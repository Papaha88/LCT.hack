"""Справочники: каталог покупок, цели, задания, термины, питомцы, экономика.

Только чтение. Контент одинаков для всех, персональных данных здесь нет,
авторизация не нужна. Любой раздел можно скачать целиком и положить в
локальный кэш — игровой цикл после этого работает офлайн (ТЗ 3.1).
"""

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Path, Query, Request, Response, status

from app.api.deps import get_content
from app.api.http_cache import apply_cache_headers, not_modified, variant_etag
from app.content.library import ContentLibrary, ContentSection
from app.schemas.content import (
    CatalogFile,
    CatalogItem,
    ContentBundle,
    ContentManifest,
    EconomyFile,
    GlossaryFile,
    Goal,
    GoalsFile,
    ItemKind,
    PetsFile,
    Quest,
    QuestsFile,
)

router = APIRouter(prefix="/api/v1/content", tags=["Справочники"])

NOT_MODIFIED = {304: {"description": "Контент не изменился — используйте локальную копию"}}


def _respond(
    request: Request,
    response: Response,
    base_etag: str,
    payload: Any,
    variant: str = "",
) -> Any:
    etag = variant_etag(base_etag, variant)
    cached = not_modified(request, etag)
    if cached is not None:
        return cached
    apply_cache_headers(response, etag)
    return payload


def _section_etag(section: ContentSection) -> str:
    return section.etag


@router.get(
    "/manifest",
    response_model=ContentManifest,
    responses=NOT_MODIFIED,
    summary="Версии всех справочников",
    description=(
        "Лёгкий запрос «не пора ли обновить контент». Клиент хранит "
        "`content_version` и ETag каждого раздела и скачивает только изменившиеся."
    ),
)
def get_manifest(
    request: Request,
    response: Response,
    content: ContentLibrary = Depends(get_content),
) -> Any:
    return _respond(request, response, f'"{content.content_version}"', content.manifest())


@router.get(
    "/bundle",
    response_model=ContentBundle,
    responses=NOT_MODIFIED,
    summary="Весь контент одним ответом",
    description=(
        "Для первого запуска и офлайн-кэша: каталог, цели, задания, "
        "термины, питомцы, экономика."
    ),
)
def get_bundle(
    request: Request,
    response: Response,
    content: ContentLibrary = Depends(get_content),
) -> Any:
    return _respond(request, response, f'"{content.content_version}"', content.bundle())


@router.get(
    "/catalog",
    response_model=CatalogFile,
    responses=NOT_MODIFIED,
    summary="Каталог покупок",
    description="Товары с ценой, категорией и влиянием на питомца (ТЗ 2.5.6).",
)
def get_catalog(
    request: Request,
    response: Response,
    kind: ItemKind | None = Query(default=None, description="mandatory | optional | education"),
    category: str | None = Query(default=None, description="food, hygiene, toys…"),
    content: ContentLibrary = Depends(get_content),
) -> Any:
    section = content.section("catalog")
    catalog: CatalogFile = section.payload  # type: ignore[assignment]
    items = catalog.items
    if kind is not None:
        items = [item for item in items if item.kind == kind]
    if category is not None:
        items = [item for item in items if item.category == category]
    payload = catalog if items is catalog.items else catalog.model_copy(update={"items": items})
    return _respond(
        request,
        response,
        _section_etag(section),
        payload,
        variant=f"kind={kind}&category={category}",
    )


@router.get(
    "/catalog/{item_id}",
    response_model=CatalogItem,
    summary="Одна позиция каталога",
)
def get_catalog_item(
    item_id: str = Path(description="Идентификатор товара, например food_apple"),
    content: ContentLibrary = Depends(get_content),
) -> CatalogItem:
    for item in content.catalog.items:
        if item.id == item_id:
            return item
    raise HTTPException(status.HTTP_404_NOT_FOUND, detail=f"Товар {item_id} не найден")


@router.get(
    "/goals",
    response_model=GoalsFile,
    responses=NOT_MODIFIED,
    summary="Цели накопления",
    description="Цель с ценой, ориентиром срока и наградой (ТЗ 2.5.7).",
)
def get_goals(
    request: Request,
    response: Response,
    content: ContentLibrary = Depends(get_content),
) -> Any:
    section = content.section("goals")
    return _respond(request, response, _section_etag(section), section.payload)


