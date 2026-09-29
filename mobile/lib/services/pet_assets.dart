import 'package:flutter/services.dart';

import '../models/pet.dart';

/// Поиск моделей питомца в `assets/pets/`.
///
/// Одна модель = одна папка `<вид>_<окраска>_<этап>/`:
///
/// ```text
/// assets/pets/cat_ginger_small/
///   pet.json            описание роликов (кадры, точки склейки)
///   idle.webp           обычный      + idle_poster.png
///   happy.webp          весёлый      + happy_poster.png
///   hungry.webp         грустный     + hungry_poster.png
/// ```
///
/// - вид: `cat`, `dog`, `penguin`;
/// - окраска: `ginger` (v1), `gray` (v2), `black` (v3);
/// - этап: `small` (малыш), `medium` (подросток), `large` (взрослый).
///
/// Ролик (webp) играет только на главном экране (`PetView`), в остальных
/// местах — постер (png). Нет папки — виджет рисует заглушку, поэтому
/// модели других видов можно добавлять по одной.
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

  static const Map<PetVariant, String> colorNames = {
    PetVariant.v1: 'ginger',
    PetVariant.v2: 'gray',
    PetVariant.v3: 'black',
  };

  static const Map<PetStage, String> stageNames = {
    PetStage.baby: 'small',
    PetStage.teen: 'medium',
    PetStage.adult: 'large',
  };

  /// Ролик для эмоции: грусть — `hungry`, радость — `happy`, иначе `idle`.
  static String clipFor(PetEmotion emotion) {
    switch (emotion) {
      case PetEmotion.sad:
        return 'hungry';
      case PetEmotion.happy:
        return 'happy';
      case PetEmotion.normal:
        return 'idle';
    }
  }

  /// Папка модели (есть она или нет).
  static String folderFor(PetType type, PetVariant variant, PetStage stage) =>
      'assets/pets/${type.name}_${colorNames[variant]}_${stageNames[stage]}';

  /// Папка модели для этапа по [level] или null, если модели ещё нет.
  static String? modelFolder(PetType type, PetVariant variant, int level) {
    final dir = folderFor(type, variant, Pet.stageOf(level));
    return _available.contains('$dir/pet.json') ? dir : null;
  }

  /// Постер (статичная картинка) модели или null, если его нет.
  static String? poster(
    PetType type,
    PetVariant variant, {
    int level = 1,
    PetEmotion emotion = PetEmotion.normal,
  }) {
    final dir = folderFor(type, variant, Pet.stageOf(level));
    for (final clip in [clipFor(emotion), 'idle']) {
      final path = '$dir/${clip}_poster.png';
      if (_available.contains(path)) return path;
    }
    return null;
  }
}
