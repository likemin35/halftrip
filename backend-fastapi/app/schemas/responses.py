from typing import Any

from pydantic import BaseModel


class ApiResponse(BaseModel):
    success: bool = True
    data: Any = None
    message: str | None = None


class ReceiptOcrData(BaseModel):
    payment_type: str
    raw_text: str
    candidates: list[str]


class ReceiptAmountData(BaseModel):
    amount: int | None
    currency: str = "KRW"
    raw_text: str


class LodgingExtractData(BaseModel):
    lodging_name: str | None
    representative_name: str | None
    phone_number: str | None
    address: str | None
    warnings: list[str]


class LodgingFormData(BaseModel):
    template_name: str
    payload: dict[str, Any]
    todos: list[str]


class LodgingFormField(BaseModel):
    key: str
    label: str
    type: str
    x: float
    y: float
    width: float
    height: float
    editable: bool = False
    multiline: bool = False
    helper_text: str | None = None


class LodgingFormRenderRequest(BaseModel):
    template_name: str
    template_key: str
    region_name: str
    preview_title: str
    preview_subtitle: str | None = None
    render_asset_path: str | None = None
    payload: dict[str, Any]
    fields: list[LodgingFormField]
    todos: list[str] = []


class LodgingTemplateAnalyzeRequest(BaseModel):
    template_name: str
    region_name: str
    render_asset_path: str | None = None
    current_fields: list[LodgingFormField] = []


class LodgingTemplateAnalyzeData(BaseModel):
    fields: list[LodgingFormField]
    warnings: list[str]
    used_ai: bool = False
