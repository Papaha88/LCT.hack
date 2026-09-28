import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finny_pet/app.dart';
import 'package:finny_pet/data/skins_data.dart';
import 'package:finny_pet/models/game_state.dart';
import 'package:finny_pet/models/pet.dart';
import 'package:finny_pet/screens/onboarding/nickname_screen.dart';
import 'package:finny_pet/screens/settings/settings_screen.dart';
import 'package:finny_pet/services/pet_assets.dart';
import 'package:finny_pet/theme/kids_theme.dart';

import 'game_fixture.dart';

void main() {
  tearDown(() => PetAssets.debugSetAvailable(const {}));

  group('скины', () {
    test('по три скина на каждый вид питомца, id уникальны', () {
      for (final type in PetType.values) {
        expect(skinsFor(type).length, 3, reason: type.name);
      }
      final ids = skinsCatalog.map((s) => s.id).toSet();
      expect(ids.length, skinsCatalog.length);
    });

    test('скин покупается один раз, надевается, снимается и сохраняется',
        () async {
      final game = await readyGame(); // кошечка
      game.balance = 500;
      final skin = skinsFor(PetType.cat).first;

      expect(game.buySkin(skin.id), isTrue);
      expect(game.balance, 500 - skin.price);
      expect(game.skin?.id, skin.id, reason: 'купленный скин сразу надет');
      expect(game.buySkin(skin.id), isFalse, reason: 'второй раз не продаём');

      game.equipSkin(null);
      expect(game.skin, isNull);
      game.equipSkin(skin.id);
      await game.save();

      final restored = GameState();
      await restored.load();
      expect(restored.ownedSkins, {skin.id});
      expect(restored.skin?.id, skin.id);
    });

    test('чужой вид и некупленный скин не надеваются', () async {
      final game = await readyGame();
      game.balance = 500;
      final dogSkin = skinsFor(PetType.dog).first;
      game.buySkin(dogSkin.id);
      expect(game.skin, isNull, reason: 'скин собачки на кошечке не виден');

      game.equipSkin(skinsFor(PetType.cat).last.id);
      expect(game.skinId, dogSkin.id, reason: 'некупленный не надевается');
    });
  });

  group('модели питомца (webp)', () {
    test('без файлов — заглушка, с файлами — ближайший подходящий', () {
      expect(
        PetAssets.resolve(
            type: PetType.cat, look: 'v1', anim: PetAnim.eat, level: 1),
        isNull,
      );

      PetAssets.debugSetAvailable({
        'assets/pets/cat/v1/idle.webp',
        'assets/pets/cat/v1/eat.webp',
        'assets/pets/cat/v1/happy_adult.webp',
      });
      expect(
        PetAssets.resolve(
            type: PetType.cat, look: 'v1', anim: PetAnim.eat, level: 1),
        'assets/pets/cat/v1/eat.webp',
      );
      expect(
        PetAssets.resolve(
            type: PetType.cat, look: 'v1', anim: PetAnim.happy, level: 3),
        'assets/pets/cat/v1/happy_adult.webp',
        reason: 'для взрослого есть своя анимация',
      );
      expect(
        PetAssets.resolve(
            type: PetType.cat, look: 'v1', anim: PetAnim.sad, level: 1),
        'assets/pets/cat/v1/idle.webp',
        reason: 'нет грусти — показываем покой',
      );
    });

    test('папки моделей объявлены для всех окрасок и скинов', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final type in PetType.values) {
        final looks = [
          ...PetVariant.values.map((v) => v.name),
          ...skinsFor(type).map((s) => s.id),
        ];
        for (final look in looks) {
          final dir = '${PetAssets.folder(type, look)}/';
          expect(pubspec, contains(dir), reason: 'нет в pubspec: $dir');
          expect(Directory(dir).existsSync(), isTrue, reason: 'нет папки $dir');
        }
      }
    });
  });

  group('огонёк и режим разработчика', () {
    test('действие зажигает огонёк один раз за день', () async {
      final game = await readyGame();
      expect(game.streak, 0);
      expect(game.streakLitToday, isFalse);

      game.buyItem('apple');
      expect(game.streak, 1);
      expect(game.streakLitToday, isTrue);
      final pulse = game.actionPulse;

      game.deposit(10);
      expect(game.streak, 1, reason: 'второе действие за день серию не растит');
      expect(game.actionPulse, pulse + 1, reason: 'но огонёк вспыхивает');
    });

    test('опыт из режима разработчика поднимает уровень как в игре',
        () async {
      final game = await readyGame();
      final coins = game.balance;
      game.devAddXp(100);
      expect(game.pet!.level, 2);
      expect(game.balance, coins + levelUpCoins);
      expect(game.pendingLevelUp, isNotNull);
    });

    testWidgets('режим разработчика открывается 7 нажатиями на версию',
        (tester) async {
      await narrow(tester);
      final game = await readyGame();
      await tester.pumpWidget(GameStateScope(
        notifier: game,
        child: MaterialApp(
          theme: KidsTheme.light(),
          home: const SettingsScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text(SettingsScreen.version));
      }
      await tester.pumpAndSettle();
      expect(find.text('🛠 Разработчик'), findsNothing);

      await tester.tap(find.text(SettingsScreen.version));
      await tester.pumpAndSettle();
      expect(find.text('🛠 Разработчик'), findsOneWidget);

      await tester.tap(find.text('+50 XP'));
      await tester.pumpAndSettle();
      expect(game.pet!.xp, 50);
    });
  });

  testWidgets('снятие из копилки — только после подтверждения', (tester) async {
    await narrow(tester);
    final game = await readyGame();
    game.deposit(50);
    await tester.pumpWidget(FinnyApp(gameState: game));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Банк'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Забрать 10 из копилки'));
    await tester.pumpAndSettle();
    expect(find.textContaining('В копилке станет 40'), findsOneWidget);
    await tester.tap(find.text('Оставить'));
    await tester.pumpAndSettle();
    expect(game.savings, 50);

    await tester.tap(find.text('Забрать 10 из копилки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Забрать'));
    await tester.pumpAndSettle();
    expect(game.savings, 40);
  });

  testWidgets('ник с матом не пропускается дальше', (tester) async {
    await narrow(tester);
    String? accepted;
    await tester.pumpWidget(MaterialApp(
      theme: KidsTheme.light(),
      home: Scaffold(
        body: NicknameScreen(
          initial: '',
          onBack: () {},
          onNext: (v) => accepted = v,
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), 'сука');
    await tester.pump();
    expect(find.textContaining('Такое имя не подойдёт'), findsOneWidget);
    await tester.tap(find.text('Отлично! 🎉'));
    expect(accepted, isNull);

    await tester.enterText(find.byType(TextField), 'Глеб');
    await tester.pump();
    expect(find.textContaining('Такое имя не подойдёт'), findsNothing);
    await tester.tap(find.text('Отлично! 🎉'));
    expect(accepted, 'Глеб');
  });
}
