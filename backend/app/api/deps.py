"""Общие зависимости FastAPI."""

from fastapi import Request

from app.content.library import ContentLibrary
from app.core.config import settings


def get_content(request: Request) -> ContentLibrary:
    """Справочники, загруженные при старте (см. lifespan в `app.main`).

    Если приложение подняли в обход lifespan (например, `TestClient` без
    контекстного менеджера) — загружаем контент по требованию и кэшируем.
    """
    library: ContentLibrary | None = getattr(request.app.state, "content", None)
    if library is None:
        library = ContentLibrary.load(settings.content_dir)
        request.app.state.content = library
    return library
