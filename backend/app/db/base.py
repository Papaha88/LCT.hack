"""Подключение к базе: движок, сессии, создание таблиц.

Хранится ровно одна сущность — снимок профиля, поэтому миграции (Alembic)
пока избыточны: схема создаётся при старте (`create_all`, идемпотентно).
"""

from collections.abc import Iterator
from typing import Any

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.config import settings


def _engine_options(url: str) -> dict[str, Any]:
    if not url.startswith("sqlite"):
        return {"pool_pre_ping": True}
    options: dict[str, Any] = {"connect_args": {"check_same_thread": False}}
    if url in ("sqlite://", "sqlite:///:memory:"):
        # In-memory база живёт ровно столько, сколько соединение, —
        # держим одно на всё приложение (так работают тесты).
        options["poolclass"] = StaticPool
    return options


_url = settings.sqlalchemy_url
engine = create_engine(_url, future=True, **_engine_options(_url))
SessionFactory = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


_schema_ready = False


def init_db() -> None:
    global _schema_ready
    from app.db import models  # noqa: F401  — регистрирует таблицы в метаданных

    Base.metadata.create_all(engine)
    _schema_ready = True


def get_session() -> Iterator[Session]:
    if not _schema_ready:
        init_db()
    with SessionFactory() as session:
        yield session
