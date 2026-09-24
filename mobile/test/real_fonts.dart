import 'dart:io';

import 'package:flutter/services.dart';

/// В flutter_test текст рисуется служебным шрифтом, у которого каждый символ —
/// квадрат шириной в кегль. Это вдвое шире настоящего, поэтому любая проверка
/// «влезает ли текст» на нём врёт: переполнения находятся там, где их нет.
///
/// Подключаем настоящий Roboto из кеша Flutter SDK — тогда ширины такие же,
/// как на устройстве, и тесты проверяют вёрстку честно.
///
/// Возвращает false, если шрифты не нашлись: тогда тесты экрана остаются
/// консервативными (служебный шрифт шире), и это тоже безопасно.
Future<bool> useRealFonts() async {
  final dir = _materialFontsDir();
  if (dir == null) return false;

  final loader = FontLoader('Roboto');
  for (final name in const [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]) {
    final file = File('${dir.path}/$name');
    if (!file.existsSync()) return false;
    loader.addFont(
      file.readAsBytes().then((bytes) => ByteData.view(bytes.buffer)),
    );
  }
  await loader.load();
  return true;
}

/// Ищем кеш шрифтов SDK — по FLUTTER_ROOT либо вверх от запущенного движка.
Directory? _materialFontsDir() {
  final candidates = <String>[];
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null && root.isNotEmpty) candidates.add(root);

  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 6; i++) {
    candidates.add(dir.path);
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  for (final candidate in candidates) {
    final fonts = Directory('$candidate/bin/cache/artifacts/material_fonts');
    if (fonts.existsSync()) return fonts;
  }
  return null;
}
