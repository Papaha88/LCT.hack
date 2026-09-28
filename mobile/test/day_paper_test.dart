import 'package:flutter_test/flutter_test.dart';

import 'package:finny_pet/app.dart';
import 'package:finny_pet/models/game_state.dart';

import 'game_fixture.dart';
import 'real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await useRealFonts();
  });

  test('итоги дня считают реальную просадку, а не номинальную', () async {
    final game = await readyGame();
    final pet = game.pet!;
    pet.hunger = 10; // меньше суточной траты — потеряется только 10
    pet.happiness = 40;
    pet.cleanliness = 100;
    final balanceBefore = game.balance;

    final summary = game.nextDay();

    expect(summary.day, 2);
    expect(summary.income, incomeForLevel(1));
    expect(summary.hungerLost, 10, reason: 'сытости было 10, больше не уйдёт');
    expect(summary.happinessLost, 10);
    expect(summary.cleanlinessLost, 12);
    expect(summary.balance, balanceBefore + summary.income);
    expect(pet.hunger, 0);
  });

  test('в бумажке видно, сколько осталось до цели', () async {
    final game = await readyGame();
    game.savings = 40;

    final summary = game.nextDay();

    expect(summary.savings, 40);
    expect(summary.goalLeft, game.goalTarget - 40);
  });

  testWidgets('бумажка с итогами открывается на смене дня и закрывается',
      (tester) async {
    await narrow(tester);
    final game = await readyGame();
    await tester.pumpWidget(FinnyApp(gameState: game));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Следующий день 👉'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Следующий день 👉'));
    await tester.pumpAndSettle();

    expect(find.text('Итоги дня'), findsOneWidget);
    expect(find.text('☀️ День 2'), findsOneWidget);
    expect(find.text('+${incomeForLevel(1)}'), findsOneWidget);
    expect(find.text('В кошельке'), findsOneWidget);
    expect(find.text('В копилке'), findsOneWidget);
    expect(find.text('Осталось до цели'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'бумажка переполнилась');

    await tester.tap(find.text('Играем дальше!'));
    await tester.pumpAndSettle();
    expect(find.text('Итоги дня'), findsNothing);

    // Даём огоньку догореть, чтобы тест не оставил висящих анимаций.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}
