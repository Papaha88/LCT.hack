"""Тесты синхронизации прогресса.

Проверяют две вещи: контракт обмена снимком (ревизии, конфликты, удаление)
и правила ТЗ, которые сервер обязан не пропускать — отрицательный баланс и
план больше доступного бюджета.
"""

from tests.conftest import PROFILE_ID

URL = f"/api/v1/progress/{PROFILE_ID}"


def test_upload_creates_profile(client, snapshot):
    response = client.put(URL, json=snapshot)

    assert response.status_code == 201
    body = response.json()
    assert body["created"] is True
    assert body["revision"] == 1
    assert body["warnings"] == []


def test_download_returns_same_snapshot(client, snapshot):
    client.put(URL, json=snapshot)

    body = client.get(URL).json()

    assert body["revision"] == 1
    assert body["snapshot"]["pet"]["name"] == "Кекс"
    assert body["snapshot"]["wallet"]["balance"] == 35
    assert body["snapshot"]["quests"][0]["quest_id"] == "quest_budget_priority"


def test_download_unknown_profile_is_404(client):
    assert client.get(URL).status_code == 404


def test_second_upload_updates_profile(client, snapshot):
    client.put(URL, json=snapshot)

    snapshot["revision"] = 2
    snapshot["wallet"]["balance"] = 60
    response = client.put(URL, json=snapshot)

    assert response.status_code == 200
    assert response.json()["created"] is False
    assert client.get(URL).json()["snapshot"]["wallet"]["balance"] == 60


def test_same_revision_is_accepted_again(client, snapshot):
    """Клиент мог не получить ответ из-за сети и повторить выгрузку."""
    client.put(URL, json=snapshot)

    assert client.put(URL, json=snapshot).status_code == 200


def test_older_revision_conflicts(client, snapshot):
    snapshot["revision"] = 5
    client.put(URL, json=snapshot)

    snapshot["revision"] = 3
    snapshot["wallet"]["balance"] = 0
    response = client.put(URL, json=snapshot)

    assert response.status_code == 409
    body = response.json()
    assert body["server_revision"] == 5
    # Прогресс не потерян: сервер вернул свою версию целиком.
    assert body["server_snapshot"]["wallet"]["balance"] == 35


def test_force_overwrites_newer_server_copy(client, snapshot):
    snapshot["revision"] = 5
    client.put(URL, json=snapshot)

    snapshot["revision"] = 3
    response = client.put(URL, params={"force": True}, json=snapshot)

    assert response.status_code == 200
    assert client.get(URL).json()["revision"] == 3


def test_negative_balance_rejected(client, snapshot):
    """ТЗ 2.5.6: отрицательный баланс не допускается."""
    snapshot["wallet"]["balance"] = -10

    assert client.put(URL, json=snapshot).status_code == 422


def test_plan_over_budget_rejected(client, snapshot):
    """ТЗ 2.5.5: распределение не может превышать доступный бюджет."""
    snapshot["plan"]["mandatory"] = 100

    response = client.put(URL, json=snapshot)

    assert response.status_code == 422
    assert "план" in response.text.lower() or "бюджет" in response.text.lower()


def test_broken_pet_stats_rejected(client, snapshot):
    snapshot["pet"]["stats"]["satiety"] = 140

    assert client.put(URL, json=snapshot).status_code == 422


def test_unknown_content_ids_become_warnings(client, snapshot):
    """Незнакомый id — не повод терять прогресс, только предупреждение."""
    snapshot["goal"]["goal_id"] = "goal_spaceship"
    snapshot["purchases"][0]["item_id"] = "food_unknown"

    body = client.put(URL, json=snapshot).json()

    codes = {warning["code"] for warning in body["warnings"]}
    assert codes == {"unknown_goal", "unknown_item"}
    assert client.get(URL).status_code == 200, "прогресс всё равно сохранён"


def test_delete_removes_server_copy(client, snapshot):
    client.put(URL, json=snapshot)

    assert client.delete(URL).status_code == 204
    assert client.get(URL).status_code == 404
    # Идемпотентность: повторное удаление не ошибка.
    assert client.delete(URL).status_code == 204


def test_profile_id_must_be_uuid(client, snapshot):
    assert client.put("/api/v1/progress/kirill", json=snapshot).status_code == 422
