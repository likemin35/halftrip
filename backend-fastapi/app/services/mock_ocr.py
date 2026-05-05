import base64
import hashlib
import json
import mimetypes
import re
import urllib.error
import urllib.request
from pathlib import Path

from fastapi import UploadFile

from app.core.config import get_settings


class MockOcrService:
    payment_keywords = {
        "credit_card": ["credit", "visa", "master", "신용", "credit card"],
        "check_card": ["check", "debit", "체크", "debit card"],
        "online_payment": [
            "kakaopay",
            "kakao pay",
            "카카오페이",
            "naverpay",
            "naver pay",
            "네이버페이",
            "npay",
            "n pay",
            "payco",
            "토스페이",
            "tosspay",
            "chak",
            "지역사랑상품권",
            "제로페이",
            "zeropay",
            "비플페이",
            "비플pay",
            "월출페이",
            "그리고",
            "고창사랑카드",
            "반반남해",
            "합천반값여행",
            "거창반값여행",
            "고흥사랑상품권",
            "online",
        ],
        "bank_transfer": ["transfer", "계좌이체", "무통장", "입금"],
        "cash_receipt": ["cash", "현금", "cash receipt", "현금영수증"],
        "simple_receipt": ["간이영수증", "simple receipt", "간이"],
    }

    def __init__(self) -> None:
        self._analysis_cache: dict[str, dict] = {}

    async def read_bytes(self, file: UploadFile) -> bytes:
        content = await file.read()
        await file.seek(0)
        return content

    async def read_text(self, file: UploadFile) -> str:
        content = await self.read_bytes(file)
        try:
            return content.decode("utf-8", errors="ignore")
        except Exception:
            return ""

    async def classify_payment(self, file: UploadFile) -> dict:
        analysis = await self._analyze(file)
        return {
            "payment_type": analysis["payment_type"],
            "raw_text": analysis["raw_text"],
            "candidates": analysis["candidates"],
        }

    async def extract_amount(self, file: UploadFile) -> dict:
        analysis = await self._analyze(file)
        return {
            "amount": analysis["amount"],
            "currency": "KRW",
            "raw_text": analysis["raw_text"],
        }

    async def _analyze(self, file: UploadFile) -> dict:
        content = await self.read_bytes(file)
        cache_key = hashlib.sha256(content).hexdigest()
        cached = self._analysis_cache.get(cache_key)
        if cached is not None:
            return cached

        raw_text = ""
        try:
            raw_text = content.decode("utf-8", errors="ignore")
        except Exception:
            raw_text = ""

        analysis = self._heuristic_analysis(file.filename or "", raw_text)
        ai_analysis = self._analyze_with_openai(file.filename or "", file.content_type or "", content)
        if ai_analysis is not None:
            analysis.update({
                "payment_type": ai_analysis.get("payment_type", analysis["payment_type"]),
                "amount": ai_analysis.get("amount", analysis["amount"]),
                "raw_text": ai_analysis.get("raw_text", analysis["raw_text"]) or analysis["raw_text"],
                "candidates": ai_analysis.get("candidates", analysis["candidates"]) or analysis["candidates"],
            })

        self._analysis_cache[cache_key] = analysis
        return analysis

    def _heuristic_analysis(self, filename: str, raw_text: str) -> dict:
        source = f"{filename} {raw_text}".lower()
        payment_type = "unknown"
        for candidate, keywords in self.payment_keywords.items():
            if any(keyword in source for keyword in keywords):
                payment_type = candidate
                break

        matches = re.findall(r"(\d[\d,]{2,})", f"{filename} {raw_text}")
        amount = None
        if matches:
            normalized = matches[-1].replace(",", "")
            try:
                amount = int(normalized)
            except ValueError:
                amount = None

        candidates = [payment_type]
        if payment_type != "online_payment":
            candidates.append("online_payment")
        if payment_type != "credit_card":
            candidates.append("credit_card")
        if payment_type == "unknown":
            candidates.append("cash_receipt")

        return {
            "payment_type": payment_type,
            "amount": amount,
            "raw_text": raw_text,
            "candidates": candidates[:3],
        }

    def _analyze_with_openai(self, filename: str, content_type: str, content: bytes) -> dict | None:
        settings = get_settings()
        if not settings.open_ai_key:
            return None

        mime_type = content_type or mimetypes.guess_type(filename)[0] or "application/octet-stream"
        if not mime_type.startswith("image/"):
            return None

        prompt = (
            "You analyze Korean receipt images for a travel settlement app. "
            "Return only JSON with keys: payment_type, amount, raw_text, candidates. "
            "payment_type must be one of: credit_card, check_card, online_payment, "
            "bank_transfer, cash_receipt, simple_receipt, unknown. "
            "amount must be an integer KRW total amount or null. "
            "raw_text should be a short summary of the detected merchant/payment clues. "
            "candidates must be an array of up to 3 likely payment types."
        )
        payload = {
            "model": settings.open_ai_model,
            "temperature": 0,
            "messages": [
                {
                    "role": "system",
                    "content": "You are a precise receipt OCR and payment classification assistant.",
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:{mime_type};base64,{base64.b64encode(content).decode('ascii')}"
                            },
                        },
                    ],
                },
            ],
            "response_format": {"type": "json_object"},
        }
        request = urllib.request.Request(
            "https://api.openai.com/v1/chat/completions",
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {settings.open_ai_key}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                body = json.loads(response.read().decode("utf-8"))
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
            return None

        try:
            content_text = body["choices"][0]["message"]["content"]
            parsed = json.loads(content_text)
        except (KeyError, IndexError, TypeError, json.JSONDecodeError):
            return None

        payment_type = str(parsed.get("payment_type", "unknown")).strip().lower()
        if payment_type not in {
            "credit_card",
            "check_card",
            "online_payment",
            "bank_transfer",
            "cash_receipt",
            "simple_receipt",
            "unknown",
        }:
            payment_type = "unknown"

        amount = parsed.get("amount")
        if not isinstance(amount, int):
            amount = None

        candidates = parsed.get("candidates")
        if not isinstance(candidates, list):
            candidates = [payment_type, "unknown"]

        return {
            "payment_type": payment_type,
            "amount": amount,
            "raw_text": str(parsed.get("raw_text", "")).strip(),
            "candidates": [str(candidate).strip().lower() for candidate in candidates[:3]],
        }

    async def extract_lodging_info(self, file: UploadFile) -> dict:
        raw_text = await self.read_text(file)
        source = raw_text or (file.filename or "")

        def find(pattern: str) -> str | None:
            match = re.search(pattern, source, re.IGNORECASE)
            return match.group(1).strip() if match else None

        phone_match = re.search(r"(01[0-9]-?\d{3,4}-?\d{4}|0\d{1,2}-\d{3,4}-\d{4})", source)
        address = find(r"(전라[남북]도[^\n]+|강원특별자치도[^\n]+|서울특별시[^\n]+|경상[남북]도[^\n]+)")
        lodging_name = find(r"(?:숙박업소명|숙소명|lodging)[:\s]+([^\n]+)")
        representative_name = find(r"(?:대표자명|대표자|owner)[:\s]+([^\n]+)")

        warnings = []
        if lodging_name is None:
            warnings.append("lodging_name_not_found")
        if representative_name is None:
            warnings.append("representative_name_not_found")

        return {
            "lodging_name": lodging_name,
            "representative_name": representative_name,
            "phone_number": phone_match.group(1) if phone_match else None,
            "address": address,
            "warnings": warnings,
        }


mock_ocr_service = MockOcrService()
