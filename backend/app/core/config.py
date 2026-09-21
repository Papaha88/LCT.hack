"""Настройки приложения. Значения берутся из переменных окружения или `.env`."""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

APP_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "Финни — API справочников и прогресса"
    app_version: str = "1.0.0"

    # По умолчанию SQLite-файл рядом с приложением: бэкенд поднимается одной
    # командой без Docker. В docker-compose подставляется Postgres.
    database_url: str = "sqlite:///./finni.db"

    content_dir: Path = APP_DIR / "content" / "data"
    content_cache_max_age: int = 300

    # Секретов у сервиса нет: контент публичный, прогресс адресуется UUID
    # профиля. Открытый CORS нужен веб-прототипу, мобильному он безразличен.
    cors_allow_origins: list[str] = ["*"]

    @property
    def sqlalchemy_url(self) -> str:
        """URL из compose (`postgresql://`) — под драйвер psycopg 3."""
        if self.database_url.startswith("postgresql://"):
            return self.database_url.replace("postgresql://", "postgresql+psycopg://", 1)
        return self.database_url


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
