"""Загрузка и выгрузка прогресса локального профиля.

Сервер не ведёт игру: он принимает снимок профиля целиком, проверяет его на
соответствие правилам ТЗ (баланс не уходит в минус, план не превышает
бюджет) и хранит последнюю версию. Игровой цикл при этом остаётся офлайн —
если сети нет, приложение продолжает работать, а выгрузка произойдёт позже.
"""

from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from app.api.deps import get_content
from app.content.library import ContentLibrary
from app.db.base import get_session
from app.db.models import as_utc
from app.schemas.progress import (
    ProgressAck,
    ProgressConflict,
    ProgressSnapshot,
    StoredProgress,
)
from app.services import progress as service

router = APIRouter(prefix="/api/v1/progress", tags=["Прогресс"])

PROFILE_ID = Path(description="UUID локального профиля, который генерирует приложение")


@router.put(
    "/{profile_id}",
    response_model=ProgressAck,
    responses={
        201: {"model": ProgressAck, "description": "Профиль сохранён впервые"},
        409: {"model": ProgressConflict, "description": "На сервере более новая ревизия"},
        422: {"description": "Снимок нарушает правила ТЗ (например, отрицательный баланс)"},
    },
    summary="Выгрузить прогресс на сервер",
    description=(
        "Клиент присылает снимок целиком и увеличивает `revision` при каждой "
        "выгрузке. Если на сервере лежит бóльшая ревизия — 409 вместе с "
        "серверным снимком, чтобы приложение могло сравнить их и не потерять "
        "прогресс. Перезаписать принудительно — `?force=true`."
    ),
)
def upload_progress(
    snapshot: ProgressSnapshot,
    response: Response,
    profile_id: UUID = PROFILE_ID,
    force: bool = Query(default=False, description="Перезаписать серверную версию"),
    session: Session = Depends(get_session),
    content: ContentLibrary = Depends(get_content),
) -> Any:
    try:
        stored, created = service.save_progress(session, profile_id, snapshot, force=force)
    except service.ProgressConflictError as conflict:
        server = conflict.stored
        payload = ProgressConflict(
            detail="На сервере более новая версия прогресса",
            server_revision=server.revision,
            server_updated_at=as_utc(server.server_updated_at),
            server_snapshot=ProgressSnapshot.model_validate(server.snapshot),
        )
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content=payload.model_dump(mode="json"),
        )

    if created:
        response.status_code = status.HTTP_201_CREATED
    return ProgressAck(
        profile_id=profile_id,
        revision=stored.revision,
        server_updated_at=as_utc(stored.server_updated_at),
        created=created,
        warnings=service.check_against_content(snapshot, content),
    )


@router.get(
    "/{profile_id}",
    response_model=StoredProgress,
    responses={404: {"description": "Прогресс для этого профиля не выгружался"}},
    summary="Забрать прогресс с сервера",
    description="Нужен при переустановке приложения или смене устройства.",
)
def download_progress(
    profile_id: UUID = PROFILE_ID,
    session: Session = Depends(get_session),
) -> StoredProgress:
    stored = service.get_progress(session, profile_id)
    if stored is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            detail=f"Прогресс профиля {profile_id} не найден",
        )
    return StoredProgress(
        profile_id=profile_id,
        revision=stored.revision,
        server_updated_at=as_utc(stored.server_updated_at),
        snapshot=ProgressSnapshot.model_validate(stored.snapshot),
    )


@router.delete(
    "/{profile_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Удалить серверную копию прогресса",
    description=(
        "Для раздела взрослого (ТЗ 3.5: сброс и удаление данных доступны без "
        "обращения к разработчику). Операция идемпотентна: если копии нет, "
        "ответ всё равно 204."
    ),
)
def delete_progress(
    profile_id: UUID = PROFILE_ID,
    session: Session = Depends(get_session),
) -> Response:
    service.delete_progress(session, profile_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
