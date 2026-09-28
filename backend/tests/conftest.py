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
    """Снимок профиля в форме сохранения приложения: пройден онбординг, третий день."""
    return {
        "schema_version": "2.0",
        "revision": 1,
        "updated_at": "2026-09-21T10:00:00Z",
        "day": 3,
        "player": {"nickname": "Ксюша", "age": 8},
        "pet": {
            "name": "Кекс",
            "species_id": "cat",
            "variant_id": "v2",
            "level": 2,
            "xp": 20,
            "stats": {"satiety": 80, "happiness": 70, "cleanliness": 90},
        },
        "wallet": {"balance": 35, "savings": 50},
        "goal": {"goal_id": "goal_bike", "title": "Велосипед", "emoji": "🚲", "target": 300},
        "inventory": [
            {"item_id": "milk", "quantity": 1},
            {"item_id": "apple", "quantity": 2},
        ],
        "lessons": {
            "solved": ["fin_1_food", "math_2_share"],
            "retry": ["fin_2_budget"],
            "mistakes": 1,
            "last_solved_day": 2,
        },
        "skins": {"owned": ["cat_astronaut"], "equipped": "cat_astronaut"},
        "streak": {"days": 3, "last_action_date": "2026-09-21"},
        "last_bonus_date": "2026-09-21",
        "settings": {"dark_theme": False},
    }


PROFILE_ID = "6f1d1b2e-8f1a-4c35-9a0e-2f2b6f7b0a11"
