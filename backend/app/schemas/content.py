"""Схемы справочников (учебный контент и правила игровой экономики).

Контент лежит в JSON-файлах (`app/content/data`) и отделён от кода — по ТЗ
(раздел 3.2: «Учебный контент должен быть отделен от интерфейсного кода»,
раздел 2.5.14: «Новое задание добавляется без переработки основной логики»).
Эти модели — единственное описание формы контента: они же валидируют файлы
при старте приложения, они же формируют OpenAPI-контракт для мобильного.

Здесь описана только *структура* контента. Минимальный объём из раздела 2.6
ТЗ (6 заданий, 8 товаров, 3 цели…) проверяется при загрузке — см.
`app.content.library.enforce_minimums`: эти же модели используются для
отфильтрованных ответов (`?topic=savings`), где подмножество — норма.
"""

from datetime import date
from typing import Annotated, Literal, Union

from pydantic import BaseModel, ConfigDict, Field, model_validator

ItemKind = Literal["mandatory", "optional", "education"]


class ContentModel(BaseModel):
    """Базовая модель контента: лишние поля запрещены, чтобы опечатка в JSON
    ловилась при старте, а не превращалась в «молча потерянное» поле."""

    model_config = ConfigDict(extra="forbid")


def _ids(items: list) -> list[str]:
    return [item.id for item in items]


def _require_unique(items: list, label: str) -> None:
    ids = _ids(items)
    duplicates = {item_id for item_id in ids if ids.count(item_id) > 1}
    if duplicates:
        raise ValueError(f"{label}: повторяющиеся id — {sorted(duplicates)}")


# --------------------------------------------------------------------------
# Каталог покупок
# --------------------------------------------------------------------------


class StatEffects(ContentModel):
    """Влияние покупки на показатели питомца (ТЗ 2.5.6)."""

    satiety: int = 0
    happiness: int = 0
    cleanliness: int = 0


class CatalogUnlock(ContentModel):
    """Условие, при котором позиция появляется в магазине."""

    pet_stage: str | None = None
    education_level: int | None = Field(default=None, ge=1)


class EducationMeta(ContentModel):
    """Курс обучения: вложение в себя, увеличивающее будущий доход."""

    level: int = Field(ge=1)
    requires_level: int = Field(ge=0)
    income_multiplier: int = Field(ge=1)


class CatalogCategory(ContentModel):
    id: str
    title: str
    emoji: str
    kind: ItemKind


class CatalogItem(ContentModel):
    id: str
    title: str = Field(max_length=20, description="До 20 символов — требование к карточке товара")
    category: str
    kind: ItemKind
    price: int = Field(ge=0)
    emoji: str
    consumable: bool
    effects: StatEffects = Field(default_factory=StatEffects)
    description: str
    finni_hint: str = Field(description="Реплика Финни после покупки")
    purchase_limit: int | None = Field(default=None, ge=1)
    slot: str | None = Field(default=None, description="Слот на главном экране (миска, лежанка…)")
    unlock: CatalogUnlock | None = None
    resale_rate: float | None = Field(default=None, ge=0, le=1)
    education: EducationMeta | None = None


class CatalogFile(ContentModel):
    version: str
    updated_at: date
    categories: list[CatalogCategory] = Field(min_length=1)
    items: list[CatalogItem]

    @model_validator(mode="after")
    def _check(self) -> "CatalogFile":
        _require_unique(self.categories, "catalog.categories")
        _require_unique(self.items, "catalog.items")
        known = {category.id for category in self.categories}
        unknown = {item.category for item in self.items} - known
        if unknown:
            raise ValueError(f"catalog.items: неизвестные категории — {sorted(unknown)}")
        return self


# --------------------------------------------------------------------------
# Цели накопления
# --------------------------------------------------------------------------


class GoalReward(ContentModel):
    xp: int = Field(default=0, ge=0)
    coins: int = Field(default=0, ge=0)
    unlocks_item_id: str | None = None


class Goal(ContentModel):
    id: str
    title: str
    price: int = Field(ge=1)
    emoji: str
    description: str
    suggested_periods: int = Field(ge=1, description="Ориентир срока при регулярном пополнении")
    suggested_per_period: int = Field(ge=1)
    reward: GoalReward
    finni_line: str


class GoalsFile(ContentModel):
    version: str
    updated_at: date
    items: list[Goal]

    @model_validator(mode="after")
    def _check(self) -> "GoalsFile":
        _require_unique(self.items, "goals.items")
        return self


# --------------------------------------------------------------------------
# Задания
# --------------------------------------------------------------------------


class QuestReward(ContentModel):
    coins: int = Field(ge=0, description="ТЗ 2.5.8: задания начисляют игровую валюту")
    xp: int = Field(ge=0)


