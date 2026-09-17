# LCT Hackathon — монорепозиторий команды

Один репозиторий, три направления разработки: бэкенд, фронтенд, мобильное приложение (Android/Flutter).

## Структура репозитория

```
.
├── backend/    # Python FastAPI — бэкенд-разработчик
├── frontend/   # React + Vite — фронтенд-разработчик
├── mobile/     # Flutter/Dart — Android-разработчик
└── .github/workflows/  # CI/CD-пайплайны (отдельный на каждое направление)
```

Каждая папка — независимый проект со своим README, зависимостями и CI. Пайплайн для конкретной папки запускается только тогда, когда меняются файлы внутри неё (path filters в GitHub Actions) — так три разработчика не блокируют друг друга.

## Ветки

Стратегия: `main` + `develop` + `feature/*`.

- **`main`** — только рабочий, задеплоенный код. Прямые пуши запрещены, попадает сюда только через PR из `develop`.
- **`develop`** — основная ветка интеграции. Все feature-ветки мёржатся сюда.
- **`feature/<область>-<задача>`** — рабочие ветки для конкретной задачи. Префикс области помогает сразу понять, кто и над чем работает:
  - `feature/backend-auth`
  - `feature/frontend-login-page`
  - `feature/android-onboarding`

### Как работать с ветками

```bash
git checkout develop
git pull
git checkout -b feature/backend-auth
# ... работаете, коммитите ...
git push -u origin feature/backend-auth
# открываете Pull Request в develop на GitHub
```

Правила:
1. Не пушьте напрямую в `main` и `develop` — только через Pull Request.
2. Перед PR обновите ветку из `develop` (`git merge develop` или `git rebase develop`), чтобы не ловить конфликты в последний момент.
3. Называйте PR понятно, указывайте что сделано — это ускорит ревью на хакатоне.
4. Перед финальной сдачей `develop` мёржится в `main` через отдельный PR — это и есть релиз.

## CI/CD

В `.github/workflows/` три независимых пайплайна:

| Workflow | Триггер (пути) | Что делает |
|---|---|---|
| `backend-ci.yml` | `backend/**` | линт (ruff), тесты (pytest), сборка Docker-образа |
| `frontend-ci.yml` | `frontend/**` | линт (eslint), сборка (vite build) |
| `mobile-ci.yml` | `mobile/**` | анализ кода (`dart analyze`), сборка debug APK |

Все три запускаются на `push` и `pull_request` в `main`/`develop`, но только если изменились файлы в соответствующей папке — экономит минуты CI и не шумит уведомлениями другим разработчикам.

## Быстрый старт для каждого разработчика

- Бэкенд: [backend/README.md](backend/README.md)
- Фронтенд (включая бесплатный гайд для новичка): [frontend/README.md](frontend/README.md)
- Android/Flutter: [mobile/README.md](mobile/README.md)

## Первые шаги для DevOps (после клонирования на GitHub)

1. Создать пустой репозиторий на GitHub (без README/gitignore — они уже есть тут).
2. `git remote add origin <URL>`
3. `git push -u origin main`
4. `git push -u origin develop`
5. В настройках GitHub repo → Settings → Branches добавить branch protection на `main` (и по желанию `develop`): запретить прямой пуш, требовать PR + прохождение CI-проверки.
6. Пригласить трёх разработчиков как collaborators, при желании настроить CODEOWNERS (файл `.github/CODEOWNERS` уже в репозитории — впишите их GitHub-логины).
