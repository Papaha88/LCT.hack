# Backend (Python / FastAPI)

## Запуск локально

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate       # Windows: .venv\Scripts\activate
pip install -r requirements.txt -r requirements-dev.txt
cp .env.example .env
uvicorn app.main:app --reload
```

Открыть: http://127.0.0.1:8000/docs (Swagger UI генерируется автоматически).

## Тесты и линт

```bash
pytest -v
ruff check .
```

Это же прогоняется в CI (`.github/workflows/backend-ci.yml`) на каждый push/PR, если менялись файлы в `backend/`.

## Docker

```bash
docker build -t backend .
docker run -p 8000:8000 backend
```

## Структура

```
backend/
├── app/
│   ├── __init__.py
│   └── main.py       # точка входа FastAPI
├── tests/
│   └── test_health.py
├── requirements.txt       # runtime-зависимости
├── requirements-dev.txt   # pytest, ruff
├── Dockerfile
└── pyproject.toml         # конфиг ruff
```

## Полезные бесплатные материалы

- Официальная документация FastAPI: https://fastapi.tiangolo.com/ru/ (есть русский перевод)
- FastAPI + SQLAlchemy на практике: https://fastapi.tiangolo.com/tutorial/sql-databases/