class QuestEffects(ContentModel):
    coins: int = 0
    satiety: int = 0
    happiness: int = 0
    cleanliness: int = 0
    savings: int = 0


class ChoiceOption(ContentModel):
    id: str
    title: str
    is_correct: bool
    explanation: str = Field(description="Показывается при любом ответе (ТЗ 2.5.8)")
    effects: QuestEffects = Field(default_factory=QuestEffects)
    recovery_hint: str | None = Field(
        default=None, description="Путь восстановления после неудачного выбора (ТЗ 2.5.9)"
    )


class AllocationDirection(ContentModel):
    id: str
    title: str
    emoji: str
    min: int | None = Field(default=None, ge=0)
    max: int | None = Field(default=None, ge=0)
    hint: str | None = None
    message_if_below: str | None = None
    message_if_above: str | None = None


class AllocationTask(ContentModel):
    available: int = Field(ge=1)
    step: int = Field(ge=1)
    must_use_all: bool = False
    directions: list[AllocationDirection] = Field(min_length=3)
    success_explanation: str
    partial_explanation: str

    @model_validator(mode="after")
    def _check(self) -> "AllocationTask":
        _require_unique(self.directions, "quest.allocation.directions")
        required = sum(direction.min or 0 for direction in self.directions)
        if required > self.available:
            raise ValueError("quest.allocation: сумма минимумов больше доступной суммы")
        return self


class OrderingItem(ContentModel):
    id: str
    title: str
    emoji: str


class OrderingTask(ContentModel):
    shuffle: bool = True
    items: list[OrderingItem] = Field(min_length=3)
    correct_order: list[str] = Field(min_length=3)
    explanation: str
    partial_explanation: str

    @model_validator(mode="after")
    def _check(self) -> "OrderingTask":
        _require_unique(self.items, "quest.ordering.items")
        if sorted(self.correct_order) != sorted(_ids(self.items)):
            raise ValueError("quest.ordering.correct_order не совпадает со списком карточек")
        return self


class QuestBase(ContentModel):
    id: str
    topic: str
    title: str
    situation: str
    finni_intro: str
    reward: QuestReward
    difficulty: int = Field(ge=1, le=3)
    tags: list[str] = Field(default_factory=list)
    wrap_up: str = Field(description="Короткий вывод после задания, независимо от ответа")


class ChoiceQuest(QuestBase):
    type: Literal["choice"]
    options: list[ChoiceOption] = Field(min_length=2)

    @model_validator(mode="after")
    def _check(self) -> "ChoiceQuest":
        _require_unique(self.options, f"quest {self.id}: options")
        if not any(option.is_correct for option in self.options):
            raise ValueError(f"quest {self.id}: нет ни одного верного варианта")
        return self


class AllocationQuest(QuestBase):
    type: Literal["allocation"]
    allocation: AllocationTask


class OrderingQuest(QuestBase):
    type: Literal["ordering"]
    ordering: OrderingTask


Quest = Annotated[
    Union[ChoiceQuest, AllocationQuest, OrderingQuest],
    Field(discriminator="type"),
]


class QuestTopic(ContentModel):
    id: str
    title: str
    emoji: str
    skill: str = Field(description="Образовательный результат темы")


class QuestsFile(ContentModel):
    version: str
    updated_at: date
    topics: list[QuestTopic]
    items: list[Quest]

    @model_validator(mode="after")
    def _check(self) -> "QuestsFile":
        _require_unique(self.topics, "quests.topics")
        _require_unique(self.items, "quests.items")
        known = {topic.id for topic in self.topics}
        unknown = {quest.topic for quest in self.items} - known
        if unknown:
            raise ValueError(f"quests.items: неизвестные темы — {sorted(unknown)}")
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


class GlossaryFile(ContentModel):
    version: str
    updated_at: date
    items: list[GlossaryTerm]

    @model_validator(mode="after")
    def _check(self) -> "GlossaryFile":
        _require_unique(self.items, "glossary.items")
        return self


# --------------------------------------------------------------------------
# Внешний вид питомца
# --------------------------------------------------------------------------


class PetSpecies(ContentModel):
    id: str
    title: str
    emoji: str


class PetPalette(ContentModel):
    id: str
    title: str
    body: str
    belly: str
    accent: str


class NicknameRules(ContentModel):
    min_length: int = Field(ge=1)
    max_length: int = Field(ge=1)
    trim_spaces: bool
    hint: str


class PetsFile(ContentModel):
    version: str
    updated_at: date
    species: list[PetSpecies]
    palettes: list[PetPalette]
    name_suggestions: list[str]
    nickname_rules: NicknameRules

    @model_validator(mode="after")
    def _check(self) -> "PetsFile":
        _require_unique(self.species, "pets.species")
        _require_unique(self.palettes, "pets.palettes")
        return self


