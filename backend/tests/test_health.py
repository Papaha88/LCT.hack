from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_get_pet_state():
    response = client.get("/pet/1")
    assert response.status_code == 200
    body = response.json()
    assert set(body.keys()) == {"name", "stage", "balance", "goal"}
