# Финни — мобильное приложение

Flutter-приложение для Android: вся игра «Финни». Работает офлайн,
состояние хранится на устройстве (`shared_preferences`), к серверу
не обращается. О продукте — в [корневом README](../README.md), об
устройстве кода — в [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md),
о механиках — в [docs/GAME_DESIGN.md](../docs/GAME_DESIGN.md).

## Запуск

Нужно: Flutter SDK (stable, 3.44+), Android SDK, эмулятор или телефон.

```bash
cd mobile
flutter pub get
flutter run
```

## Сборка APK

```bash
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
flutter build apk --debug     # то же, что собирает CI
```

Готовые сборки выкладываются в
[GitHub Releases](https://github.com/SilMax-Lang/LCT.hack/releases).

## Тесты

```bash
flutter analyze
flutter test
```

То же самое гоняет CI (`.github/workflows/mobile-ci.yml`) на каждый push
и pull request, если менялись файлы в `mobile/`.

| Файл | Что проверяет |
|---|---|
| `test/pet_test.dart` | окраски, возраст 7–10+, чтение старых сейвов |
| `test/screens_test.dart` | главный экран, вкладки на 360dp, тёмная тема, рюкзак, «огонёк» на действие |
| `test/roads_test.dart` | каталог заданий, рекомендация по возрасту, награда один раз, ошибка → «Повтори», своя цель, скидка дня, дороги на 360dp, вход в родительский режим |
| `test/skins_streak_test.dart` | скины, поиск webp-моделей, папки в `pubspec.yaml`, серия дней, режим разработчика, подтверждение снятия, фильтр на экране ника |
| `test/name_filter_test.dart` | нормальные имена проходят, мат и 18+ (и обходы) — нет |
| `test/level_up_test.dart` | награда за уровень, экран нового уровня |
| `test/day_paper_test.dart` | итоги дня считают реальную просадку статов |
| `test/glyphs_test.dart` | в текстах нет символов, которых нет в шрифте Android |
| `test/smoke_test.dart` | тестовое окружение поднимается |
| `test/game_fixture.dart`, `test/real_fonts.dart`, `test/flutter_test_config.dart` | помощники: готовое состояние игры, настоящий шрифт, отключение бесконечных анимаций |

Зачем `real_fonts.dart`: `flutter test` по умолчанию рисует текст
служебным шрифтом, где каждый символ — квадрат шириной в кегль. Он вдвое
шире настоящего, и проверки «влезает ли текст на 360dp» ложно падают.

Зачем `glyphs_test.dart`: в Roboto нет символов вроде `→ ✓ ▶` — на
устройстве вместо них пустой квадрат. Поэтому в текстах только слова и
эмодзи, а стрелки и галочки — Material-иконки.

## Модели питомца

Анимированные WebP кладутся в `assets/pets/<вид>/<образ>/` — раскладка
и имена файлов описаны в [assets/pets/README.md](assets/pets/README.md).
Пока файла нет, рисуется заглушка, код менять не нужно.
