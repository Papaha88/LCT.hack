import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Символы, которых нет в шрифте Roboto. На устройстве вместо них рисуется
/// пустой квадрат — именно так выглядели «символы» на слайде окрасок.
/// Список получен разбором cmap шрифта из кеша SDK.
///
/// Эмодзи сюда не входят: их рисует системный эмодзи-шрифт, а не Roboto.
/// А вот стрелки и галочки из типографских наборов рисует именно Roboto,
/// поэтому в тексте их быть не должно — только Material-иконки или слова.
const List<String> notInRoboto = ['→', '←', '✓', '⬜', '➜', '▶'];

/// Строковые литералы в строке кода: и одинарные, и двойные кавычки.
/// Комментарии так не ловятся — в них символы упоминать можно.
final RegExp _literals = RegExp(
  "'([^'\\n]*)'" // в одинарных кавычках
  '|'
  '"([^"\\n]*)"', // в двойных кавычках
);

void main() {
  test('в текстах приложения нет символов, которых нет в Roboto', () {
    final offenders = <String>[];

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final match in _literals.allMatches(lines[i])) {
          final text = match.group(1) ?? match.group(2) ?? '';
          for (final symbol in notInRoboto) {
            if (text.contains(symbol)) {
              offenders.add('${file.path}:${i + 1} — символ «$symbol»');
            }
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'такие символы на устройстве будут пустым квадратом.\n'
          'Замените на Material-иконку или слово:\n${offenders.join('\n')}',
    );
  });
}
