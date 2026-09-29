"""Схемы справочников (учебный контент и правила игровой экономики).

Источник правды для контента — Dart-код мобильного приложения: приложение
работает офлайн, весь контент зашит в `mobile/lib/data`. JSON в
`app/content/data` собирается из него скриптом `scripts/sync_from_mobile.py`,
а эти модели — единственное описание формы контента: они же валидируют
файлы при старте, они же формируют OpenAPI-контракт.

Здесь описана только *структура* контента. Минимальный объём из раздела 2.6
ТЗ (6 заданий, 8 товаров, 3 цели…) проверяется при загрузке — см.
`app.content.library.enforce_minimums`: эти же модели используются для
отфильтрованных ответов (`?track=finance`), где подмножество — норма.
"""

from datetime import date
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

ItemKind = Literal["mandatory", "optional"]
StatId = Literal["satiety", "happiness", "cleanliness"]
HEX_COLOR = r"^#[0-9A-F]{6}$"


class ContentModel(BaseModel):
    """Базовая модель контента: лишние поля запрещены, чтобы опечатка в JSON
    ловилась при старте, а не превращалась в «молча потерянное» поле."""

    model_config = ConfigDict(extra="forbid")


class ContentFile(ContentModel):
    version: str
    updated_at: date
    source: str | None = Field(default=None, description="Откуда в приложении взят контент")


def _ids(items: list) -> list[str]:
    return [item.id for item in items]


def _require_unique(items: list, label: str) -> None:
    ids = _ids(items)
    duplicates = {item_id for item_id in ids if ids.count(item_id) > 1}
    if duplicates:
        raise ValueError(f"{label}: повторяющиеся id — {sorted(duplicates)}")


# --------------------------------------------------------------------------
# Каталог магазина
# --------------------------------------------------------------------------


class ItemEffects(ContentModel):
    """Прирост показателей питомца при использовании предмета из рюкзачка."""

    satiety: int = Field(default=0, ge=0, description="В приложении поле называется hunger")
    happiness: int = Field(default=0, ge=0)
    cleanliness: int = Field(default=0, ge=0)
    xp: int = Field(default=0, ge=0)


class CatalogCategory(ContentModel):
    id: str
    title: str
    emoji: str
    kind: ItemKind = Field(description="mandatory — «надо», optional — «хочу»")


class CatalogItem(ContentModel):
    id: str
    title: str = Field(max_length=20, description="До 20 символов — требование к карточке товара")
    category: str
    kind: ItemKind
    price: int = Field(ge=1)
    emoji: str
    effects: ItemEffects
    effect_text: str = Field(description="Реплика после использования предмета")
    badge: str | None = Field(default=None, description="Ярлык на карточке: «Хит», «Новинка»…")


class DealOfDay(ContentModel):
    discount_percent: int = Field(ge=0, le=100)
    day_multiplier: int = Field(ge=1)
    day_offset: int = Field(ge=0)
    min_price: int = Field(ge=0)
    explain: str


class CatalogFile(ContentFile):
    categories: list[CatalogCategory] = Field(min_length=1)
    items: list[CatalogItem]
    deal_of_day: DealOfDay

    @model_validator(mode="after")
    def _check(self) -> "CatalogFile":
        _require_unique(self.categories, "catalog.categories")
        _require_unique(self.items, "catalog.items")
        kinds = {category.id: category.kind for category in self.categories}
        for item in self.items:
            if item.category not in kinds:
                raise ValueError(f"catalog.items: неизвестная категория {item.category}")
            if item.kind != kinds[item.category]:
                raise ValueError(f"catalog.items: {item.id} — kind не совпадает с категорией")
        return self


# --------------------------------------------------------------------------
# Цели копилки
# --------------------------------------------------------------------------


class Goal(ContentModel):
    id: str
    title: str
    emoji: str
    price: int = Field(ge=1)
    hint: str = Field(description="Совет Финни: сколько откладывать и как долго")


