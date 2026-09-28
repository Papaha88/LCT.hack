import 'package:flutter/services.dart';

import '../models/pet.dart';

/// Анимация модели питомца. Имя = имя файла: `idle.webp`, `happy.webp`…
enum PetAnim {
  /// Спокойно дышит — показывается большую часть времени.
  idle,

  /// Радуется: после игрушки, похвалы, верного ответа.
  happy,

  /// Ест: после еды из рюкзачка.
  eat,

  /// Грустит: когда сытость, счастье или чистота совсем низко.
  sad,

  /// Спит: при переходе к новому дню.
  sleep,
}

/// Поиск файлов анимированных моделей питомца.
///
/// Модели — анимированные WebP (Flutter проигрывает их сам через
/// `Image.asset`). Раскладка:
///
/// ```text
/// assets/pets/<вид>/<образ>/<анимация>[_<этап>].webp
///   вид     — cat | dog | penguin
///   образ   — v1 | v2 | v3 (окраска) или id скина (cat_astronaut…)
///   анимация — idle | happy | eat | sad | sleep
///   этап    — baby | teen | adult (необязательно)
/// ```
///
/// Если нужного файла нет, берём ближайший: без этапа → idle. Если нет
/// ничего — виджет рисует заглушку (эмодзи). Поэтому модели можно
/// добавлять по одной, ничего не ломая.
class PetAssets {
  const PetAssets._();

  static Set<String> _available = const {};

  /// Загрузить список файлов из AssetManifest. Вызывается один раз
  /// на старте; ошибка не страшна — останутся заглушки.
  static Future<void> init([AssetBundle? bundle]) async {
    try {
      final manifest =
          await AssetManifest.loadFromAssetBundle(bundle ?? rootBundle);
      _available = manifest
          .listAssets()
          .where((path) => path.startsWith('assets/pets/'))
          .toSet();
    } catch (_) {
      _available = const {};
    }
  }

  /// Для тестов: подставить список «существующих» файлов.
  static void debugSetAvailable(Set<String> paths) => _available = paths;

  static String stageKey(int level) {
    if (level <= 1) return 'baby';
    if (level == 2) return 'teen';
    return 'adult';
  }

  static String folder(PetType type, String look) =>
      'assets/pets/${type.name}/$look';

  /// Путь к файлу модели или null, если моделей для образа ещё нет.
  static String? resolve({
    required PetType type,
    required String look,
    required PetAnim anim,
    required int level,
  }) {
    final dir = folder(type, look);
    final stage = stageKey(level);
    final candidates = [
      '$dir/${anim.name}_$stage.webp',
      '$dir/${anim.name}.webp',
      '$dir/idle_$stage.webp',
      '$dir/idle.webp',
    ];
    for (final path in candidates) {
      if (_available.contains(path)) return path;
    }
    return null;
  }
}
