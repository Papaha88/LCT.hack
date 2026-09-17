# С чего начать (для Кирилла и Дани)

## Общее для всех — сделать один раз

1. Принять приглашение в репозиторий (придёт на почту/уведомлением на GitHub).
2. Установить Git, если ещё нет: https://git-scm.com/downloads
3. Склонировать репозиторий:
   ```bash
   git clone https://github.com/SilMax-Lang/LCT.hack.git
   cd LCT.hack
   ```
4. Настроить своё имя для коммитов (один раз на компьютере):
   ```bash
   git config --global user.name "Имя Фамилия"
   git config --global user.email "твоя-почта@example.com"
   ```
5. Прочитать корневой [README.md](README.md) — там про ветки и структуру.
6. Взять свою первую задачу в ветку:
   ```bash
   git checkout develop
   git pull
   git checkout -b feature/backend-название-задачи   # для Кирилла
   git checkout -b feature/android-название-задачи   # для Дани
   ```
7. Когда задача готова:
   ```bash
   git add .
   git commit -m "что сделал"
   git push -u origin feature/backend-название-задачи
   ```
   Дальше на GitHub открыть Pull Request **в `develop`** (не в `main`!). Заголовок PR подставится сам из шаблона — заполнить что сделано.

---

## Кириллу (Backend)

Подробности: [backend/README.md](backend/README.md)

1. Установить Python 3.12 (или ту версию, что стоит у вас, ≥3.10): https://www.python.org/downloads/
2. Настроить и запустить проект:
   ```bash
   cd backend
   python3 -m venv .venv
   source .venv/bin/activate       # на Windows: .venv\Scripts\activate
   pip install -r requirements.txt -r requirements-dev.txt
   cp .env.example .env
   uvicorn app.main:app --reload
   ```
3. Открыть http://127.0.0.1:8000/docs — это твой API "живьём", там видно все эндпоинты.
4. Если нужна база данных — не ставить Postgres вручную, а поднять всё разом:
   ```bash
   docker compose up --build
   ```
   (нужен установленный Docker Desktop: https://www.docker.com/products/docker-desktop/)
5. Первая задача: посмотри пример `GET /pet/{user_id}` в `app/main.py` — по этому шаблону добавляй новые эндпоинты (сначала форма ответа + фейковые данные, потом настоящая логика с базой).
6. Перед каждым PR прогоняй:
   ```bash
   pytest -v
   ruff check .
   ```
   Если тесты падают — CI на GitHub тоже упадёт, PR не примут.
7. **Важно для Дани**: как только добавляешь/меняешь эндпоинт — напиши в чат команды, какой путь и что он возвращает (или просто скинь скриншот `/docs`), чтобы мобильный сразу знал новую форму данных.

---

## Дане (Mobile / Android, Flutter)

Подробности: [mobile/README.md](mobile/README.md)

1. Установить Flutter SDK: https://docs.flutter.dev/get-started/install
2. Проверить, что всё встало нормально:
   ```bash
   flutter doctor
   ```
   Всё что помечено красным — исправить по подсказкам (обычно это Android Studio / Android SDK / лицензии).
3. Первым делом достроить проект до полноценного Flutter-приложения (в репозитории пока только минимальный скелет):
   ```bash
   cd mobile
   flutter create --project-name lct_hackathon_mobile --org com.lcthackathon .
   flutter pub get
   ```
   Это безопасно — существующие `lib/main.dart` и `pubspec.yaml` не перезапишутся, только добавятся недостающие папки (`android/`, `ios/` и т.д.).
4. Запустить на эмуляторе или подключённом телефоне:
   ```bash
   flutter run
   ```
5. Чтобы обращаться к API Кирилла:
   - Пока Кирилл работает локально — используй адрес `http://10.0.2.2:8000` (это способ Android-эмулятора достучаться до `localhost` компьютера, где крутится backend), либо попроси у Кирилла адрес, если backend уже задеплоен на сервер.
   - Смотри форму данных на http://127.0.0.1:8000/docs (или ссылку, которую скинет Кирилл) — это и есть контракт, под него пиши запросы (`http` пакет из `pubspec.yaml` уже добавлен).
6. Перед каждым PR прогоняй:
   ```bash
   flutter analyze
   flutter test
   ```
7. Иконку/картинки для приложения бери из папки `design/` (см. [design/README.md](design/README.md)) — не рисуй с нуля, если Аналитик уже что-то подготовил(а).

---

## Если что-то не работает

- Читай текст ошибки в терминале — обычно там прямо написано, чего не хватает.
- Проверь, что ты в правильной папке (`backend/` или `mobile/`), когда запускаешь команды.
- Спроси в чат команды — не трать час на самостоятельную борьбу с окружением, на хакатоне дорого время.