class CustomGoalRules(ContentModel):
    allowed: bool
    min_target: int = Field(ge=1)
    max_target: int = Field(ge=1)
    title_max_length: int = Field(ge=1)
    emoji_choices: list[str] = Field(min_length=1)


class GoalsFile(ContentFile):
    items: list[Goal]
    default_goal_id: str
    custom_goal: CustomGoalRules

    @model_validator(mode="after")
    def _check(self) -> "GoalsFile":
        _require_unique(self.items, "goals.items")
        if self.default_goal_id not in _ids(self.items):
            raise ValueError(f"goals.default_goal_id: нет цели {self.default_goal_id}")
        return self


# --------------------------------------------------------------------------
# Задания: дороги «Математика» и «Финансы»
# --------------------------------------------------------------------------


class LessonReward(ContentModel):
    coins: int = Field(ge=1, description="ТЗ 2.5.8: задания начисляют игровую валюту")
    xp: int = Field(ge=0)


class Lesson(ContentModel):
    id: str
    track: str
    grade: int = Field(ge=1, le=4, description="Класс 1–4: сложность и награда")
    title: str
    emoji: str
    question: str
    options: list[str] = Field(min_length=2, description="Ответ выбирается кнопкой")
    correct_index: int = Field(ge=0)
    answer: str = Field(description="Разбор — показывается после ответа")
    note: str = Field(description="Справка: правило, которое стоит запомнить")
    reward: LessonReward

    @model_validator(mode="after")
    def _check(self) -> "Lesson":
        if self.correct_index >= len(self.options):
            raise ValueError(f"lesson {self.id}: correct_index вне списка вариантов")
        return self


class TrackSection(ContentModel):
    grade: int = Field(ge=1, le=4)
    title: str


class LessonTrack(ContentModel):
    id: str
    title: str
    emoji: str
    color: str = Field(pattern=HEX_COLOR)
    sections: list[TrackSection] = Field(min_length=1)


class AgeGrade(ContentModel):
    age: int = Field(ge=1)
    grade: int = Field(ge=1)


class LessonRules(ContentModel):
    options_per_lesson: int = Field(ge=2)
    reward_base: int = Field(ge=0)
    reward_per_grade: int = Field(ge=0)
    xp_per_lesson: int = Field(ge=0)
    reward_only_first_solve: bool
    mistake_goes_to_retry: bool = Field(description="ТЗ 2.5.9: ошибка → задача «Повтори»")
    mistake_penalty: int = Field(ge=0)
    age_to_grade: list[AgeGrade] = Field(min_length=1)
    age_to_grade_explain: str


class QuestsFile(ContentFile):
    tracks: list[LessonTrack]
    rules: LessonRules
    items: list[Lesson]

    @model_validator(mode="after")
    def _check(self) -> "QuestsFile":
        _require_unique(self.tracks, "quests.tracks")
        _require_unique(self.items, "quests.items")
        grades = {track.id: {section.grade for section in track.sections} for track in self.tracks}
        rules = self.rules
        for lesson in self.items:
            if lesson.track not in grades:
                raise ValueError(f"lesson {lesson.id}: неизвестная дорога {lesson.track}")
            if lesson.grade not in grades[lesson.track]:
                raise ValueError(f"lesson {lesson.id}: у дороги нет раздела {lesson.grade} класса")
            if len(lesson.options) != rules.options_per_lesson:
                raise ValueError(f"lesson {lesson.id}: нужно {rules.options_per_lesson} варианта")
            expected = rules.reward_base + lesson.grade * rules.reward_per_grade
            if lesson.reward.coins != expected:
                raise ValueError(f"lesson {lesson.id}: награда не по правилу ({expected})")
        return self


# --------------------------------------------------------------------------
# Справочник терминов
# --------------------------------------------------------------------------


class GlossaryTerm(ContentModel):
    id: str
    term: str
    definition: str
    example: str
    topic: str


