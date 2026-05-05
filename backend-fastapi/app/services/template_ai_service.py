import json
import re
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path

from pypdf import PdfReader

from app.core.config import get_settings
from app.schemas.responses import (
    LodgingFormField,
    LodgingTemplateAnalyzeData,
    LodgingTemplateAnalyzeRequest,
)


@dataclass
class _TextToken:
    text: str
    x: float
    y: float
    font_size: float


class TemplateAiService:
    _field_aliases = {
        "lodging_name": ["업소명", "숙박업소", "숙박업소명"],
        "business_number": ["사업자번호", "사업자등록번호"],
        "address": ["주소"],
        "representative_name": ["대표자", "대표자명"],
        "phone_number": ["연락처", "전화번호", "전화", "업소 연락처"],
        "traveler_name": ["성명", "신청자명", "여행신청자", "결제자"],
        "traveler_phone_number": ["연락처", "휴대전화", "핸드폰", "전화번호"],
        "residence": ["거주지역", "거주지"],
        "trip_date_range": ["숙박기간", "여행기간", "이용기간"],
        "occupancy_count": ["숙박인원", "인원"],
        "payment_amount": ["결제금액", "결제금액(원)", "결제 금액"],
        "payment_date": ["결제일자", "결제일"],
        "signature": ["서명", "날인/서명", "날인"],
        "agreed_personal_info": ["동의", "개인정보"],
        "agreed_stay_proof": ["실제 숙박 사실 확인", "숙박 확인"],
    }

    def analyze_template(
        self,
        request: LodgingTemplateAnalyzeRequest,
    ) -> LodgingTemplateAnalyzeData:
        pdf_path = self._resolve_pdf_path(request.render_asset_path)
        if pdf_path is None:
            return LodgingTemplateAnalyzeData(
                fields=request.current_fields,
                warnings=["Template PDF path is missing or invalid."],
                used_ai=False,
            )

        page_width, page_height, tokens = self._extract_tokens(pdf_path)
        heuristic_fields = self._build_heuristic_fields(
            request.current_fields,
            page_width,
            page_height,
            tokens,
        )

        settings = get_settings()
        warnings: list[str] = []
        if not settings.open_ai_key:
            warnings.append("OPEN_AI_KEY is not configured; heuristic mapping was used.")
            return LodgingTemplateAnalyzeData(
                fields=heuristic_fields,
                warnings=warnings,
                used_ai=False,
            )
        if len(tokens) < 20:
            warnings.append(
                "Not enough template text could be extracted from the PDF; heuristic mapping was used.",
            )
            return LodgingTemplateAnalyzeData(
                fields=heuristic_fields,
                warnings=warnings,
                used_ai=False,
            )

        try:
            ai_fields = self._request_openai_fields(
                request=request,
                page_width=page_width,
                page_height=page_height,
                tokens=tokens,
                heuristic_fields=heuristic_fields,
            )
            merged_fields = self._merge_fields(heuristic_fields, ai_fields)
            if not self._is_mapping_plausible(heuristic_fields, merged_fields):
                warnings.append(
                    "AI mapping looked unreliable for this PDF; heuristic mapping was used instead.",
                )
                return LodgingTemplateAnalyzeData(
                    fields=heuristic_fields,
                    warnings=warnings,
                    used_ai=False,
                )
            return LodgingTemplateAnalyzeData(
                fields=merged_fields,
                warnings=warnings,
                used_ai=True,
            )
        except Exception as error:  # noqa: BLE001
            warnings.append(f"AI analysis failed, heuristic mapping was used: {error}")
            return LodgingTemplateAnalyzeData(
                fields=heuristic_fields,
                warnings=warnings,
                used_ai=False,
            )

    def _extract_tokens(self, pdf_path: Path) -> tuple[float, float, list[_TextToken]]:
        reader = PdfReader(str(pdf_path))
        page = reader.pages[0]
        page_width = float(page.mediabox.width)
        page_height = float(page.mediabox.height)
        tokens: list[_TextToken] = []

        def visitor_text(text, cm, tm, font_dict, font_size):  # noqa: ANN001
            cleaned = (text or "").strip()
            if not cleaned:
                return
            tokens.append(
                _TextToken(
                    text=cleaned,
                    x=float(tm[4]),
                    y=float(tm[5]),
                    font_size=float(font_size),
                )
            )

        page.extract_text(visitor_text=visitor_text)
        return page_width, page_height, tokens

    def _build_heuristic_fields(
        self,
        current_fields: list[LodgingFormField],
        page_width: float,
        page_height: float,
        tokens: list[_TextToken],
    ) -> list[LodgingFormField]:
        results: list[LodgingFormField] = []
        for field in current_fields:
            matched = self._find_label_token(field.key, tokens)
            if matched is None:
                continue

            default_width = self._default_width(field)
            default_height = self._default_height(field)
            x_points = matched.x if field.type == "checkbox" else matched.x + self._default_offset(field)
            y_top_points = page_height - matched.y - default_height

            if field.type == "signature":
                x_points = min(matched.x + 20, page_width * 0.72)
                y_top_points = page_height - matched.y - (page_height * 0.055)

            results.append(
                LodgingFormField(
                    key=field.key,
                    label=field.label,
                    type=field.type,
                    x=self._clamp_percent((x_points / page_width) * 100),
                    y=self._clamp_percent((y_top_points / page_height) * 100),
                    width=self._clamp_percent((default_width / page_width) * 100),
                    height=self._clamp_percent((default_height / page_height) * 100),
                    editable=field.editable,
                    multiline=field.multiline,
                    helper_text=field.helper_text,
                )
            )
        if not results:
            return current_fields
        results.sort(key=lambda item: (item.y, item.x))
        return results

    def _find_label_token(self, field_key: str, tokens: list[_TextToken]) -> _TextToken | None:
        aliases = self._field_aliases.get(field_key, [])
        for alias in aliases:
            for token in tokens:
                if alias in token.text:
                    return token
        return None

    def _default_offset(self, field: LodgingFormField) -> float:
        if field.key in {"address", "residence"}:
            return 70
        if field.key in {"trip_date_range", "payment_date"}:
            return 95
        if field.key == "payment_amount":
            return 95
        if field.key == "occupancy_count":
            return 95
        return 80

    def _default_width(self, field: LodgingFormField) -> float:
        if field.type == "checkbox":
            return 16
        if field.type == "signature":
            return 110
        if field.key in {"address", "residence"}:
            return 260
        if field.key in {"trip_date_range", "payment_date"}:
            return 230
        if field.key == "payment_amount":
            return 150
        if field.key == "occupancy_count":
            return 80
        return 220

    def _default_height(self, field: LodgingFormField) -> float:
        if field.type == "checkbox":
            return 16
        if field.type == "signature":
            return 48
        return 24

    def _request_openai_fields(
        self,
        request: LodgingTemplateAnalyzeRequest,
        page_width: float,
        page_height: float,
        tokens: list[_TextToken],
        heuristic_fields: list[LodgingFormField],
    ) -> list[LodgingFormField]:
        settings = get_settings()
        token_payload = [
            {
                "text": token.text,
                "x": round(token.x, 2),
                "y": round(token.y, 2),
                "font_size": round(token.font_size, 2),
            }
            for token in tokens[:300]
        ]
        heuristic_payload = [field.model_dump() for field in heuristic_fields]
        body = {
            "model": settings.open_ai_model,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are analyzing Korean lodging confirmation PDFs. "
                        "Return JSON only. For each field, refine x/y/width/height as percentages of the page. "
                        "Keep field keys exactly as given. Preserve type/editable/multiline."
                    ),
                },
                {
                    "role": "user",
                    "content": json.dumps(
                        {
                            "template_name": request.template_name,
                            "region_name": request.region_name,
                            "page_width": page_width,
                            "page_height": page_height,
                            "tokens": token_payload,
                            "heuristic_fields": heuristic_payload,
                            "output_format": {
                                "fields": [
                                    {
                                        "key": "lodging_name",
                                        "type": "text",
                                        "x": 27.5,
                                        "y": 13.8,
                                        "width": 47.0,
                                        "height": 3.6,
                                        "editable": True,
                                        "multiline": False,
                                    }
                                ]
                            },
                            "rules": [
                                "Return the same set of keys as heuristic_fields whenever possible.",
                                "Coordinates must be percentages from the top-left corner of page 1.",
                                "Checkbox width/height should remain small.",
                                "Signature box should cover the signature area, not the label.",
                            ],
                        },
                        ensure_ascii=False,
                    ),
                },
            ],
            "temperature": 0.1,
            "response_format": {"type": "json_object"},
        }
        request_bytes = json.dumps(body).encode("utf-8")
        http_request = urllib.request.Request(
            "https://api.openai.com/v1/chat/completions",
            data=request_bytes,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {settings.open_ai_key}",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(http_request, timeout=60) as response:
                raw_response = response.read().decode("utf-8")
        except urllib.error.HTTPError as error:
            details = error.read().decode("utf-8", errors="ignore")
            raise RuntimeError(details) from error

        decoded = json.loads(raw_response)
        content = decoded["choices"][0]["message"]["content"]
        payload = self._parse_json_object(content)
        ai_fields = payload.get("fields", [])
        return [LodgingFormField.model_validate(item) for item in ai_fields]

    def _merge_fields(
        self,
        heuristic_fields: list[LodgingFormField],
        ai_fields: list[LodgingFormField],
    ) -> list[LodgingFormField]:
        ai_map = {field.key: field for field in ai_fields}
        merged: list[LodgingFormField] = []
        for heuristic in heuristic_fields:
            candidate = ai_map.get(heuristic.key)
            if candidate is None:
                merged.append(heuristic)
                continue
            merged.append(
                LodgingFormField(
                    key=heuristic.key,
                    label=heuristic.label,
                    type=heuristic.type,
                    x=self._clamp_percent(candidate.x),
                    y=self._clamp_percent(candidate.y),
                    width=self._clamp_percent(candidate.width),
                    height=self._clamp_percent(candidate.height),
                    editable=heuristic.editable,
                    multiline=heuristic.multiline,
                    helper_text=heuristic.helper_text,
                )
            )
        return merged

    def _is_mapping_plausible(
        self,
        heuristic_fields: list[LodgingFormField],
        candidate_fields: list[LodgingFormField],
    ) -> bool:
        if not candidate_fields:
            return False

        candidate_by_key = {field.key: field for field in candidate_fields}
        boundary_hits = 0
        invalid_sizes = 0
        extreme_shifts = 0

        for heuristic in heuristic_fields:
            candidate = candidate_by_key.get(heuristic.key)
            if candidate is None:
                continue
            if candidate.x <= 1 or candidate.x >= 99 or candidate.y <= 1 or candidate.y >= 99:
                boundary_hits += 1
            if candidate.width <= 0 or candidate.height <= 0 or candidate.width > 95 or candidate.height > 40:
                invalid_sizes += 1
            if abs(candidate.x - heuristic.x) > 45 or abs(candidate.y - heuristic.y) > 45:
                extreme_shifts += 1

        field_count = max(len(heuristic_fields), 1)
        if boundary_hits >= max(2, field_count // 3):
            return False
        if invalid_sizes > 0:
            return False
        if extreme_shifts >= max(3, field_count // 2):
            return False
        return True

    def _parse_json_object(self, content: str) -> dict:
        stripped = content.strip()
        if stripped.startswith("```"):
            stripped = re.sub(r"^```(?:json)?", "", stripped).strip()
            stripped = re.sub(r"```$", "", stripped).strip()
        return json.loads(stripped)

    def _resolve_pdf_path(self, render_asset_path: str | None) -> Path | None:
        if not render_asset_path:
            return None
        candidate = Path(render_asset_path)
        if not candidate.is_absolute():
            cwd_candidate = Path.cwd() / render_asset_path
            service_candidate = Path(__file__).resolve().parents[2] / render_asset_path
            candidate = cwd_candidate if cwd_candidate.exists() else service_candidate
        if candidate.exists() and candidate.suffix.lower() == ".pdf":
            return candidate
        return None

    def _clamp_percent(self, value: float) -> float:
        return round(max(0.0, min(100.0, value)), 2)


template_ai_service = TemplateAiService()