# --------------------------------------------------------------------------
# Правила игровой экономики
# --------------------------------------------------------------------------


class Currency(ContentModel):
    code: str
    title: str
    emoji: str


class IncomeSource(ContentModel):
    id: str
    title: str
    explain: str = Field(description="ТЗ 2.5.4: у каждого начисления понятен источник")


class IncomeRules(ContentModel):
    base_income_per_period: int = Field(ge=1)
    daily_login_bonus: int = Field(ge=0)
    course_income_multiplier: int = Field(ge=1)
    max_education_level: int = Field(ge=1)
    sources: list[IncomeSource] = Field(min_length=1)


class PeriodRules(ContentModel):
    periods_per_year: int = Field(ge=1)
    demo_mode_periods: int = Field(ge=1, description="ТЗ 2.6: не менее 5 периодов подряд")
    demo_mode_skips_real_time: bool


class BudgetDirection(ContentModel):
    id: str
    title: str
    emoji: str
    categories: list[str]
    explain: str


class BudgetRules(ContentModel):
    step: int = Field(ge=1)
    alt_step: int = Field(ge=1)
    allow_unallocated: bool
    unallocated_hint: str
    editable_until_confirmed: bool
    directions: list[BudgetDirection] = Field(
        min_length=3, description="ТЗ 2.5.5: минимум 3 направления"
    )


class DepositRules(ContentModel):
    annual_rate: float = Field(ge=0, le=1)
    accrual: str
    min_amount: int = Field(ge=0)
    quick_amounts: list[int] = Field(min_length=1)
    withdraw_requires_confirmation: bool
    explain: str


class PetStat(ContentModel):
    id: str
    title: str
    emoji: str
    max: int = Field(ge=1)
    decay_per_period: int = Field(ge=0)
    low_threshold: int = Field(ge=0)


class PetStage(ContentModel):
    id: str
    title: str
    order: int = Field(ge=1)
    min_xp: int = Field(ge=0)


class PetMood(ContentModel):
    id: str
    title: str
    emoji: str
    min_average_stat: int = Field(ge=0, le=100)


class XpRule(ContentModel):
    id: str
    xp: int = Field(ge=0)
    explain: str


class PurchaseBlock(ContentModel):
    id: str
    when_stat: str
    lte: int = Field(ge=0)
    blocked_categories: list[str] = Field(min_length=1)
    message: str


class PetRules(ContentModel):
    stats: list[PetStat] = Field(min_length=3)
    stages: list[PetStage] = Field(description="ТЗ 2.6: не менее 3 стадий развития")
    moods: list[PetMood] = Field(min_length=2)
    xp_rules: list[XpRule] = Field(min_length=1)
    purchase_blocks: list[PurchaseBlock] = Field(default_factory=list)

    @model_validator(mode="after")
    def _check(self) -> "PetRules":
        _require_unique(self.stats, "economy.pet.stats")
        _require_unique(self.stages, "economy.pet.stages")
        known_stats = {stat.id for stat in self.stats}
        for block in self.purchase_blocks:
            if block.when_stat not in known_stats:
                raise ValueError(
                    f"economy.pet.purchase_blocks: неизвестный показатель {block.when_stat}"
                )
        return self


class GameRules(ContentModel):
    """Правила, которые по ТЗ нельзя нарушать, — поэтому только `true`."""

    negative_balance_forbidden: Literal[True]
    purchase_requires_confirmation: Literal[True]
    savings_withdraw_requires_confirmation: Literal[True]
    plan_editable_until_confirmed: Literal[True]
    quests_reward_coins: Literal[True]
    failure_creates_recovery_task: Literal[True]
    resale_rate: float = Field(ge=0, le=1)


class EconomyFile(ContentModel):
    version: str
    updated_at: date
    currency: Currency
    income: IncomeRules
    period: PeriodRules
    budget: BudgetRules
    deposit: DepositRules
    pet: PetRules
    rules: GameRules
    messages: dict[str, str]


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
    """Лёгкий ответ для проверки «не пора ли обновить локальный контент».

    Мобильный хранит `content_version` рядом с закэшированным контентом и
    скачивает разделы, у которых изменился `etag`.
    """

    content_version: str
    sections: list[ContentSectionInfo]


class ContentBundle(BaseModel):
    """Весь контент одним ответом — для первого запуска и офлайн-кэша."""

    content_version: str
    catalog: CatalogFile
    goals: GoalsFile
    quests: QuestsFile
    glossary: GlossaryFile
    pets: PetsFile
    economy: EconomyFile
