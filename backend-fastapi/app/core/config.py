from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = "local"
    temp_upload_dir: str = "./tmp"
    common_lodging_template_path: str = "./templates/common_lodging_form.pdf"
    open_ai_key: str = ""
    open_ai_model: str = "gpt-4.1-mini"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
