import 'dart:io';

import 'package:flutter/services.dart';

/// Пути, где искали шрифты SDK. Заполняется при [useRealFonts],
/// чтобы на CI было видно, почему шрифт не нашёлся.
final List<String> fontSearchPaths = <String>[];

/// В flutter_test текст рисуется служебным шрифтом, у которого каждый символ —
/// квадрат шириной в кегль. Это вдвое шире настоящего, поэтому любая проверка
/// «влезает ли текст» на нём врёт: переполнения находятся там, где их нет.
///
/// Подключаем настоящий Roboto из кеша Flutter SDK — тогда ширины такие же,
/// как на устройстве, и тесты проверяют вёрстку честно.
///
/// Возвращает false, если шрифты не нашлись: тогда проверки ширины текста
/// надо пропускать, а не «падать» на замерах служебного шрифта.
Future<bool> useRealFonts() async {
  fontSearchPaths.clear();
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

/// Ищем кеш шрифтов SDK: по FLUTTER_ROOT, по PATH и вверх от запущенного
/// движка. Раскладка кеша от этого не зависит — нужен только корень SDK.
Directory? _materialFontsDir() {
  final candidates = <String>[];

  void add(String? path) {
    if (path == null || path.isEmpty || candidates.contains(path)) return;
    candidates.add(path);
  }

  add(Platform.environment['FLUTTER_ROOT']);

  // .../flutter/bin/flutter_test указывает на корень SDK двумя ступенями выше.
  final pathVar =
      Platform.environment['PATH'] ?? Platform.environment['Path'] ?? '';
  for (final entry in pathVar.split(Platform.isWindows ? ';' : ':')) {
    if (entry.isEmpty) continue;
    final normalized = entry.replaceAll('\\', '/');
    if (normalized.endsWith('/bin')) {
      add(Directory(entry).parent.path);
    }
  }

  // .../flutter/bin/cache/artifacts/engine/<os>-<arch>/flutter_tester
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    add(dir.path);
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  for (final candidate in candidates) {
    final fonts = Directory('$candidate/bin/cache/artifacts/material_fonts');
    fontSearchPaths.add(fonts.path);
    if (fonts.existsSync()) return fonts;
  }
  return null;
}
