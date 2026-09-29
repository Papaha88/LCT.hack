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
    контент, и отказ сохранить прогресс из-за незнакомого id означал бы
    потерю прогресса — что ТЗ прямо запрещает.
    """
    warnings: list[ContentWarning] = []
    item_ids = {item.id for item in content.catalog.items}
    goal_ids = {goal.id for goal in content.goals.items}
    lesson_ids = {lesson.id for lesson in content.quests.items}
    variants = {
        species.id: {variant.id for variant in species.variants} for species in content.pets.species
    }
    skins = {skin.id: skin.species for skin in content.pets.skins}

    def warn(code: str, ref: str, message: str) -> None:
        warnings.append(ContentWarning(code=code, message=message, ref=ref))

    pet = snapshot.pet
    if pet.species_id not in variants:
        warn("unknown_species", pet.species_id, "Неизвестный вид питомца")
    elif pet.variant_id not in variants[pet.species_id]:
        warn("unknown_variant", pet.variant_id, "У этого вида нет такой окраски")

    if snapshot.goal.goal_id is not None and snapshot.goal.goal_id not in goal_ids:
        warn("unknown_goal", snapshot.goal.goal_id, "Цель отсутствует в справочнике сервера")

    for entry in snapshot.inventory:
        if entry.item_id not in item_ids:
            warn("unknown_item", entry.item_id, "Предмет рюкзачка отсутствует в каталоге")

    for lesson_id in [*snapshot.lessons.solved, *snapshot.lessons.retry]:
        if lesson_id not in lesson_ids:
            warn("unknown_lesson", lesson_id, "Задание отсутствует в справочнике сервера")

    for skin_id in snapshot.skins.owned:
        if skin_id not in skins:
            warn("unknown_skin", skin_id, "Образ отсутствует в справочнике сервера")

    equipped = snapshot.skins.equipped
    if equipped in skins and skins[equipped] != pet.species_id:
        # Приложение такой образ просто не показывает — питомец в обычной окраске.
        warn("skin_species_mismatch", equipped, "Надетый образ предназначен другому виду")

    # Дубликаты ref схлопываем: один и тот же id мог встретиться несколько раз.
    unique: dict[tuple[str, str], ContentWarning] = {}
    for warning in warnings:
        unique.setdefault((warning.code, warning.ref), warning)
    return list(unique.values())
