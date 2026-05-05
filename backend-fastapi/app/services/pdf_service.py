import json
from dataclasses import dataclass
from io import BytesIO
from pathlib import Path

from fastapi import UploadFile
from PIL import Image
from pypdf import PdfReader, PdfWriter
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas

from app.schemas.responses import LodgingFormField, LodgingFormRenderRequest

PDF_COORD_BASE_WIDTH = 720.0
PDF_COORD_BASE_HEIGHT = 1018.0


@dataclass(frozen=True)
class _TemplateInsetProfile:
    text_inset_x: float = 3.0
    text_inset_y: float = 3.0
    signature_inset_x: float = 4.0
    signature_inset_y: float = 3.0
    checkbox_inset: float = 2.0
    max_checkbox_size: float = 14.0


_TEMPLATE_INSET_PROFILES: dict[str, _TemplateInsetProfile] = {
    "stay_confirm_wando.pdf": _TemplateInsetProfile(
        text_inset_x=4.0,
        text_inset_y=3.0,
        signature_inset_x=5.0,
        signature_inset_y=3.0,
        checkbox_inset=2.5,
        max_checkbox_size=13.0,
    ),
    "stay_confirm_pyoungchang.pdf": _TemplateInsetProfile(
        text_inset_x=4.0,
        text_inset_y=4.0,
        signature_inset_x=5.0,
        signature_inset_y=4.0,
    ),
    "stay_confirm_haenam.pdf": _TemplateInsetProfile(
        text_inset_x=4.0,
        text_inset_y=4.0,
        signature_inset_x=6.0,
        signature_inset_y=4.0,
    ),
    "stay_confirm_gangjin.pdf": _TemplateInsetProfile(
        text_inset_x=4.0,
        text_inset_y=4.0,
        signature_inset_x=6.0,
        signature_inset_y=4.0,
    ),
    "stay_confirm_hadong.pdf": _TemplateInsetProfile(
        text_inset_x=4.0,
        text_inset_y=4.0,
        signature_inset_x=6.0,
        signature_inset_y=4.0,
    ),
    "stay_confirm_milyang.pdf": _TemplateInsetProfile(
        text_inset_x=4.0,
        text_inset_y=4.0,
        signature_inset_x=6.0,
        signature_inset_y=4.0,
    ),
    "stay_confirm_namhae.pdf": _TemplateInsetProfile(
        text_inset_x=4.0,
        text_inset_y=4.0,
        signature_inset_x=6.0,
        signature_inset_y=4.0,
    ),
    "stay_confirm_yeongam.pdf": _TemplateInsetProfile(
        text_inset_x=4.0,
        text_inset_y=4.0,
        signature_inset_x=6.0,
        signature_inset_y=4.0,
    ),
    "stay_confirm_geochang.pdf": _TemplateInsetProfile(
        text_inset_x=4.0,
        text_inset_y=3.0,
        signature_inset_x=5.0,
        signature_inset_y=3.0,
        checkbox_inset=2.5,
        max_checkbox_size=13.0,
    ),
    "stay_confirm_gochang.pdf": _TemplateInsetProfile(
        text_inset_x=4.0,
        text_inset_y=3.0,
        signature_inset_x=5.0,
        signature_inset_y=3.0,
        checkbox_inset=2.5,
        max_checkbox_size=13.0,
    ),
    "stay_confirm_hapcheon.pdf": _TemplateInsetProfile(
        text_inset_x=4.0,
        text_inset_y=3.0,
        signature_inset_x=5.0,
        signature_inset_y=3.0,
        checkbox_inset=2.5,
        max_checkbox_size=13.0,
    ),
    "stay_confirm_yeonggwang.pdf": _TemplateInsetProfile(
        text_inset_x=4.0,
        text_inset_y=3.0,
        signature_inset_x=5.0,
        signature_inset_y=3.0,
        checkbox_inset=2.5,
        max_checkbox_size=13.0,
    ),
}

_COMPACT_FIELD_KEYS = {
    "phone_number_mid",
    "phone_number_last",
    "traveler_phone_mid",
    "traveler_phone_last",
    "payment_date_year",
    "payment_date_month",
    "payment_date_day",
    "confirmation_date_year",
    "confirmation_date_month",
    "confirmation_date_day",
    "occupancy_count",
}


