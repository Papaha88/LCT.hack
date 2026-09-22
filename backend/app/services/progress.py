"""Логика синхронизации прогресса.

Клиент — источник правды: сервер хранит последний присланный снимок и
отдаёт его обратно. Единственная «умная» часть — разрешение конфликта по
номеру ревизии и мягкая сверка снимка со справочниками.
"""

from uuid import UUID

from sqlalchemy.orm import Session

from app.content.library import ContentLibrary
from app.db.models import ProfileProgress, utcnow
from app.schemas.progress import ContentWarning, ProgressSnapshot


class ProgressConflictError(Exception):
    """На сервере лежит снимок новее присланного."""

    def __init__(self, stored: ProfileProgress) -> None:
        super().__init__("На сервере более новая версия прогресса")
        self.stored = stored


def get_progress(session: Session, profile_id: UUID) -> ProfileProgress | None:
    return session.get(ProfileProgress, str(profile_id))


def save_progress(
    session: Session,
    profile_id: UUID,
    snapshot: ProgressSnapshot,
    *,
    force: bool = False,
) -> tuple[ProfileProgress, bool]:
    """Сохранить снимок. Возвращает запись и признак «создан впервые».

    Повторная отправка той же ревизии допустима (клиент мог не получить
    ответ из-за сети) — это перезапись теми же данными, а не конфликт.
    """
    stored = get_progress(session, profile_id)
    payload = snapshot.model_dump(mode="json")

    if stored is None:
        stored = ProfileProgress(
            profile_id=str(profile_id),
            revision=snapshot.revision,
            schema_version=snapshot.schema_version,
            snapshot=payload,
            client_updated_at=snapshot.updated_at,
            created_at=utcnow(),
            server_updated_at=utcnow(),
        )
        session.add(stored)
        session.commit()
        return stored, True

    if snapshot.revision < stored.revision and not force:
        raise ProgressConflictError(stored)

    stored.revision = snapshot.revision
    stored.schema_version = snapshot.schema_version
    stored.snapshot = payload
    stored.client_updated_at = snapshot.updated_at
    stored.server_updated_at = utcnow()
    session.commit()
    return stored, False


def delete_progress(session: Session, profile_id: UUID) -> bool:
    stored = get_progress(session, profile_id)
    if stored is None:
        return False
    session.delete(stored)
    session.commit()
    return True


def check_against_content(
    snapshot: ProgressSnapshot,
    content: ContentLibrary,
) -> list[ContentWarning]:
    """Сверить ссылки снимка со справочниками сервера.

    Это предупреждения, а не ошибки: у приложения может быть более свежий
    (или собственный офлайн-) контент, и отказ сохранить прогресс из-за
    незнакомого id означал бы потерю прогресса — что ТЗ прямо запрещает.
    """
    warnings: list[ContentWarning] = []
    item_ids = {item.id for item in content.catalog.items}
    goal_ids = {goal.id for goal in content.goals.items}
    quest_ids = {quest.id for quest in content.quests.items}
    species_ids = {species.id for species in content.pets.species}
    palette_ids = {palette.id for palette in content.pets.palettes}
    stage_ids = {stage.id for stage in content.economy.pet.stages}

    def warn(code: str, ref: str, message: str) -> None:
        warnings.append(ContentWarning(code=code, message=message, ref=ref))

    if snapshot.goal and snapshot.goal.goal_id not in goal_ids:
        warn("unknown_goal", snapshot.goal.goal_id, "Цель отсутствует в справочнике сервера")

    for entry in snapshot.inventory:
        if entry.item_id not in item_ids:
            warn("unknown_item", entry.item_id, "Позиция инвентаря отсутствует в каталоге")

    for purchase in snapshot.purchases:
        if purchase.item_id not in item_ids:
            warn("unknown_item", purchase.item_id, "Покупка ссылается на неизвестный товар")

    for record in snapshot.quests:
        if record.quest_id not in quest_ids:
            warn("unknown_quest", record.quest_id, "Задание отсутствует в справочнике сервера")

    for course_id in snapshot.education.purchased_course_ids:
        if course_id not in item_ids:
            warn("unknown_course", course_id, "Курс отсутствует в каталоге")

    if snapshot.pet.species_id not in species_ids:
        warn("unknown_species", snapshot.pet.species_id, "Неизвестный вид питомца")
    if snapshot.pet.palette_id not in palette_ids:
        warn("unknown_palette", snapshot.pet.palette_id, "Неизвестная окраска питомца")
    if snapshot.pet.stage_id not in stage_ids:
        warn("unknown_stage", snapshot.pet.stage_id, "Неизвестная стадия развития питомца")

    # Дубликаты ref схлопываем: одинаковый товар мог встретиться много раз.
    unique: dict[tuple[str, str], ContentWarning] = {}
    for warning in warnings:
        unique.setdefault((warning.code, warning.ref), warning)
    return list(unique.values())
