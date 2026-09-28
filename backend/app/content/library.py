"""Загрузка справочников из JSON и раздача их в виде готовых моделей.

Контент читается один раз при старте и проверяется по схемам из
`app.schemas.content`. Если файл сломан или не хватает обязательного минимума
из ТЗ — приложение не поднимется: лучше упасть при старте, чем отдать
мобильному наполовину валидный справочник.

Для каждого раздела считается ETag (хэш файла). Мобильный кэширует контент
офлайн и присылает `If-None-Match`, получая 304 вместо повторной загрузки.
"""

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

from pydantic import BaseModel, ValidationError

from app.schemas.content import (
    CatalogFile,
    ContentBundle,
    ContentManifest,
    ContentSectionInfo,
    EconomyFile,
    GlossaryFile,
    GoalsFile,
    PetsFile,
    QuestsFile,
)

SECTION_MODELS: dict[str, type[BaseModel]] = {
    "catalog": CatalogFile,
    "goals": GoalsFile,
    "quests": QuestsFile,
    "glossary": GlossaryFile,
    "pets": PetsFile,
    "economy": EconomyFile,
}


class ContentError(RuntimeError):
    """Контент не удалось загрузить или он не прошёл проверку."""


def enforce_minimums(
    catalog: CatalogFile,
    goals: GoalsFile,
    quests: QuestsFile,
    glossary: GlossaryFile,
    pets: PetsFile,
    economy: EconomyFile,
) -> None:
    """Минимальный объём демонстрационного контента, раздел 2.6 ТЗ.

    Проверяется при загрузке, а не в схемах: те же схемы описывают
    отфильтрованные ответы (`/quests?topic=savings`), где подмножество — норма.
    """
    problems: list[str] = []

    def require(condition: bool, message: str) -> None:
        if not condition:
            problems.append(message)

    mandatory = sum(1 for item in catalog.items if item.kind == "mandatory")
    optional = sum(1 for item in catalog.items if item.kind == "optional")
    require(len(catalog.items) >= 8, f"каталог: нужно 8+ позиций, есть {len(catalog.items)}")
    require(mandatory >= 5, f"каталог: нужно 5+ обязательных позиций, есть {mandatory}")
    require(optional >= 5, f"каталог: нужно 5+ необязательных позиций, есть {optional}")

    require(len(goals.items) >= 3, f"цели: нужно 3+, есть {len(goals.items)}")

    require(len(quests.items) >= 6, f"задания: нужно 6+, есть {len(quests.items)}")
    require(len(quests.topics) >= 3, f"задания: нужно 3+ темы, есть {len(quests.topics)}")
    empty_topics = {topic.id for topic in quests.topics} - {quest.topic for quest in quests.items}
    require(not empty_topics, f"задания: темы без заданий — {sorted(empty_topics)}")

    require(bool(glossary.items), "глоссарий: нужен хотя бы один термин")

    combinations = len(pets.species) * len(pets.palettes)
    require(combinations >= 9, f"питомец: нужно 9+ комбинаций внешнего вида, есть {combinations}")
    require(len(pets.name_suggestions) >= 5, "питомец: нужно 5+ готовых имён для подсказки")

    require(len(economy.pet.stages) >= 3, "питомец: нужно 3+ стадии развития")
    require(economy.period.demo_mode_periods >= 5, "демо-режим: нужно 5+ периодов подряд")

    if problems:
        raise ContentError(
            "Контент не покрывает минимум из ТЗ (раздел 2.6):\n- " + "\n- ".join(problems)
        )


@dataclass(frozen=True)
class ContentSection:
    name: str
    payload: BaseModel
    etag: str
    version: str

    @property
    def items_count(self) -> int | None:
        items = getattr(self.payload, "items", None)
        return len(items) if isinstance(items, list) else None

    @property
    def url(self) -> str:
        return f"/api/v1/content/{self.name}"


class ContentLibrary:
    """Загруженные и проверенные справочники."""

    def __init__(self, sections: dict[str, ContentSection]) -> None:
        self._sections = sections
        self.content_version = _digest(
            "|".join(f"{name}:{section.etag}" for name, section in sorted(sections.items()))
        )

    @classmethod
    def load(cls, directory: Path) -> "ContentLibrary":
        sections: dict[str, ContentSection] = {}
        for name, model in SECTION_MODELS.items():
            path = directory / f"{name}.json"
            if not path.is_file():
                raise ContentError(f"Не найден файл контента: {path}")
            raw = path.read_bytes()
            try:
                payload = model.model_validate(json.loads(raw))
            except json.JSONDecodeError as error:
                raise ContentError(f"{path.name}: некорректный JSON — {error}") from error
            except ValidationError as error:
                raise ContentError(f"{path.name}: контент не прошёл проверку —\n{error}") from error
            sections[name] = ContentSection(
                name=name,
                payload=payload,
                etag=f'"{hashlib.sha256(raw).hexdigest()[:32]}"',
                version=getattr(payload, "version", "0"),
            )
        library = cls(sections)
        enforce_minimums(
            library.catalog,
            library.goals,
            library.quests,
            library.glossary,
            library.pets,
            library.economy,
        )
        return library

    def section(self, name: str) -> ContentSection:
        try:
            return self._sections[name]
        except KeyError as error:
            raise ContentError(f"Неизвестный раздел контента: {name}") from error

    @property
    def catalog(self) -> CatalogFile:
        return self.section("catalog").payload  # type: ignore[return-value]

    @property
    def goals(self) -> GoalsFile:
        return self.section("goals").payload  # type: ignore[return-value]

    @property
    def quests(self) -> QuestsFile:
        return self.section("quests").payload  # type: ignore[return-value]

    @property
    def glossary(self) -> GlossaryFile:
        return self.section("glossary").payload  # type: ignore[return-value]

    @property
    def pets(self) -> PetsFile:
        return self.section("pets").payload  # type: ignore[return-value]

    @property
    def economy(self) -> EconomyFile:
        return self.section("economy").payload  # type: ignore[return-value]

    def manifest(self) -> ContentManifest:
        return ContentManifest(
            content_version=self.content_version,
            sections=[
                ContentSectionInfo(
                    name=section.name,
                    version=section.version,
                    etag=section.etag,
                    items=section.items_count,
                    url=section.url,
                )
                for section in sorted(self._sections.values(), key=lambda item: item.name)
            ],
        )

    def bundle(self) -> ContentBundle:
        return ContentBundle(
            content_version=self.content_version,
            catalog=self.catalog,
            goals=self.goals,
            quests=self.quests,
            glossary=self.glossary,
            pets=self.pets,
            economy=self.economy,
        )


def _digest(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()[:16]
