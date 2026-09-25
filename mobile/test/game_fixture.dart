import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finny_pet/models/game_state.dart';
import 'package:finny_pet/models/pet.dart';

/// Экран 360dp — минимальная ширина по ТЗ. Если вёрстка переполняется,
/// отчёт об ошибке роняет тест: именно этот класс ошибок ловил ребёнок.
Future<void> narrow(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 720);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Готовое состояние игры: онбординг пройден, питомец есть,
/// диалоги при старте не всплывают.
Future<GameState> readyGame({int age = 9, bool dark = false}) async {
  SharedPreferences.setMockInitialValues({});
  final game = GameState();
  await game.createProfile(
    nickname: 'Кирилл',
    age: age,
    type: PetType.cat,
    variant: PetVariant.v1,
    petName: 'Барсик',
  );
  // Иначе главный экран покажет диалог «Секрет игры» и тест зависнет.
  game.justFinishedOnboarding = false;
  game.isDark = dark;
  return game;
}
