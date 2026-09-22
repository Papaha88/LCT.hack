"""Тесты справочников.

Часть проверок намеренно повторяет минимальный объём контента из раздела 2.6
ТЗ: если аналитик уберёт задание или цель, тест упадёт раньше, чем это
увидит эксперт на демонстрации.
"""

import pytest

from app.content.library import ContentError, ContentLibrary, enforce_minimums
from app.core.config import settings

SECTIONS = {"catalog", "goals", "quests", "glossary", "pets", "economy"}


def test_content_loads_and_passes_minimums():
    """Сам факт загрузки означает, что контент прошёл проверки ТЗ 2.6."""
    library = ContentLibrary.load(settings.content_dir)

    assert library.content_version


def test_missing_content_breaks_startup():
    """Если аналитик уберёт задания, сервис не поднимется молча."""
    library = ContentLibrary.load(settings.content_dir)
    trimmed = library.quests.model_copy(update={"items": library.quests.items[:2]})

    with pytest.raises(ContentError, match="задания"):
        enforce_minimums(
            library.catalog,
            library.goals,
            trimmed,
            library.glossary,
            library.pets,
            library.economy,
        )


def test_manifest_lists_all_sections(client):
    body = client.get("/api/v1/content/manifest").json()

    assert body["content_version"]
    assert {section["name"] for section in body["sections"]} == SECTIONS
    assert all(section["etag"] for section in body["sections"])


def test_bundle_contains_every_section(client):
    body = client.get("/api/v1/content/bundle").json()
    manifest = client.get("/api/v1/content/manifest").json()

    assert SECTIONS <= set(body)
    assert body["content_version"] == manifest["content_version"]


def test_catalog_meets_required_minimum(client):
    body = client.get("/api/v1/content/catalog").json()
    items = body["items"]

    assert len(items) >= 8, "ТЗ 2.6: не менее 8 позиций покупок"
    assert sum(1 for item in items if item["kind"] == "mandatory") >= 5
    assert sum(1 for item in items if item["kind"] == "optional") >= 5
    assert all(len(item["title"]) <= 20 for item in items)
    assert all(item["price"] >= 0 for item in items)


def test_catalog_filters(client):
    optional = client.get("/api/v1/content/catalog", params={"kind": "optional"}).json()
    assert optional["items"]
    assert {item["kind"] for item in optional["items"]} == {"optional"}

    food = client.get("/api/v1/content/catalog", params={"category": "food"}).json()
    assert {item["category"] for item in food["items"]} == {"food"}


def test_catalog_item_by_id(client):
    assert client.get("/api/v1/content/catalog/food_apple").json()["title"] == "Яблочко"
    assert client.get("/api/v1/content/catalog/no_such_item").status_code == 404


def test_goals_meet_required_minimum(client):
    items = client.get("/api/v1/content/goals").json()["items"]

    assert len(items) >= 3, "ТЗ 2.6: не менее 3 целей накопления"
    assert all(goal["price"] > 0 and goal["suggested_periods"] > 0 for goal in items)


def test_quests_meet_required_minimum(client):
    body = client.get("/api/v1/content/quests").json()
    items, topics = body["items"], body["topics"]

    assert len(items) >= 6, "ТЗ 2.6: не менее 6 заданий"
    assert len(topics) >= 3, "ТЗ 2.5.8: минимум 3 темы"
    assert {quest["topic"] for quest in items} == {topic["id"] for topic in topics}
    # ТЗ 2.5.8: задания не сводятся к выбору ответа из вариантов.
    assert {quest["type"] for quest in items} > {"choice"}
    # ТЗ 2.5.8: объяснение выдаётся при любом ответе.
    for quest in items:
        for option in quest.get("options", []):
            assert option["explanation"]
    # ТЗ 2.5.8: задания начисляют монеты, а не только очки.
    assert all(quest["reward"]["coins"] > 0 for quest in items)


def test_quests_have_recovery_task(client):
    """ТЗ 2.5.9: у неудачного решения есть понятный путь восстановления."""
    body = client.get("/api/v1/content/quests", params={"tag": "recovery"}).json()

    assert body["items"], "нужно хотя бы одно задание-восстановление"


def test_quests_filter_by_topic(client):
    body = client.get("/api/v1/content/quests", params={"topic": "savings"}).json()

    assert body["items"]
    assert {quest["topic"] for quest in body["items"]} == {"savings"}


def test_pets_have_nine_combinations(client):
    body = client.get("/api/v1/content/pets").json()

    assert len(body["species"]) * len(body["palettes"]) >= 9, "ТЗ 2.6: 9+ комбинаций"
    assert len(body["name_suggestions"]) >= 5


def test_economy_rules(client):
    body = client.get("/api/v1/content/economy").json()

    assert len(body["pet"]["stages"]) >= 3, "ТЗ 2.6: не менее 3 стадий развития"
    assert body["period"]["demo_mode_periods"] >= 5, "ТЗ 2.6: 5 периодов подряд"
    assert len(body["budget"]["directions"]) >= 3, "ТЗ 2.5.5: минимум 3 направления"
    assert body["rules"]["negative_balance_forbidden"] is True
    assert body["rules"]["savings_withdraw_requires_confirmation"] is True


def test_glossary_not_empty(client):
    items = client.get("/api/v1/content/glossary").json()["items"]

    assert items, "ТЗ 2.5.11: нужен справочный раздел с терминами"
    assert all(term["definition"] for term in items)


def test_etag_returns_304(client):
    first = client.get("/api/v1/content/catalog")
    etag = first.headers["ETag"]

    second = client.get("/api/v1/content/catalog", headers={"If-None-Match": etag})

    assert first.status_code == 200
    assert second.status_code == 304
    assert second.content == b""


def test_filtered_response_has_its_own_etag(client):
    full = client.get("/api/v1/content/catalog").headers["ETag"]
    filtered = client.get("/api/v1/content/catalog", params={"kind": "optional"}).headers["ETag"]

    assert full != filtered

    # ETag от полного ответа не должен «подойти» к отфильтрованному.
    response = client.get(
        "/api/v1/content/catalog",
        params={"kind": "optional"},
        headers={"If-None-Match": full},
    )
    assert response.status_code == 200
