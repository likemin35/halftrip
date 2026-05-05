from __future__ import annotations

from pathlib import Path

from google.adk.agents import Agent
from google.adk.apps import App
from google.adk.models import Gemini
from google.genai import types

PROJECT_ROOT = Path(__file__).resolve().parents[2]

REGION_MIGRATION = (
    PROJECT_ROOT
    / "backend-spring"
    / "src"
    / "main"
    / "resources"
    / "db"
    / "migration"
    / "V2__region_map_and_residence_rules.sql"
)
LODGING_MIGRATION = (
    PROJECT_ROOT
    / "backend-spring"
    / "src"
    / "main"
    / "resources"
    / "db"
    / "migration"
    / "V4__lodging_form_templates.sql"
)
PICKER_DATA = PROJECT_ROOT / "flutter_app" / "lib" / "data" / "residence_picker_data.dart"
TRIP_FORM_SCREEN = PROJECT_ROOT / "flutter_app" / "lib" / "screens" / "trip_form_screen.dart"
REGION_SELECTION_SCREEN = (
    PROJECT_ROOT / "flutter_app" / "lib" / "screens" / "region_selection_screen.dart"
)
LODGING_FORM_SCREEN = (
    PROJECT_ROOT / "flutter_app" / "lib" / "screens" / "lodging_form_screen.dart"
)
FASTAPI_DOCUMENTS = PROJECT_ROOT / "backend-fastapi" / "app" / "routers" / "documents.py"
FASTAPI_PDF_SERVICE = PROJECT_ROOT / "backend-fastapi" / "app" / "services" / "pdf_service.py"
LODGING_TEMPLATE_ORIGINALS = (
    PROJECT_ROOT / "backend-fastapi" / "templates" / "lodging_forms" / "originals"
)

SAMPLE_REGION_NAMES = [
    "완도",
    "강진",
    "평창",
    "해남",
    "영광",
    "횡성",
    "영월",
    "제천",
    "거창",
    "고창",
    "영암",
    "합천",
    "밀양",
    "하동",
    "남해",
    "고흥",
]

SUPPORTED_TEMPLATE_FILES = [
    "stay_confirm_wando.hwp",
    "stay_confirm_gangjin.hwp",
    "stay_confirm_pyoungchang.hwp",
    "stay_confirm_haenam.hwp",
    "stay_confirm_yeonggwang.hwp",
    "stay_confirm_geochang.hwp",
    "stay_confirm_gochang.hwp",
    "stay_confirm_yeongam.hwp",
    "stay_confirm_hapcheon.hwp",
    "stay_confirm_milyang.hwpx",
    "stay_confirm_hadong.hwp",
    "stay_confirm_namhae.hwp",
]


def validate_core_feature_files() -> dict:
    """Check whether the core files for region filtering and lodging templates exist."""

    targets = {
        "region_migration": REGION_MIGRATION,
        "lodging_migration": LODGING_MIGRATION,
        "residence_picker_data": PICKER_DATA,
        "trip_form_screen": TRIP_FORM_SCREEN,
        "region_selection_screen": REGION_SELECTION_SCREEN,
        "lodging_form_screen": LODGING_FORM_SCREEN,
        "fastapi_documents_router": FASTAPI_DOCUMENTS,
        "fastapi_pdf_service": FASTAPI_PDF_SERVICE,
        "lodging_template_originals": LODGING_TEMPLATE_ORIGINALS,
    }
    return {
        "project_root": str(PROJECT_ROOT),
        "files": {
            key: {
                "exists": path.exists(),
                "path": str(path),
            }
            for key, path in targets.items()
        },
    }


def summarize_region_seed_snapshot() -> dict:
    """Summarize whether the sample half-price travel regions are still present."""

    if not REGION_MIGRATION.exists():
        return {
            "status": "missing_migration",
            "path": str(REGION_MIGRATION),
        }

    text = REGION_MIGRATION.read_text(encoding="utf-8")
    matched = [name for name in SAMPLE_REGION_NAMES if name in text]
    return {
        "status": "ok",
        "seeded_region_count": len(matched),
        "seeded_regions": matched,
        "missing_regions": [name for name in SAMPLE_REGION_NAMES if name not in matched],
        "notes": [
            "This validates sample seed coverage only.",
            "Adjacency restriction rules are intentionally sample-based, not official public data.",
        ],
    }


def summarize_lodging_template_structure() -> dict:
    """Summarize whether the lodging form migration and PDF renderer were added."""

    migration_exists = LODGING_MIGRATION.exists()
    route_exists = FASTAPI_DOCUMENTS.exists()
    service_exists = FASTAPI_PDF_SERVICE.exists()

    route_has_render = False
    service_has_renderer = False
    if route_exists:
        route_has_render = "/pdf/lodging-form" in FASTAPI_DOCUMENTS.read_text(encoding="utf-8")
    if service_exists:
        service_has_renderer = "create_lodging_form_pdf" in FASTAPI_PDF_SERVICE.read_text(encoding="utf-8")

    return {
        "status": "ok" if migration_exists and route_has_render and service_has_renderer else "incomplete",
        "migration_exists": migration_exists,
        "pdf_route_exists": route_has_render,
        "pdf_renderer_exists": service_has_renderer,
        "lodging_form_screen_exists": LODGING_FORM_SCREEN.exists(),
        "supported_original_files": [
            filename
            for filename in SUPPORTED_TEMPLATE_FILES
            if (LODGING_TEMPLATE_ORIGINALS / filename).exists()
        ],
        "missing_original_files": [
            filename
            for filename in SUPPORTED_TEMPLATE_FILES
            if not (LODGING_TEMPLATE_ORIGINALS / filename).exists()
        ],
        "notes": [
            "Current implementation uses a placeholder coordinate-based PDF renderer.",
            "Real regional PDF/HWP template assets can be plugged into the same storage structure later.",
        ],
    }


def check_residence_picker_coverage(province: str) -> dict:
    """Check whether a province or metropolitan city exists in the picker data file."""

    if not PICKER_DATA.exists():
        return {
            "status": "missing_picker_data",
            "path": str(PICKER_DATA),
        }

    text = PICKER_DATA.read_text(encoding="utf-8")
    normalized = province.strip()
    return {
        "status": "ok",
        "province": normalized,
        "included": normalized in text,
        "path": str(PICKER_DATA),
    }


root_agent = Agent(
    name="travel_region_validator",
    model=Gemini(
        model="gemini-flash-latest",
        retry_options=types.HttpRetryOptions(attempts=3),
    ),
    instruction=(
        "You are a development-time validator for a travel support MVP. "
        "Focus on checking region sample seed coverage, residence picker support, "
        "lodging form template storage, and whether the Flutter/Spring/FastAPI files "
        "for the lodging confirmation workflow exist. Never claim sample data is official public tourism data."
    ),
    tools=[
        validate_core_feature_files,
        summarize_region_seed_snapshot,
        summarize_lodging_template_structure,
        check_residence_picker_coverage,
    ],
)

app = App(
    root_agent=root_agent,
    name="app",
)
