"""Точка входа FastAPI: API справочников и синхронизации прогресса «Финни»."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import content as content_routes
from app.api.routes import progress as progress_routes
from app.content.library import ContentLibrary
from app.core.config import settings
from app.db.base import init_db

DESCRIPTION = """
Бэкенд игры «Питомец Финни».

**Приложение работает без сервера.** Игра полностью офлайн: контент зашит в
код приложения, прогресс хранится на устройстве. Этот сервис необязательный —
он нужен для двух вещей:

1. **Справочники** (`/api/v1/content/*`) — тот же контент, что в приложении:
   магазин, цели копилки, задания дорог «Математика» и «Финансы», питомцы и
   правила экономики. JSON собирается из Dart-кода скриптом
   `scripts/sync_from_mobile.py`. Разделы кэшируются по ETag
   (`If-None-Match` → 304).
2. **Прогресс** (`/api/v1/progress/*`) — резервная копия снимка локального
   профиля (переустановка, смена устройства, проверка экспертом).

Персональные данные не собираются: профиль адресуется UUID, который
генерирует само приложение.
"""

TAGS = [
    {"name": "Справочники", "description": "Контент только на чтение, одинаковый для всех."},
    {"name": "Прогресс", "description": "Снимок локального профиля: выгрузка, загрузка, удаление."},
    {"name": "Служебное", "description": "Проверки доступности сервиса."},
]


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Контент проверяется на старте: битый JSON или нехватка обязательного
    # минимума из ТЗ уронят сервис сразу, а не в момент запроса с телефона.
    app.state.content = ContentLibrary.load(settings.content_dir)
    init_db()
    yield


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description=DESCRIPTION,
    openapi_tags=TAGS,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_allow_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(content_routes.router)
app.include_router(progress_routes.router)


@app.get("/health", tags=["Служебное"], summary="Проверка доступности")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/v1/health", tags=["Служебное"], summary="Проверка доступности и версии контента")
def health_v1() -> dict[str, str]:
    library: ContentLibrary | None = getattr(app.state, "content", None)
    return {
        "status": "ok",
        "app_version": settings.app_version,
        "content_version": library.content_version if library else "not_loaded",
    }

