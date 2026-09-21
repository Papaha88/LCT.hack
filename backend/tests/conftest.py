"""Общие фикстуры тестов.

База для тестов — SQLite в памяти: тесты не зависят от поднятого Postgres,
поэтому CI проходит без сервисов-контейнеров.
"""

import os

os.environ["DATABASE_URL"] = "sqlite://"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.db.base import Base, engine, init_db  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture()
def client():
    init_db()
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture()
def snapshot() -> dict:
    """Минимально осмысленный снимок профиля: онбординг пройден, первый период."""
    return {
        "schema_version": "1.0",
        "revision": 1,
        "updated_at": "2026-09-21T10:00:00Z",
        "current_period": 1,
        "player": {"nickname": "Ксюша"},
        "pet": {
            "name": "Кекс",
            "species_id": "cat",
            "palette_id": "sunny",
            "stage_id": "baby",
            "xp": 20,
            "stats": {"satiety": 80, "happiness": 70, "cleanliness": 90},
        },
        "wallet": {"balance": 35, "savings": 50, "deposit": 0},
        "education": {"level": 1, "base_income": 50, "purchased_course_ids": []},
        "goal": {"goal_id": "goal_scooter", "accumulated": 50},
        "plan": {
            "period": 1,
            "available": 50,
            "mandatory": 30,
            "optional": 10,
            "education": 0,
            "savings": 10,
            "confirmed": True,
        },
        "inventory": [{"item_id": "food_apple", "quantity": 1}],
        "purchases": [
            {
                "item_id": "food_apple",
                "price": 5,
                "quantity": 1,
                "period": 1,
                "at": "2026-09-21T09:30:00Z",
            }
        ],
        "quests": [
            {
                "quest_id": "quest_budget_priority",
                "option_id": "opt_dinner",
                "result": "correct",
                "earned_coins": 10,
                "earned_xp": 10,
                "period": 1,
                "at": "2026-09-21T09:40:00Z",
            }
        ],
        "periods": [
            {
                "period": 1,
                "income": 50,
                "planned": {"mandatory": 30, "optional": 10, "savings": 10},
                "actual": {"mandatory": 5, "optional": 0, "savings": 10},
                "saved": 10,
                "plan_followed": False,
            }
        ],
    }


PROFILE_ID = "6f1d1b2e-8f1a-4c35-9a0e-2f2b6f7b0a11"
