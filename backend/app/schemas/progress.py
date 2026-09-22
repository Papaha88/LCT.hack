"""Схемы прогресса локального игрового профиля.

Главный сценарий по ТЗ — офлайн: профиль живёт на устройстве (раздел 3.1).
Сервер нужен только чтобы выгрузить снимок профиля и вернуть его обратно
(смена устройства, переустановка, проверка экспертом), поэтому обмен идёт
целым снимком, а не отдельными операциями: клиент — источник правды.

Персональные данные не принимаем (ТЗ 3.5): профиль адресуется UUID, который
генерирует само приложение, а из «личного» в снимке только игровое имя.
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

SCHEMA_VERSION = "1.0"


class ProgressModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class ProfileSettings(ProgressModel):
    """Настройки доступности (ТЗ 3.6: звук и анимации можно отключить)."""

    sound_enabled: bool = True
    animations_enabled: bool = True
    demo_mode: bool = False


class PlayerState(ProgressModel):
    nickname: str = Field(min_length=1, max_length=15)


class PetStatsState(ProgressModel):
    satiety: int = Field(ge=0, le=100)
    happiness: int = Field(ge=0, le=100)
    cleanliness: int = Field(ge=0, le=100)


class PetState(ProgressModel):
    name: str = Field(min_length=1, max_length=15)
    species_id: str
    palette_id: str
    stage_id: str
    xp: int = Field(ge=0)
    stats: PetStatsState


class WalletState(ProgressModel):
    """Отрицательный баланс запрещён ТЗ 2.5.6 — ограничение `ge=0` здесь и есть
    это правило: снимок с минусом сервер не примет (422)."""

    balance: int = Field(ge=0)
    savings: int = Field(ge=0, description="Накопления по текущей цели")
    deposit: int = Field(default=0, ge=0, description="Сумма на вкладе")


class EducationState(ProgressModel):
    level: int = Field(ge=1)
    base_income: int = Field(ge=0)
    purchased_course_ids: list[str] = Field(default_factory=list)


class GoalProgressState(ProgressModel):
    goal_id: str
    accumulated: int = Field(ge=0)
    selected_at: datetime | None = None


class BudgetPlanState(ProgressModel):
    """План периода. После подтверждения не редактируется (ТЗ 2.5.5),
    поэтому `confirmed` едет в снимке вместе с суммами."""

    period: int = Field(ge=1)
    available: int = Field(ge=0)
    mandatory: int = Field(ge=0)
    optional: int = Field(default=0, ge=0)
    education: int = Field(default=0, ge=0)
    savings: int = Field(default=0, ge=0)
    confirmed: bool = False

    @property
    def allocated(self) -> int:
        return self.mandatory + self.optional + self.education + self.savings

    @model_validator(mode="after")
    def _check_total(self) -> "BudgetPlanState":
        if self.allocated > self.available:
            raise ValueError(
                f"распределено {self.allocated} монет при доступных {self.available}: "
                "сумма плана не может превышать доступный бюджет"
            )
        return self


class InventoryEntry(ProgressModel):
    item_id: str
    quantity: int = Field(ge=0)


class PurchaseRecord(ProgressModel):
    item_id: str
    price: int = Field(ge=0)
    quantity: int = Field(default=1, ge=1)
    period: int = Field(ge=1)
    at: datetime


class QuestRecord(ProgressModel):
    quest_id: str
    option_id: str | None = None
    result: str = Field(pattern="^(correct|partly|incorrect)$")
    earned_coins: int = Field(default=0, ge=0)
    earned_xp: int = Field(default=0, ge=0)
    period: int = Field(ge=1)
    at: datetime


class PeriodSummary(ProgressModel):
    """Итог периода: план против факта (ТЗ 2.5.5)."""

    period: int = Field(ge=1)
    income: int = Field(ge=0)
    planned: dict[str, int] = Field(default_factory=dict)
    actual: dict[str, int] = Field(default_factory=dict)
    saved: int = Field(default=0, ge=0)
    plan_followed: bool = False


class ProgressSnapshot(ProgressModel):
    """Полный снимок локального профиля."""

    schema_version: str = Field(default=SCHEMA_VERSION)
    revision: int = Field(ge=1, description="Счётчик версий на клиенте: растёт при каждой выгрузке")
    updated_at: datetime = Field(description="Время последнего изменения на устройстве")
    current_period: int = Field(ge=1)
    player: PlayerState
    pet: PetState
    wallet: WalletState
    education: EducationState
    settings: ProfileSettings = Field(default_factory=ProfileSettings)
    goal: GoalProgressState | None = None
    plan: BudgetPlanState | None = None
    inventory: list[InventoryEntry] = Field(default_factory=list)
    purchases: list[PurchaseRecord] = Field(default_factory=list)
    quests: list[QuestRecord] = Field(default_factory=list)
    periods: list[PeriodSummary] = Field(default_factory=list)

    @model_validator(mode="after")
    def _check(self) -> "ProgressSnapshot":
        periods = [summary.period for summary in self.periods]
        if len(set(periods)) != len(periods):
            raise ValueError("periods: итоги периода не должны повторяться")
        return self


class ContentWarning(BaseModel):
    """Мягкое предупреждение о ссылке на неизвестный серверу контент.

    Не ошибка: у приложения может быть более новый контент (или собственный
    офлайн-набор), и терять из-за этого прогресс нельзя.
    """

    code: str
    message: str
    ref: str


class ProgressAck(BaseModel):
    profile_id: UUID
    revision: int
    server_updated_at: datetime
    created: bool = Field(description="true — профиль сохранён впервые")
    warnings: list[ContentWarning] = Field(default_factory=list)


class StoredProgress(BaseModel):
    profile_id: UUID
    revision: int
    server_updated_at: datetime
    snapshot: ProgressSnapshot


class ProgressConflict(BaseModel):
    """Ответ 409: на сервере снимок новее. Клиент решает — слить или перезаписать
    (`?force=true`), прогресс при этом не теряется ни с одной стороны."""

    detail: str
    server_revision: int
    server_updated_at: datetime
    server_snapshot: ProgressSnapshot
