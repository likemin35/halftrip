from fastapi import APIRouter, File, UploadFile
from fastapi.responses import Response

from app.schemas.responses import (
    ApiResponse,
    LodgingExtractData,
    LodgingFormData,
    LodgingTemplateAnalyzeData,
    LodgingTemplateAnalyzeRequest,
    LodgingFormRenderRequest,
    ReceiptAmountData,
    ReceiptOcrData,
)
from app.services.mock_ocr import mock_ocr_service
from app.services.pdf_service import pdf_service
from app.services.template_ai_service import template_ai_service

router = APIRouter(prefix="/api/v1/documents", tags=["documents"])


@router.post("/ocr/receipt", response_model=ApiResponse)
async def receipt_ocr(file: UploadFile = File(...)) -> ApiResponse:
    data = await mock_ocr_service.classify_payment(file)
    return ApiResponse(data=ReceiptOcrData(**data))


@router.post("/ocr/receipt-amount", response_model=ApiResponse)
async def receipt_amount(file: UploadFile = File(...)) -> ApiResponse:
    data = await mock_ocr_service.extract_amount(file)
    return ApiResponse(data=ReceiptAmountData(**data))


@router.post("/ocr/lodging", response_model=ApiResponse)
async def lodging_extract(file: UploadFile = File(...)) -> ApiResponse:
    data = await mock_ocr_service.extract_lodging_info(file)
    return ApiResponse(data=LodgingExtractData(**data))


@router.post("/pdf/merge")
async def merge_pdf(files: list[UploadFile] = File(...)) -> Response:
    merged_pdf = await pdf_service.merge_files(files)
    return Response(content=merged_pdf, media_type="application/pdf")


@router.post("/pdf/lodging-form")
async def render_lodging_form(request: LodgingFormRenderRequest) -> Response:
    pdf_bytes = pdf_service.create_lodging_form_pdf(request)
    return Response(content=pdf_bytes, media_type="application/pdf")


@router.post("/templates/analyze", response_model=ApiResponse)
async def analyze_lodging_template(
    request: LodgingTemplateAnalyzeRequest,
) -> ApiResponse:
    data = template_ai_service.analyze_template(request)
    return ApiResponse(data=LodgingTemplateAnalyzeData(**data.model_dump()))


@router.post("/lodging-form-data", response_model=ApiResponse)
async def lodging_form_data(payload: dict) -> ApiResponse:
    data = LodgingFormData(
        template_name="common_lodging_form.pdf",
        payload=payload,
        todos=[
            "TODO: Replace common template with region-specific template when files are provided.",
            "TODO: Render electronic signature on final PDF output when real template is integrated.",
        ],
    )
    return ApiResponse(data=data)