@router.get("/goals/{goal_id}", response_model=Goal, summary="Одна цель")
def get_goal(
    goal_id: str,
    content: ContentLibrary = Depends(get_content),
) -> Goal:
    for goal in content.goals.items:
        if goal.id == goal_id:
            return goal
    raise HTTPException(status.HTTP_404_NOT_FOUND, detail=f"Цель {goal_id} не найдена")


@router.get(
    "/quests",
    response_model=QuestsFile,
    responses=NOT_MODIFIED,
    summary="Задания по финансовой грамотности",
    description=(
        "Минимум 6 заданий по 3 темам (ТЗ 2.5.8). Типы: `choice` — выбор с "
        "последствиями, `allocation` — распределение бюджета, `ordering` — "
        "порядок шагов. У каждого варианта есть объяснение — оно показывается "
        "независимо от правильности ответа."
    ),
)
def get_quests(
    request: Request,
    response: Response,
    topic: str | None = Query(default=None, description="budget_planning, savings, payments"),
    tag: str | None = Query(default=None, description="Например, recovery — задание-исправление"),
    content: ContentLibrary = Depends(get_content),
) -> Any:
    section = content.section("quests")
    quests: QuestsFile = section.payload  # type: ignore[assignment]
    items = quests.items
    if topic is not None:
        items = [quest for quest in items if quest.topic == topic]
    if tag is not None:
        items = [quest for quest in items if tag in quest.tags]
    payload = quests if items is quests.items else quests.model_copy(update={"items": items})
    return _respond(
        request,
        response,
        _section_etag(section),
        payload,
        variant=f"topic={topic}&tag={tag}",
    )


@router.get("/quests/{quest_id}", response_model=Quest, summary="Одно задание")
def get_quest(
    quest_id: str,
    content: ContentLibrary = Depends(get_content),
) -> Any:
    for quest in content.quests.items:
        if quest.id == quest_id:
            return quest
    raise HTTPException(status.HTTP_404_NOT_FOUND, detail=f"Задание {quest_id} не найдено")


@router.get(
    "/glossary",
    response_model=GlossaryFile,
    responses=NOT_MODIFIED,
    summary="Справочник терминов",
    description="Короткие объяснения финансовых слов для справочного раздела (ТЗ 2.5.11).",
)
def get_glossary(
    request: Request,
    response: Response,
    topic: str | None = Query(default=None),
    content: ContentLibrary = Depends(get_content),
) -> Any:
    section = content.section("glossary")
    glossary: GlossaryFile = section.payload  # type: ignore[assignment]
    items = glossary.items
    if topic is not None:
        items = [term for term in items if term.topic == topic]
    payload = glossary if items is glossary.items else glossary.model_copy(update={"items": items})
    return _respond(request, response, _section_etag(section), payload, variant=f"topic={topic}")


@router.get(
    "/pets",
    response_model=PetsFile,
    responses=NOT_MODIFIED,
    summary="Внешний вид питомца",
    description="Виды, окраски и готовые имена для онбординга: 3 × 3 = 9 комбинаций (ТЗ 2.6).",
)
def get_pets(
    request: Request,
    response: Response,
    content: ContentLibrary = Depends(get_content),
) -> Any:
    section = content.section("pets")
    return _respond(request, response, _section_etag(section), section.payload)


@router.get(
    "/economy",
    response_model=EconomyFile,
    responses=NOT_MODIFIED,
    summary="Правила игровой экономики",
    description=(
        "Доход за период, шаг планирования, ставка вклада, пороги стадий "
        "питомца и обязательные правила. Вынесены в контент, чтобы баланс "
        "игры менялся без правок кода приложения (ТЗ 2.5.14)."
    ),
)
def get_economy(
    request: Request,
    response: Response,
    content: ContentLibrary = Depends(get_content),
) -> Any:
    section = content.section("economy")
    return _respond(request, response, _section_etag(section), section.payload)