class GlossaryFile(ContentFile):
    items: list[GlossaryTerm]

    @model_validator(mode="after")
    def _check(self) -> "GlossaryFile":
        _require_unique(self.items, "glossary.items")
        return self


# --------------------------------------------------------------------------
# Питомец: виды, окраски, образы, этапы, настроение
# --------------------------------------------------------------------------


class PetVariant(ContentModel):
    id: str
    title: str
    bg_start: str = Field(pattern=HEX_COLOR)
    bg_end: str = Field(pattern=HEX_COLOR)
    accent: str = Field(pattern=HEX_COLOR)


class PetSpecies(ContentModel):
    id: str
    title: str
    emoji: str
    variants: list[PetVariant] = Field(min_length=1, description="Окраски, свои у каждого вида")

    @model_validator(mode="after")
    def _check(self) -> "PetSpecies":
        _require_unique(self.variants, f"pets.species.{self.id}.variants")
        return self


class PetSkin(ContentModel):
    """Образ питомца: покупается навсегда, надевается только на свой вид."""

    id: str
    species: str
    title: str
    emoji: str
    price: int = Field(ge=1)
    description: str
    bg_start: str = Field(pattern=HEX_COLOR)
    bg_end: str = Field(pattern=HEX_COLOR)


class PetStage(ContentModel):
    id: str
    title: str
    emoji: str
    min_level: int = Field(ge=1)


class PetMood(ContentModel):
    """Настроение. Правила проверяются по порядку, последнее — запасное, без условия.

    `stat: min` — самый низкий из трёх показателей.
    """

    id: str
    emoji: str
    phrase: str
    stat: Literal["min", "satiety", "happiness", "cleanliness"] | None
    op: Literal["lte", "gte"] | None
    value: int | None = Field(ge=0, le=100)


class NicknameRules(ContentModel):
    min_length: int = Field(ge=1)
    max_length: int = Field(ge=1)
    trim_spaces: bool
    profanity_filter: bool
    hint: str


class PetsFile(ContentFile):
    species: list[PetSpecies]
    skins: list[PetSkin]
    stages: list[PetStage]
    moods: list[PetMood] = Field(min_length=2)
    name_suggestions: list[str]
    nickname_rules: NicknameRules

    @model_validator(mode="after")
    def _check(self) -> "PetsFile":
        _require_unique(self.species, "pets.species")
        _require_unique(self.skins, "pets.skins")
        _require_unique(self.stages, "pets.stages")
        _require_unique(self.moods, "pets.moods")
        species = set(_ids(self.species))
        for skin in self.skins:
            if skin.species not in species:
                raise ValueError(f"pets.skins: {skin.id} — неизвестный вид {skin.species}")
        levels = [stage.min_level for stage in self.stages]
        if levels != sorted(set(levels)) or (levels and levels[0] != 1):
            raise ValueError("pets.stages: min_level должен расти и начинаться с 1")
        if self.moods[-1].stat is not None:
            raise ValueError("pets.moods: последнее настроение — запасное, без условия")
        return self

    @property
    def combinations(self) -> int:
        """Сколько вариантов внешнего вида «вид + окраска» (ТЗ 2.6: 9+)."""
        return sum(len(species.variants) for species in self.species)


# --------------------------------------------------------------------------
# Правила игровой экономики
# --------------------------------------------------------------------------


class Currency(ContentModel):
    code: str
    title: str
    emoji: str


class InventoryStart(ContentModel):
    item_id: str
    quantity: int = Field(ge=1)


class StartState(ContentModel):
    balance: int = Field(ge=0)
    inventory: list[InventoryStart]
    pet_level: int = Field(ge=1)
    pet_stats: int = Field(ge=0, le=100)
    day: int = Field(ge=1)


class IncomeSource(ContentModel):
    id: str
    title: str
    explain: str = Field(description="ТЗ 2.5.4: у каждого начисления понятен источник")


