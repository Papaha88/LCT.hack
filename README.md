# Финни — финансовая грамотность для детей через питомца

Команда **LitEnergy**.

«Финни» — Android-игра для детей 7–10+ лет. Ребёнок заводит питомца,
получает монетки за каждый игровой день и за решённые задания, покупает
питомцу еду и игрушки, откладывает в копилку на мечту. Так на практике
осваиваются базовые понятия: «надо» и «хочу», бюджет, накопления, цель.
Правила объясняет помощник Финни. Игра работает полностью офлайн,
персональных данных не собирает, к сети не обращается.

## Скачать APK

Готовая сборка — на странице
**[Releases](https://github.com/SilMax-Lang/LCT.hack/releases)**:
скачайте `.apk` из последнего релиза и установите на Android 8.0+
(понадобится разрешение «Установка из неизвестных источников»).

## Возможности

- **Питомец**: 3 вида × 3 окраски = 9 комбинаций, 3 этапа взросления
  (Малыш → Подросток → Взрослый), сытость / счастье / чистота,
  настроение и эмоции.
- **Игровые дни**: доход растёт с уровнем питомца, статы убывают,
  в конце дня — «бумажка» с итогами (доход, траты питомца, кошелёк, копилка).
- **Задания — две дороги**: «Математика» (1–4 класс) и «Финансы»
  (3 раздела), всего 35 заданий. Класс рекомендуется по возрасту, ошибка
  ничего не отнимает, а превращается во временную задачу «Повтори».
- **Магазин**: 26 товаров в 6 отделах с ярлыками «Надо» / «Хочу»,
  скидка дня, образы (скины) питомца.
- **Копилка**: готовая или своя цель; снятие — только после
  подтверждения с новой суммой и новым сроком до цели.
- **Мотивация**: ежедневный бонус, «огонёк» — серия дней с действиями,
  праздничный экран нового уровня.
- **Родительский режим** за проверкой «ты взрослый?»: прогресс,
  смена возраста, сброс.
- **Безопасность**: фильтр мата и 18+ в нике и кличке питомца,
  приложение не запрашивает никаких разрешений Android.
- Светлая и тёмная тема, текст от 16sp, кнопки от 48dp, портрет от 360dp.

## Стек

| Часть | Технологии |
|---|---|
| Приложение (`mobile/`) | Flutter / Dart, Material 3, `shared_preferences`; анимации — `AnimationController` + `CustomPainter` |
| Сервер (`backend/`, необязательный) | Python 3.12, FastAPI, SQLAlchemy, SQLite / PostgreSQL 16, Docker Compose |
| CI | GitHub Actions: `flutter analyze` → `flutter test` → debug APK; `ruff` → `pytest` → Docker-образ |

## Быстрый старт (локально)

Нужно: [Flutter SDK](https://docs.flutter.dev/get-started/install)
(канал stable, 3.44+) и Android-эмулятор или телефон с включённой
отладкой по USB. Проверить окружение — `flutter doctor`.

```bash
git clone https://github.com/SilMax-Lang/LCT.hack.git
cd LCT.hack/mobile
flutter pub get
flutter run
```

Собрать APK:

```bash
cd mobile
flutter build apk --release
# готовый файл: mobile/build/app/outputs/flutter-apk/app-release.apk
```

Сервер для игры **не нужен**: весь контент зашит в приложение, прогресс
хранится на устройстве. Необязательный сервер (справочники и резервная
копия прогресса, Swagger UI на `/docs`) запускается отдельно —
см. [backend/README.md](backend/README.md).

## Тесты

```bash
cd mobile
flutter analyze
flutter test
```

Сервер: `pytest -v` и `ruff check .` в папке `backend/` (подробнее —
в [backend/README.md](backend/README.md)). Оба набора автоматически
прогоняются в CI на каждый push и pull request
([.github/workflows](.github/workflows)).

## Структура репозитория

```text
.
├── mobile/        Flutter-приложение (вся игра)
│   ├── lib/       код: models/ (логика), data/ (контент), screens/, widgets/, services/
│   ├── test/      тесты логики и экранов
│   └── assets/    картинки и модели питомца
├── backend/       необязательный сервер FastAPI (справочники, резервная копия)
├── docs/          документация
├── design/        иконка приложения для RuStore
└── .github/       CI и CODEOWNERS
```

## Документация

| Документ | О чём |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | архитектура, стек, данные, развёртывание, тесты и CI |
| [docs/SPEC.md](docs/SPEC.md) | требования ТЗ и где они выполнены |
| [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) | пояснительная записка: игровой цикл, экономика, обучение, задания, питомец |
| [mobile/README.md](mobile/README.md) | сборка и тесты приложения |
| [backend/README.md](backend/README.md) | запуск сервера, Docker Compose, API |
| [backend/openapi.json](backend/openapi.json) | спецификация API (OpenAPI) |

## Команда LitEnergy

- Максим Силин ([@SilMax-Lang](https://github.com/SilMax-Lang)) — DevOps, Designer
- Даниил Жердецких [@dancheck557](https://github.com/dancheck557) — Mobile
- Мальцев Арсений — [@PaPaHa88](https://github.com/PaPaHa88) Product manager
- Максим Древаль — Designer
- Ксения Садилкина — Analyst