class PdfService:
    def __init__(self) -> None:
        self._font_regular = "Helvetica"
        self._font_bold = "Helvetica-Bold"
        self._register_fonts()

    async def merge_files(self, files: list[UploadFile]) -> bytes:
        writer = PdfWriter()
        for file in files:
            suffix = Path(file.filename or "").suffix.lower()
            content = await file.read()
            await file.seek(0)
            if suffix == ".pdf":
                reader = PdfReader(BytesIO(content))
                for page in reader.pages:
                    writer.add_page(page)
                continue

            image_pdf = self._image_to_pdf(content)
            reader = PdfReader(BytesIO(image_pdf))
            for page in reader.pages:
                writer.add_page(page)

        if len(writer.pages) == 0:
            writer.add_blank_page(width=595, height=842)

        output = BytesIO()
        writer.write(output)
        return output.getvalue()

    def create_lodging_form_pdf(self, request: LodgingFormRenderRequest) -> bytes:
        asset_path = self._resolve_render_asset(request.render_asset_path)
        if asset_path is not None:
            return self._render_on_background_pdf(asset_path, request)
        return self._render_placeholder_pdf(request)

    def _render_on_background_pdf(
        self,
        asset_path: Path,
        request: LodgingFormRenderRequest,
    ) -> bytes:
        reader = PdfReader(str(asset_path))
        writer = PdfWriter()

        for page_index, base_page in enumerate(reader.pages):
            overlay_buffer = BytesIO()
            page_width = float(base_page.mediabox.width)
            page_height = float(base_page.mediabox.height)
            pdf_canvas = canvas.Canvas(
                overlay_buffer,
                pagesize=(page_width, page_height),
            )
            self._draw_overlay(
                pdf_canvas,
                page_width,
                page_height,
                request,
                page_index,
                draw_frame=False,
            )
            pdf_canvas.save()
            overlay_buffer.seek(0)
            overlay_page = PdfReader(overlay_buffer).pages[0]
            base_page.merge_page(overlay_page)
            writer.add_page(base_page)

        output = BytesIO()
        writer.write(output)
        return output.getvalue()

    def _render_placeholder_pdf(self, request: LodgingFormRenderRequest) -> bytes:
        output = BytesIO()
        pdf_canvas = canvas.Canvas(output, pagesize=A4)
        width, height = A4
        self._draw_background(pdf_canvas, width, height, request)
        self._draw_overlay(pdf_canvas, width, height, request, 0, draw_frame=True)
        footer_text = "MVP placeholder renderer: replace background with regional PDF/HWP-converted asset later."
        self._set_font(pdf_canvas, 8)
        pdf_canvas.setFillColor(colors.HexColor("#6B7280"))
        pdf_canvas.drawString(36, 24, footer_text)
        pdf_canvas.save()
        return output.getvalue()

    def _draw_overlay(
        self,
        pdf_canvas: canvas.Canvas,
        width: float,
        height: float,
        request: LodgingFormRenderRequest,
        page_index: int,
        draw_frame: bool,
    ) -> None:
        background_mode = not draw_frame
        profile = _TEMPLATE_INSET_PROFILES.get(
            request.template_name,
            _TemplateInsetProfile(),
        )
        if draw_frame:
            self._draw_background(pdf_canvas, width, height, request)

        for field in request.fields:
            self._draw_field(
                pdf_canvas,
                width,
                height,
                field,
                request.payload,
                profile,
                background_mode=background_mode,
            )

        if page_index == 0:
            self._set_font(pdf_canvas, 8)
            pdf_canvas.setFillColor(colors.HexColor("#6B7280"))
            pdf_canvas.drawRightString(width - 24, 18, request.template_key)

    def _image_to_pdf(self, content: bytes) -> bytes:
        image = Image.open(BytesIO(content))
        if image.mode != "RGB":
            image = image.convert("RGB")
        output = BytesIO()
        image.save(output, format="PDF")
        return output.getvalue()

    def _draw_background(
        self,
        pdf_canvas: canvas.Canvas,
        width: float,
        height: float,
        request: LodgingFormRenderRequest,
    ) -> None:
        pdf_canvas.setFillColor(colors.white)
        pdf_canvas.rect(0, 0, width, height, fill=1, stroke=0)

        pdf_canvas.setFillColor(colors.HexColor("#EAF1FB"))
        pdf_canvas.roundRect(28, height - 170, width - 56, 128, 18, fill=1, stroke=0)

        pdf_canvas.setFillColor(colors.HexColor("#111827"))
        self._set_font(pdf_canvas, 18, bold=True)
        pdf_canvas.drawString(40, height - 48, request.preview_title)
        self._set_font(pdf_canvas, 11)
        pdf_canvas.setFillColor(colors.HexColor("#4B5563"))
        pdf_canvas.drawString(40, height - 66, request.region_name)
        if request.preview_subtitle:
            pdf_canvas.drawString(40, height - 84, request.preview_subtitle)

        pdf_canvas.setStrokeColor(colors.HexColor("#CBD5E1"))
        pdf_canvas.setLineWidth(1)
        pdf_canvas.line(36, height - 182, width - 36, height - 182)

        self._set_font(pdf_canvas, 13, bold=True)
        pdf_canvas.setFillColor(colors.HexColor("#111827"))
        pdf_canvas.drawString(40, height - 112, "숙박업소 확인 정보")
        self._set_font(pdf_canvas, 10)
        pdf_canvas.setFillColor(colors.HexColor("#475569"))
        pdf_canvas.drawString(40, height - 128, "입력한 내용은 저장되며, 이후 PDF로 출력할 수 있습니다.")

        pdf_canvas.setStrokeColor(colors.HexColor("#E5E7EB"))
        pdf_canvas.roundRect(32, 40, width - 64, height - 250, 16, fill=0, stroke=1)

    def _draw_field(
        self,
        pdf_canvas: canvas.Canvas,
        page_width: float,
        page_height: float,
        field: LodgingFormField,
        payload: dict,
        profile: _TemplateInsetProfile,
        background_mode: bool,
    ) -> None:
        if background_mode:
            left, top, box_width, box_height = self._resolve_background_rect(
                page_width,
                page_height,
                field,
            )
            y_origin = page_height - top - box_height
        else:
            left = 32 + ((page_width - 64) * field.x / 100)
            top = 40 + ((page_height - 250) * field.y / 100)
            box_width = (page_width - 64) * field.width / 100
            box_height = (page_height - 250) * field.height / 100
            y_origin = page_height - top - box_height

            pdf_canvas.setFillColor(colors.HexColor("#111827"))
            self._set_font(pdf_canvas, 9, bold=True)
            pdf_canvas.drawString(left, y_origin + box_height - 11, field.label)

        value = payload.get(field.key, "")
        field_type = field.type.lower()
        if field_type == "hidden":
            return
        if field_type == "checkbox":
            checkbox_size = max(
                8.0,
                min(
                    profile.max_checkbox_size,
                    box_width - (profile.checkbox_inset * 2),
                    box_height - (profile.checkbox_inset * 2),
                ),
            )
            self._draw_checkbox(
                pdf_canvas,
                left + max((box_width - checkbox_size) / 2, 0),
                y_origin + max((box_height - checkbox_size) / 2, 0),
                checkbox_size,
                checkbox_size,
                bool(value),
                background_mode=background_mode,
            )
            return
        if field_type == "signature":
            inset_left = left + profile.signature_inset_x
            inset_bottom = y_origin + profile.signature_inset_y
            inset_width = max(16.0, box_width - (profile.signature_inset_x * 2))
            inset_height = max(20.0, box_height - (profile.signature_inset_y * 2))
            self._draw_signature_box(
                pdf_canvas,
                inset_left,
                inset_bottom,
                inset_width,
                inset_height,
                value,
                background_mode=background_mode,
            )
            return

        inset_left = left + profile.text_inset_x
        inset_bottom = y_origin + profile.text_inset_y
        inset_width = max(18.0, box_width - (profile.text_inset_x * 2))
        inset_height = max(18.0, box_height - (profile.text_inset_y * 2))
        if field.key in _COMPACT_FIELD_KEYS:
            inset_left = left + 1
            inset_bottom = y_origin + 1
            inset_width = max(10.0, box_width - 2)
            inset_height = max(10.0, box_height - 2)
        self._draw_text_box(
            pdf_canvas,
            inset_left,
            inset_bottom,
            inset_width,
            inset_height,
            value,
            multiline=field.multiline,
            background_mode=background_mode,
        )

    def _resolve_background_rect(
        self,
        page_width: float,
        page_height: float,
        field: LodgingFormField,
    ) -> tuple[float, float, float, float]:
        # Legacy templates used percentages. New fixed templates use PDF-space
        # coordinates based on the same canvas as the Flutter overlay.
        if (
            field.x <= 100
            and field.y <= 100
            and field.width <= 100
            and field.height <= 100
        ):
            return (
                page_width * field.x / 100,
                page_height * field.y / 100,
                page_width * field.width / 100,
                page_height * field.height / 100,
            )

        return (
            page_width * field.x / PDF_COORD_BASE_WIDTH,
            page_height * field.y / PDF_COORD_BASE_HEIGHT,
            page_width * field.width / PDF_COORD_BASE_WIDTH,
            page_height * field.height / PDF_COORD_BASE_HEIGHT,
        )

    def _draw_checkbox(
        self,
        pdf_canvas: canvas.Canvas,
        left: float,
        bottom: float,
        box_width: float,
        box_height: float,
        checked: bool,
        background_mode: bool,
    ) -> None:
        if background_mode:
            if checked:
                pdf_canvas.setStrokeColor(colors.HexColor("#111827"))
                pdf_canvas.setLineWidth(1.8)
                pdf_canvas.line(left, bottom + box_height * 0.45, left + box_width * 0.35, bottom)
                pdf_canvas.line(left + box_width * 0.35, bottom, left + box_width, bottom + box_height)
            return
        square = min(12, box_height - 8)
        pdf_canvas.setStrokeColor(colors.HexColor("#475569"))
        pdf_canvas.roundRect(left, bottom, square, square, 2, fill=0, stroke=1)
        if checked:
            pdf_canvas.setStrokeColor(colors.HexColor("#2563EB"))
            pdf_canvas.setLineWidth(2)
            pdf_canvas.line(left + 2, bottom + square / 2, left + square / 2, bottom + 2)
            pdf_canvas.line(left + square / 2, bottom + 2, left + square - 2, bottom + square - 2)
        self._set_font(pdf_canvas, 9)
        pdf_canvas.setFillColor(colors.HexColor("#1F2937"))
        pdf_canvas.drawString(left + square + 6, bottom + 2, "동의함" if checked else "미동의")

    def _draw_signature_box(
        self,
        pdf_canvas: canvas.Canvas,
        left: float,
        bottom: float,
        box_width: float,
        box_height: float,
        signature_value: object,
        background_mode: bool,
    ) -> None:
        points = self._parse_signature(signature_value)
        if not points:
            if background_mode:
                return
            pdf_canvas.setStrokeColor(colors.HexColor("#94A3B8"))
            pdf_canvas.roundRect(left, bottom, box_width, box_height, 6, fill=0, stroke=1)
            self._set_font(pdf_canvas, 9)
            pdf_canvas.setFillColor(colors.HexColor("#64748B"))
            pdf_canvas.drawString(left + 8, bottom + box_height / 2, "Tap to sign")
            return

        if not background_mode:
            pdf_canvas.setStrokeColor(colors.HexColor("#94A3B8"))
            pdf_canvas.roundRect(left, bottom, box_width, box_height, 6, fill=0, stroke=1)

        pdf_canvas.setStrokeColor(colors.HexColor("#0F5132"))
        pdf_canvas.setLineWidth(2)
        for current, nxt in zip(points, points[1:]):
            if current is None or nxt is None:
                continue
            current_x = left + (current[0] / 320) * box_width
            current_y = bottom + box_height - (current[1] / 220) * box_height
            next_x = left + (nxt[0] / 320) * box_width
            next_y = bottom + box_height - (nxt[1] / 220) * box_height
            pdf_canvas.line(current_x, current_y, next_x, next_y)

    def _draw_text_box(
        self,
        pdf_canvas: canvas.Canvas,
        left: float,
        bottom: float,
        box_width: float,
        box_height: float,
        value: object,
        multiline: bool = False,
        background_mode: bool = False,
    ) -> None:
        pdf_canvas.setFillColor(colors.HexColor("#0F172A"))
        compact = box_width <= 44 or box_height <= 18
        font_size = 8 if compact else 10
        self._set_font(pdf_canvas, font_size)
        text = "" if value is None else str(value)
        if background_mode:
            if multiline:
                y = bottom + box_height - 12
                for line in self._wrap_text(text, max_chars=34)[:3]:
                    pdf_canvas.drawString(left + 3, y, line)
                    y -= 12
                return
            if compact:
                baseline = bottom + max(1, (box_height - font_size) / 2)
                pdf_canvas.drawCentredString(left + (box_width / 2), baseline, text)
                return
            baseline = bottom + max(2, (box_height - font_size) / 2)
            pdf_canvas.drawString(left + 3, baseline, text)
            return

        pdf_canvas.setStrokeColor(colors.HexColor("#CBD5E1"))
        pdf_canvas.roundRect(left, bottom, box_width, box_height - 14, 6, fill=0, stroke=1)
        if multiline:
            y = bottom + box_height - 26
            for line in self._wrap_text(text, max_chars=40)[:3]:
                pdf_canvas.drawString(left + 8, y, line)
                y -= 12
            return
        if compact:
            pdf_canvas.drawCentredString(left + (box_width / 2), bottom + 6, text)
            return
        pdf_canvas.drawString(left + 8, bottom + 8, text)

    def _parse_signature(self, signature_value: object) -> list[tuple[float, float] | None]:
        if not signature_value:
            return []
        try:
            raw_points = json.loads(str(signature_value))
        except (TypeError, ValueError, json.JSONDecodeError):
            return []

        points: list[tuple[float, float] | None] = []
        for item in raw_points:
            if item is None:
                points.append(None)
                continue
            x = float(item.get("x", 0))
            y = float(item.get("y", 0))
            points.append((x, y))
        return points

    def _wrap_text(self, text: str, max_chars: int) -> list[str]:
        if len(text) <= max_chars:
            return [text]
        words = text.split()
        if not words:
            return [text[:max_chars]]

        lines: list[str] = []
        current = ""
        for word in words:
            candidate = word if not current else f"{current} {word}"
            if len(candidate) <= max_chars:
                current = candidate
                continue
            if current:
                lines.append(current)
            current = word
        if current:
            lines.append(current)
        return lines or [text[:max_chars]]

    def _resolve_render_asset(self, render_asset_path: str | None) -> Path | None:
        if not render_asset_path:
            return None
        candidate = Path(render_asset_path)
        if not candidate.is_absolute():
            candidate = Path.cwd() / candidate
        if candidate.exists() and candidate.suffix.lower() == ".pdf":
            return candidate
        return None

    def _register_fonts(self) -> None:
        regular = Path(r"C:\Windows\Fonts\malgun.ttf")
        bold = Path(r"C:\Windows\Fonts\malgunbd.ttf")
        try:
            if regular.exists():
                pdfmetrics.registerFont(TTFont("MalgunGothic", str(regular)))
                self._font_regular = "MalgunGothic"
            if bold.exists():
                pdfmetrics.registerFont(TTFont("MalgunGothicBold", str(bold)))
                self._font_bold = "MalgunGothicBold"
            elif self._font_regular != "Helvetica":
                self._font_bold = self._font_regular
        except Exception:
            self._font_regular = "Helvetica"
            self._font_bold = "Helvetica-Bold"

    def _set_font(self, pdf_canvas: canvas.Canvas, size: float, bold: bool = False) -> None:
        pdf_canvas.setFont(self._font_bold if bold else self._font_regular, size)


pdf_service = PdfService()
