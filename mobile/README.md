# Mobile (Flutter / Dart, Android)

## Установка

1. Установить Flutter SDK: https://docs.flutter.dev/get-started/install
2. Проверить окружение:

```bash
flutter doctor
```

Исправьте всё, что `flutter doctor` пометит красным (обычно Android SDK / лицензии).

## Важно: доводим скелет до полноценного Flutter-проекта

Этот `mobile/` содержит только минимальный код (`lib/main.dart`, `pubspec.yaml`). Папки `android/`, `ios/`, платформенные файлы и `.gitignore` для них Flutter генерирует сам. Первым шагом после клонирования выполните:

```bash
cd mobile
flutter create --project-name lct_hackathon_mobile --org com.lcthackathon .
flutter pub get
```

Это безопасно — команда не перезапишет уже существующие `lib/main.dart` и `pubspec.yaml`, а только добавит недостающие платформенные файлы.

## Запуск

```bash
flutter run
```

## Тесты и анализ

```bash
flutter analyze
flutter test
```

Это же проверяется в CI (`.github/workflows/mobile-ci.yml`).

## Структура

```
mobile/
├── lib/
│   └── main.dart          # точка входа
├── pubspec.yaml            # зависимости
└── analysis_options.yaml   # линт-правила (flutter_lints)
```

После `flutter create` появятся ещё `android/`, `ios/`, `test/` и другие — это нормально.
