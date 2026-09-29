"""Схемы прогресса локального игрового профиля.

Главный сценарий по ТЗ — офлайн: профиль живёт на устройстве (раздел 3.1),
приложение работает без сервера. Сервер — только резервная копия: выгрузить
снимок профиля и вернуть его обратно (смена устройства, переустановка,
проверка экспертом), поэтому обмен идёт целым снимком, а не отдельными
операциями: клиент — источник правды.

Форма снимка повторяет сохранение приложения (`finny_state_v1` в
`mobile/lib/models/game_state.dart`), только с говорящими id вместо индексов
enum: `species_id: "cat"` вместо `type: 0`, `variant_id: "v2"` вместо
`variant: 1`.

Персональные данные не принимаем (ТЗ 3.5): профиль адресуется UUID, который
генерирует само приложение, а из «личного» в снимке только игровое имя и
возраст 7–10 для подбора класса заданий.
"""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

SCHEMA_VERSION = "2.0"


class ProgressModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class ProfileSettings(ProgressModel):
    dark_theme: bool = False


class PlayerState(ProgressModel):
    nickname: str = Field(min_length=1, max_length=15)
    age: int | None = Field(
        default=None, ge=7, le=10, description="7, 8, 9 или 10 («10+»); null — старый сейв"
    )


class PetStatsState(ProgressModel):
    satiety: int = Field(ge=0, le=100, description="В приложении — hunger")
    happiness: int = Field(ge=0, le=100)
    cleanliness: int = Field(ge=0, le=100)


class PetState(ProgressModel):
    name: str = Field(min_length=1, max_length=15)
    species_id: str = Field(description="cat | dog | penguin")
    variant_id: str = Field(description="Окраска: v1 | v2 | v3")
    level: int = Field(ge=1)
    xp: int = Field(ge=0, le=99, description="Опыт внутри текущего уровня")
    stats: PetStatsState


class WalletState(ProgressModel):
    """Отрицательный баланс запрещён ТЗ 2.5.6 — ограничение `ge=0` здесь и есть
    это правило: снимок с минусом сервер не примет (422)."""

    balance: int = Field(ge=0, description="Монетки в кошельке")
    savings: int = Field(ge=0, description="Монетки в копилке")


class GoalState(ProgressModel):
    """Цель копилки: готовая (`goal_id`) или своя (`goal_id: null`)."""

    goal_id: str | None = None
    title: str = Field(min_length=1, max_length=24)
    emoji: str = Field(min_length=1)
    target: int = Field(ge=50, le=5000)


class InventoryEntry(ProgressModel):
    item_id: str
    quantity: int = Field(ge=0)


class LessonsState(ProgressModel):
    """Задания дорог. Ошибка не отнимает прогресс — задание уходит в «Повтори»."""

    solved: list[str] = Field(default_factory=list)
    retry: list[str] = Field(default_factory=list, description="Задачи «Повтори»")
    mistakes: int = Field(default=0, ge=0)
    last_solved_day: int = Field(default=1, ge=1)

    @model_validator(mode="after")
    def _check(self) -> "LessonsState":
        if len(set(self.solved)) != len(self.solved) or len(set(self.retry)) != len(self.retry):
            raise ValueError("lessons: id заданий не должны повторяться")
        both = set(self.solved) & set(self.retry)
        if both:
            raise ValueError(f"lessons: решённое задание попало в «Повтори» — {sorted(both)}")
        return self


class SkinsState(ProgressModel):
    owned: list[str] = Field(default_factory=list, description="Купленные образы (навсегда)")
    equipped: str | None = Field(default=None, description="Надетый образ; null — обычный")

    @model_validator(mode="after")
    def _check(self) -> "SkinsState":
        if self.equipped is not None and self.equipped not in self.owned:
            raise ValueError("skins: надеть можно только купленный образ")
        return self


class StreakState(ProgressModel):
    days: int = Field(default=0, ge=0, description="Огонёк: дней подряд с действием")
    last_action_date: date | None = None


class ProgressSnapshot(ProgressModel):
    """Полный снимок локального профиля."""

    schema_version: str = Field(default=SCHEMA_VERSION)
    revision: int = Field(ge=1, description="Счётчик версий на клиенте: растёт при каждой выгрузке")
    updated_at: datetime = Field(description="Время последнего изменения на устройстве")
    day: int = Field(ge=1, description="Текущий период («День N»)")
    player: PlayerState
    pet: PetState
    wallet: WalletState
    goal: GoalState
    inventory: list[InventoryEntry] = Field(default_factory=list, description="Рюкзачок")
    lessons: LessonsState = Field(default_factory=LessonsState)
    skins: SkinsState = Field(default_factory=SkinsState)
    streak: StreakState = Field(default_factory=StreakState)
    last_bonus_date: date | None = Field(default=None, description="Когда выдан бонус за вход")
    settings: ProfileSettings = Field(default_factory=ProfileSettings)

    @model_validator(mode="after")
    def _check(self) -> "ProgressSnapshot":
        ids = [entry.item_id for entry in self.inventory]
        if len(set(ids)) != len(ids):
            raise ValueError("inventory: товар должен встречаться один раз")
        if self.lessons.last_solved_day > self.day:
            raise ValueError("lessons.last_solved_day не может быть позже текущего дня")
        return self


class ContentWarning(BaseModel):
    """Мягкое предупреждение о ссылке на неизвестный серверу контент.

    Не ошибка: у приложения может быть более новый контент, и терять из-за
    этого прогресс нельзя.
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
