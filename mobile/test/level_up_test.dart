import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finny_pet/app.dart';
import 'package:finny_pet/models/game_state.dart';
import 'package:finny_pet/models/pet.dart';
import 'package:finny_pet/screens/level_up/level_up_screen.dart';
import 'package:finny_pet/theme/kids_theme.dart';
import 'package:finny_pet/widgets/pet_avatar.dart';

import 'game_fixture.dart';
import 'real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await useRealFonts();
  });

  test('новый уровень даёт монетки, силы и событие для экрана', () async {
    final game = await readyGame();
    final pet = game.pet!;
    pet.xp = 95;
    pet.hunger = 30;
    pet.happiness = 40;
    pet.cleanliness = 50;
    final balanceBefore = game.balance;

    // Копилка даёт 5 опыта — ровно добираем до нового уровня.
    expect(game.deposit(10), isTrue);

    expect(pet.level, 2, reason: '100 опыта — это новый уровень');
    expect(pet.xp, 0, reason: 'на новом уровне опыт начинается заново');
    expect(pet.hunger, 100);
    expect(pet.happiness, 100);
    expect(pet.cleanliness, 100);
    // +25 за уровень и −10, которые ушли в копилку.
    expect(game.balance, balanceBefore + levelUpCoins - 10);
  });

  test('доход за день растёт вместе с уровнем', () async {
    final game = await readyGame();
    final incomeBefore = game.baseIncome;
    game.pet!.xp = 95;

    game.deposit(10);

    expect(game.baseIncome - incomeBefore, 10);
  });

  test('событие роста показывается один раз', () async {
    final game = await readyGame();
    game.pet!.xp = 95;
    game.deposit(10);

    final event = game.consumeLevelUp();
    expect(event, isNotNull);
    expect(event!.fromLevel, 1);
    expect(event.toLevel, 2);
    expect(event.coins, levelUpCoins);
    expect(event.levelsGained, 1);
    expect(event.stageFrom, Pet.stageForLevel(1));
    expect(event.stageTo, Pet.stageForLevel(2));
    expect(event.stageChanged, isTrue, reason: 'Малыш → Подросток');
    expect(event.incomeTo - event.incomeFrom, 10);

    expect(game.consumeLevelUp(), isNull,
        reason: 'второй раз показывать нечего');
  });

  test('без роста уровня события не появляется', () async {
    final game = await readyGame();

    expect(game.deposit(10), isTrue);

    expect(game.pet!.level, 1);
    expect(game.consumeLevelUp(), isNull);
  });

  testWidgets('экран нового уровня рисуется на 360dp и закрывается',
      (tester) async {
    await narrow(tester);
    final game = await readyGame();
    game.pet!.xp = 95;
    game.deposit(10);

    await tester.pumpWidget(GameStateScope(
      notifier: game,
      child: MaterialApp(
        theme: KidsTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showLevelUpIfNeeded(context),
                child: const Text('действие'),
              ),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('действие'));
    await tester.pumpAndSettle();

    expect(find.text('НОВЫЙ УРОВЕНЬ!'), findsOneWidget);
    expect(find.text('Уровень 2'), findsOneWidget);
    expect(find.text('+$levelUpCoins'), findsOneWidget);
    expect(find.text('Барсик вырос: ${Pet.stageForLevel(2)}'), findsOneWidget);
    expect(find.byType(PetAvatar), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'экран нового уровня переполнился');

    await tester.tap(find.text('Играем дальше! 🚀'));
    await tester.pumpAndSettle();
    expect(find.text('НОВЫЙ УРОВЕНЬ!'), findsNothing);
  });

  testWidgets('кормление на границе уровня само открывает экран роста',
      (tester) async {
    await narrow(tester);
    final game = await readyGame();
    // Молочко даёт 5 опыта — ровно добираем до нового уровня.
    game.pet!.xp = 95;

    await tester.pumpWidget(FinnyApp(gameState: game));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(PetAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PetAvatar));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Дать').first);
    await tester.pump();
    await tester.tap(find.text('Готово ✅'));
    await tester.pumpAndSettle();

    expect(find.text('НОВЫЙ УРОВЕНЬ!'), findsOneWidget,
        reason: 'после кормления должен открыться экран роста');

    await tester.tap(find.text('Играем дальше! 🚀'));
    await tester.pumpAndSettle();

    // Даём огоньку догореть, чтобы тест не оставил висящих анимаций.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}
