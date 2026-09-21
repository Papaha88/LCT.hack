"""ETag и заголовки кэширования для справочников.

Приложение работает офлайн и хранит контент локально, поэтому важнее всего
дешёвый ответ «ничего не изменилось»: клиент шлёт `If-None-Match` с
сохранённым ETag и получает 304 без тела.
"""

import hashlib

from fastapi import Request, Response

from app.core.config import settings


def variant_etag(base_etag: str, variant: str) -> str:
    """ETag для отфильтрованного ответа: он не должен совпадать с ETag всего
    раздела, иначе клиент закэширует часть контента как целое."""
    if not variant:
        return base_etag
    digest = hashlib.sha256(f"{base_etag}:{variant}".encode("utf-8")).hexdigest()[:32]
    return f'"{digest}"'


def not_modified(request: Request, etag: str) -> Response | None:
    """304, если у клиента уже есть эта версия раздела."""
    header = request.headers.get("if-none-match")
    if not header:
        return None
    candidates = {value.strip().removeprefix("W/") for value in header.split(",")}
    if "*" in candidates or etag in candidates:
        return Response(status_code=304, headers=_cache_headers(etag))
    return None


def apply_cache_headers(response: Response, etag: str) -> None:
    response.headers.update(_cache_headers(etag))


def _cache_headers(etag: str) -> dict[str, str]:
    return {"ETag": etag, "Cache-Control": f"public, max-age={settings.content_cache_max_age}"}
