# Backend (Python / FastAPI)

Необязательный сервер справочников и резервной копии прогресса для игры
«Питомец Финни».

> **Приложение работает без сервера.** Игра полностью офлайн: весь контент
> (магазин, задания, цели, питомцы, экономика) зашит в Dart-код приложения,
> прогресс хранится на устройстве. Мобильное приложение к этому API
> не обращается — для игры и демонстрации сервер поднимать не нужно.

Зачем тогда бэкенд:

1. **Справочники** — тот же контент, что в приложении, в машиночитаемом виде
   (JSON + OpenAPI/Swagger). Удобно проверять экспертам и пригодится, если
   контент начнёт обновляться без пересборки приложения (ТЗ 2.5.14).
2. **Резервная копия прогресса** — выгрузка и восстановление снимка локального
   профиля (переустановка, смена устройства, проверка экспертом).

Персональные данные не собираются: профиль адресуется UUID, который генерирует
само приложение (ТЗ 3.5).

## Запуск локально (SQLite, без Docker)

Нужен Python 3.12+.

```bash
cd backend
python3.12 -m venv .venv
source .venv/bin/activate       # Windows: .venv\Scripts\activate
pip install -r requirements.txt -r requirements-dev.txt
cp .env.example .env
uvicorn app.main:app --reload
```

- Swagger UI: http://127.0.0.1:8000/docs
- ReDoc: http://127.0.0.1:8000/redoc
- спецификация: http://127.0.0.1:8000/openapi.json

База по умолчанию — файл SQLite (`finni.db`) рядом с приложением, больше ничего
ставить не нужно.

