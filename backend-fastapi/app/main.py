from pathlib import Path

from fastapi import FastAPI

from app.core.config import get_settings
from app.routers.documents import router as documents_router
from app.schemas.responses import ApiResponse

settings = get_settings()
Path(settings.temp_upload_dir).mkdir(parents=True, exist_ok=True)

app = FastAPI(
    title="Travel MVP Document AI Server",
    version="0.1.0",
    description="OCR, lodging extraction, and PDF utilities for the travel support MVP.",
)

app.include_router(documents_router)


@app.get("/health", response_model=ApiResponse)
async def health() -> ApiResponse:
    return ApiResponse(data={"status": "ok", "env": settings.app_env})

