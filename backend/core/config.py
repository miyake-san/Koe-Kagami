"""Application configuration loaded from environment variables."""

import os
from dataclasses import dataclass, field


def _cors_origins() -> list[str]:
    raw = os.getenv("KOE_CORS_ORIGINS", "http://localhost:5173")
    return [origin.strip() for origin in raw.split(",") if origin.strip()]


@dataclass(frozen=True)
class Settings:
    """Runtime settings for the Koe-Kagami backend."""

    azure_openai_endpoint: str = os.getenv("AZURE_OPENAI_ENDPOINT", "")
    azure_openai_deployment: str = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-4o")
    azure_openai_api_version: str = os.getenv("AZURE_OPENAI_API_VERSION", "2024-10-21")
    cors_origins: list[str] = field(default_factory=_cors_origins)


settings = Settings()