Если на машине нет Python 3.12, быстрее всего через [uv](https://docs.astral.sh/uv/):

```bash
uv venv -p 3.12 .venv && uv pip install -p .venv -r requirements.txt -r requirements-dev.txt
.venv/bin/uvicorn app.main:app --reload
```

## Запуск через Docker Compose (бэкенд + Postgres)

```bash
cd backend
docker compose up --build
```

Бэкенд — http://127.0.0.1:8000 (Swagger — http://127.0.0.1:8000/docs), Postgres —
порт 5432 (`app`/`app`/`app`, см. `docker-compose.yml`). Остановить:
`docker compose down`; удалить и данные — `docker compose down -v`.

Только сам бэкенд, без Compose (внутри контейнера будет SQLite):

```bash
docker build -t finni-backend .
docker run -p 8000:8000 finni-backend
```

## Тесты и линт

```bash
pytest -v
ruff check .
python scripts/sync_from_mobile.py --check   # JSON совпадает с приложением?
```

Тесты и линт прогоняет CI (`.github/workflows/backend-ci.yml`) на каждый PR,
затрагивающий `backend/`.

## Контент: откуда берётся

**Источник правды — Dart-код приложения.** JSON в `app/content/data/`
собирается из него скриптом:

```bash
python scripts/sync_from_mobile.py          # пересобрать JSON из mobile/lib
python scripts/sync_from_mobile.py --check  # только сверить (код 1 при расхождении)
```

| Файл | Откуда | Что внутри | Минимум по ТЗ 2.6 |
|---|---|---|---|
| `catalog.json` | `mobile/lib/data/shop_data.dart` | 6 отделов («надо»: еда, уход, здоровье; «хочу»: игры, наряды, уют), 26 товаров, скидка дня 30% | 8+ позиций, по 5+ «надо» и «хочу» |
| `quests.json` | `mobile/lib/data/lessons_data.dart` | дороги «Математика» (1–4 класс) и «Финансы» (1–3 класс), 35 заданий, награда 5 + класс × 10 | 6+ заданий, 3+ темы-раздела |
| `goals.json` | `mobile/lib/data/goals_data.dart` | 6 готовых целей, цель по умолчанию, правила своей цели (50…5000) | 3+ цели |
| `pets.json` | `mobile/lib/models/pet.dart`, `data/skins_data.dart`, `data/names_data.dart` | 3 вида × 3 окраски, 9 образов, этапы по уровню, настроение, имена для кубика | 9+ комбинаций, 3+ этапа |
| `economy.json` | `mobile/lib/models/game_state.dart` (+ экраны банка/плана) | старт, доход по уровню, бонус за вход, опыт и уровни, расход за день, копилка, огонёк; блок `from_documents` | 5+ периодов демо-режима |
| `glossary.json` | вручную, по заданиям дороги «Финансы» | термины для справочного раздела | — |

**`from_documents`** в `economy.json` — механики из документов команды
(игровая экономика, ТЗ экранов), которых в приложении пока нет: вклад 20% с
потолком 500, курсы 20/40/80/160, бонусы огонька +10/+20, коллекция из 20
украшений и продажа за 70%, план бюджета с шагом 5/10. Сервер отдаёт их
справочно, приложение ими не пользуется.

Форма контента описана Pydantic-моделями в `app/schemas/content.py`, они же
проверяют файлы **при старте**: опечатка, дубль id, ссылка на несуществующий
отдел/дорогу/вид, награда не по формуле или контента меньше минимума ТЗ —
сервис не поднимется и напишет, что именно не так.

## Эндпоинты

Полное описание с примерами — в Swagger (`/docs`) и в `openapi.json`.

### Справочники — `GET`, без авторизации

| Путь | Что отдаёт |
|---|---|
| `/api/v1/content/manifest` | версии и ETag всех разделов |
| `/api/v1/content/bundle` | весь контент одним ответом |
| `/api/v1/content/catalog` | магазин; фильтры `?kind=mandatory\|optional`, `?category=food` |
| `/api/v1/content/catalog/{item_id}` | один товар, например `apple` |
| `/api/v1/content/goals` · `/goals/{goal_id}` | цели копилки |
| `/api/v1/content/quests` | задания; фильтры `?track=math\|finance`, `?grade=1..4` |
| `/api/v1/content/quests/{quest_id}` | одно задание, например `fin_1_food` |
| `/api/v1/content/glossary` | термины; фильтр `?topic=finance_1` |
| `/api/v1/content/pets` | виды, окраски, образы, этапы, настроение, имена |
| `/api/v1/content/economy` | правила экономики приложения + `from_documents` |

Каждый раздел отдаёт `ETag` и `Cache-Control`; с `If-None-Match` приходит `304`.

### Резервная копия прогресса — `/api/v1/progress/{profile_id}`

`profile_id` — UUID, который генерирует приложение.

| Метод | Что делает |
|---|---|
| `PUT` | выгрузить снимок профиля целиком. `201` — впервые, `200` — обновлён |
| `GET` | забрать последний снимок (`404`, если не выгружался) |
| `DELETE` | удалить серверную копию (ТЗ 3.5). Идемпотентно, всегда `204` |

Снимок (схема `2.0`) повторяет сохранение приложения (`finny_state_v1`) с
говорящими id вместо индексов enum: игрок (имя, возраст 7–10), питомец (вид,
окраска `v1`–`v3`, уровень, опыт 0–99, показатели), кошелёк и копилка, цель
(готовая `goal_id` или своя), рюкзачок, задания (`solved`, `retry` —
«Повтори»), образы, огонёк, дата бонуса.

**Конфликты.** `revision` клиент увеличивает при каждой выгрузке. Если на
сервере ревизия больше — `409` с серверным снимком; перезаписать —
`?force=true`. Повтор той же ревизии — не конфликт.

**Проверки (`422`)** — отрицательный баланс или копилка, показатели вне 0…100,
возраст вне 7–10, своя цель вне 50…5000, надет некупленный образ, решённое
задание одновременно в «Повтори». Незнакомые серверу товар, задание, цель,
окраска или образ — **не** ошибка, а `warnings` в ответе: терять прогресс
из-за этого нельзя.

```bash
curl -X PUT http://127.0.0.1:8000/api/v1/progress/6f1d1b2e-8f1a-4c35-9a0e-2f2b6f7b0a11 \
  -H "Content-Type: application/json" \
  -d '{"revision":1,"updated_at":"2026-09-21T10:00:00Z","day":3,
       "player":{"nickname":"Ксюша","age":8},
       "pet":{"name":"Кекс","species_id":"cat","variant_id":"v2","level":2,"xp":20,
              "stats":{"satiety":80,"happiness":70,"cleanliness":90}},
       "wallet":{"balance":35,"savings":50},
       "goal":{"goal_id":"goal_bike","title":"Велосипед","emoji":"🚲","target":300},
       "inventory":[{"item_id":"milk","quantity":1}],
       "lessons":{"solved":["fin_1_food"],"retry":[],"mistakes":0,"last_solved_day":2}}'
```

Схема `2.0` несовместима со снимками `1.0` из прошлых версий сервера: если
Postgres в Compose уже содержит старые данные — `docker compose down -v`.

### Служебное

`GET /health` — проверка доступности. `GET /api/v1/health` — плюс версия
приложения и контента.

## Структура

```
backend/
├── app/
│   ├── main.py            # сборка приложения, lifespan, роутеры
│   ├── api/
│   │   ├── deps.py        # доступ к загруженному контенту
│   │   ├── http_cache.py  # ETag и Cache-Control
│   │   └── routes/        # content.py, progress.py
│   ├── content/
│   │   ├── data/          # JSON-справочники (собираются из mobile/lib)
│   │   └── library.py     # загрузка, минимум ТЗ, ETag, манифест
│   ├── core/config.py     # настройки из окружения/.env
│   ├── db/                # engine, сессии, таблица снимков профиля
│   ├── schemas/           # content.py (справочники), progress.py (прогресс)
│   └── services/progress.py  # сохранение снимка, конфликты, сверка с контентом
├── scripts/
│   ├── sync_from_mobile.py   # Dart → JSON, режим --check
│   └── export_openapi.py     # спецификация → openapi.json
├── tests/                 # pytest: контент, прогресс, health
├── openapi.json           # спецификация OpenAPI (ТЗ 3.2), генерируется
├── Dockerfile · docker-compose.yml
└── pyproject.toml         # ruff и pytest
```

## Спецификация OpenAPI

ТЗ 3.2 требует описания API в OpenAPI. Спецификация генерируется из кода:

```bash
python scripts/export_openapi.py
```

`openapi.json` обновляем в том же PR, где меняется API.
