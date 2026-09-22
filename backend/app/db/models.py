"""Таблицы базы данных."""

from datetime import UTC, datetime

from sqlalchemy import JSON, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


def utcnow() -> datetime:
    return datetime.now(UTC)


def as_utc(value: datetime) -> datetime:
    """SQLite возвращает время без таймзоны — восстанавливаем UTC, чтобы
    клиент всегда получал однозначную метку времени."""
    return value if value.tzinfo else value.replace(tzinfo=UTC)


class ProfileProgress(Base):
    """Снимок локального профиля.

    Снимок лежит целиком в JSON: его форму задаёт `ProgressSnapshot`, и когда
    в игре появится новое поле, таблицу менять не придётся — только схему.
    """

    __tablename__ = "profile_progress"

    profile_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    revision: Mapped[int] = mapped_column(Integer, nullable=False)
    schema_version: Mapped[str] = mapped_column(String(16), nullable=False)
    snapshot: Mapped[dict] = mapped_column(JSON, nullable=False)
    client_updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )
    server_updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False
    )
