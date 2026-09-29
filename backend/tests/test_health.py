from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_legacy_pet_stub_removed():
    """Заглушка из скелета репозитория удалена: приложение к серверу не ходит."""
    assert client.get("/pet/1").status_code == 404
