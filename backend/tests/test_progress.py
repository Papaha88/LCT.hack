"""Тесты синхронизации прогресса.

Проверяют две вещи: контракт обмена снимком (ревизии, конфликты, удаление)
и правила ТЗ, которые сервер обязан не пропускать — отрицательный баланс,
показатели питомца вне 0…100, несогласованное состояние заданий и образов.
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
    assert body["snapshot"]["lessons"]["solved"] == ["fin_1_food", "math_2_share"]
    assert body["snapshot"]["pet"]["variant_id"] == "v2"


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


def test_equipped_skin_must_be_owned(client, snapshot):
    """Надеть можно только купленный образ."""
    snapshot["skins"] = {"owned": [], "equipped": "cat_astronaut"}

    response = client.put(URL, json=snapshot)

    assert response.status_code == 422
    assert "образ" in response.text


def test_solved_lesson_cannot_be_in_retry(client, snapshot):
    snapshot["lessons"]["retry"] = ["fin_1_food"]

    assert client.put(URL, json=snapshot).status_code == 422


def test_age_outside_app_range_rejected(client, snapshot):
    """В приложении возраст 7, 8, 9 или 10 («10+»)."""
    snapshot["player"]["age"] = 12

    assert client.put(URL, json=snapshot).status_code == 422


def test_custom_goal_limits(client, snapshot):
    """Своя цель — от 50 до 5000 монет, как в приложении."""
    snapshot["goal"] = {"goal_id": None, "title": "Лего", "emoji": "🧸", "target": 10}

    assert client.put(URL, json=snapshot).status_code == 422

    snapshot["goal"]["target"] = 400
    body = client.put(URL, json=snapshot).json()
    assert body["warnings"] == [], "своя цель без goal_id — не предупреждение"


def test_broken_pet_stats_rejected(client, snapshot):
    snapshot["pet"]["stats"]["satiety"] = 140

    assert client.put(URL, json=snapshot).status_code == 422


def test_unknown_content_ids_become_warnings(client, snapshot):
    """Незнакомый id — не повод терять прогресс, только предупреждение."""
    snapshot["goal"]["goal_id"] = "goal_spaceship"
    snapshot["inventory"].append({"item_id": "food_unknown", "quantity": 1})
    snapshot["lessons"]["solved"].append("quest_budget_plan_60")
    snapshot["pet"]["variant_id"] = "sunny"

    body = client.put(URL, json=snapshot).json()

    codes = {warning["code"] for warning in body["warnings"]}
    assert codes == {"unknown_goal", "unknown_item", "unknown_lesson", "unknown_variant"}
    assert client.get(URL).status_code == 200, "прогресс всё равно сохранён"


def test_skin_of_other_species_is_warning(client, snapshot):
    snapshot["pet"]["species_id"] = "dog"

    body = client.put(URL, json=snapshot).json()

    assert [warning["code"] for warning in body["warnings"]] == ["skin_species_mismatch"]


def test_delete_removes_server_copy(client, snapshot):
    client.put(URL, json=snapshot)

    assert client.delete(URL).status_code == 204
    assert client.get(URL).status_code == 404
    # Идемпотентность: повторное удаление не ошибка.
    assert client.delete(URL).status_code == 204


def test_profile_id_must_be_uuid(client, snapshot):
    assert client.put("/api/v1/progress/kirill", json=snapshot).status_code == 422