class IncomeLevel(ContentModel):
    level: int = Field(ge=1)
    income: int = Field(ge=0)


class IncomeRules(ContentModel):
    depends_on: Literal["pet_level"]
    base: int = Field(ge=0)
    per_level: int = Field(ge=0)
    explain: str
    table: list[IncomeLevel] = Field(min_length=1)
    sources: list[IncomeSource] = Field(min_length=1)

    @model_validator(mode="after")
    def _check(self) -> "IncomeRules":
        for row in self.table:
            if row.income != self.base + row.level * self.per_level:
                raise ValueError(f"economy.income.table: уровень {row.level} не по формуле")
        return self


class DailyBonus(ContentModel):
    coins: int = Field(ge=0)
    once_per: Literal["calendar_day"]


class LevelUpRules(ContentModel):
    xp_per_level: int = Field(ge=1)
    coins_per_level: int = Field(ge=0)
    restores_stats: bool


class XpRule(ContentModel):
    id: str
    xp: int = Field(ge=0)
    explain: str


class PetStat(ContentModel):
    id: StatId
    title: str
    emoji: str
    max: int = Field(ge=1)
    decay_per_day: int = Field(ge=0)
    low_threshold: int = Field(ge=0)


class PeriodRules(ContentModel):
    title: str
    advance: Literal["manual_button"]
    skips_real_time: bool
    demo_mode_periods: int = Field(ge=1, description="ТЗ 2.6: не менее 5 периодов подряд")


class SavingsRules(ContentModel):
    quick_amounts: list[int] = Field(min_length=1)
    plan_quick_amount: int = Field(ge=1)
    withdraw_amount: int = Field(ge=1)
    withdraw_requires_confirmation: bool
    suggested_per_day: int = Field(ge=1)


class StreakRules(ContentModel):
    counts: str
    resets_after_missed_day: bool
    coins_bonus: bool


class PlayerRules(ContentModel):
    min_age: int = Field(ge=1)
    max_age: int = Field(ge=1)
    max_age_label: str


class GameRules(ContentModel):
    negative_balance_forbidden: Literal[True]
    purchase_requires_confirmation: bool
    savings_withdraw_requires_confirmation: bool
    quests_reward_coins: Literal[True]
    mistake_creates_retry_task: bool
    mistake_loses_progress: Literal[False]


class EconomyFile(ContentFile):
    currency: Currency
    start: StartState
    income: IncomeRules
    daily_bonus: DailyBonus
    level_up: LevelUpRules
    xp_rules: list[XpRule] = Field(min_length=1)
    stats: list[PetStat] = Field(min_length=3)
    period: PeriodRules
    savings: SavingsRules
    streak: StreakRules
    player: PlayerRules
    rules: GameRules
    messages: dict[str, str]
    from_documents: dict[str, Any] = Field(
        default_factory=dict,
        description=(
            "Механики из документов команды, которых в приложении пока нет "
            "(вклад 20%, курсы, бонусы огонька, украшения). Справочно."
        ),
    )

    @model_validator(mode="after")
    def _check(self) -> "EconomyFile":
        _require_unique(self.xp_rules, "economy.xp_rules")
        _require_unique(self.stats, "economy.stats")
        return self


# --------------------------------------------------------------------------
# Манифест и общий пакет контента
# --------------------------------------------------------------------------


class ContentSectionInfo(BaseModel):
    name: str
    version: str
    etag: str
    items: int | None = Field(default=None, description="Количество записей, если раздел — список")
    url: str


class ContentManifest(BaseModel):
    """Лёгкий ответ для проверки «не пора ли обновить локальный контент»."""

    content_version: str
    sections: list[ContentSectionInfo]


class ContentBundle(BaseModel):
    """Весь контент одним ответом."""

    content_version: str
    catalog: CatalogFile
    goals: GoalsFile
    quests: QuestsFile
    glossary: GlossaryFile
    pets: PetsFile
    economy: EconomyFile
