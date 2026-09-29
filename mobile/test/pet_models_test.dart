import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finny_pet/app.dart';
import 'package:finny_pet/models/game_state.dart';
import 'package:finny_pet/models/pet.dart';
import 'package:finny_pet/screens/onboarding/nickname_screen.dart';
import 'package:finny_pet/screens/settings/settings_screen.dart';
import 'package:finny_pet/services/pet_assets.dart';
import 'package:finny_pet/theme/kids_theme.dart';

import 'game_fixture.dart';

void main() {
  tearDown(() => PetAssets.debugSetAvailable(const {}));

  group('эмоции и возраст модели', () {
    test('эмоция зависит от счастья: <33 грусть, >66 радость', () async {
      final pet = (await readyGame()).pet!;
      pet.happiness = 32;
      expect(pet.emotion, PetEmotion.sad);
      pet.happiness = 33;
      expect(pet.emotion, PetEmotion.normal);
      pet.happiness = 66;
      expect(pet.emotion, PetEmotion.normal);
      pet.happiness = 67;
      expect(pet.emotion, PetEmotion.happy);
    });

    test('папка модели: окраска и этап по уровню', () {
      expect(
        PetAssets.folderFor(PetType.cat, PetVariant.v1, PetStage.baby),
        'assets/pets/cat_ginger_small',
      );
      expect(
        PetAssets.folderFor(PetType.cat, PetVariant.v2, PetStage.teen),
        'assets/pets/cat_gray_medium',
      );
      expect(
        PetAssets.folderFor(PetType.cat, PetVariant.v3, PetStage.adult),
        'assets/pets/cat_black_large',
      );
    });

    test('постер: ролик по эмоции, нет модели — заглушка', () {
      expect(PetAssets.poster(PetType.cat, PetVariant.v1), isNull);

      PetAssets.debugSetAvailable({
        'assets/pets/cat_ginger_medium/pet.json',
        'assets/pets/cat_ginger_medium/idle_poster.png',
        'assets/pets/cat_ginger_medium/hungry_poster.png',
      });
      expect(
        PetAssets.modelFolder(PetType.cat, PetVariant.v1, teenLevel),
        'assets/pets/cat_ginger_medium',
      );
      expect(
        PetAssets.poster(PetType.cat, PetVariant.v1,
            level: teenLevel, emotion: PetEmotion.sad),
        'assets/pets/cat_ginger_medium/hungry_poster.png',
      );
      expect(
        PetAssets.poster(PetType.cat, PetVariant.v1,
            level: teenLevel, emotion: PetEmotion.happy),
        'assets/pets/cat_ginger_medium/idle_poster.png',
        reason: 'нет постера радости — показываем обычный',
      );
      expect(PetAssets.modelFolder(PetType.dog, PetVariant.v1, 1), isNull,
          reason: 'модели собачки пока нет — заглушка');
    });

    test('все 9 моделей котика на месте и объявлены в pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final variant in PetVariant.values) {
        for (final stage in PetStage.values) {
          final dir = PetAssets.folderFor(PetType.cat, variant, stage);
          expect(pubspec, contains('$dir/'), reason: 'нет в pubspec: $dir');
          for (final emotion in PetEmotion.values) {
            final clip = PetAssets.clipFor(emotion);
            for (final file in ['$clip.webp', '${clip}_poster.png']) {
              expect(File('$dir/$file').existsSync(), isTrue,
                  reason: 'нет файла $dir/$file');
            }
          }
          expect(File('$dir/pet.json').existsSync(), isTrue);
        }
      }
    });
  });

  group('перекраска в магазине', () {
    test('стоит монет, меняет окраску и сохраняется', () async {
      final game = await readyGame(); // рыжий котик
      game.balance = 100;

      expect(game.recolorPet(PetVariant.v1), isTrue);
      expect(game.balance, 100, reason: 'та же окраска — бесплатно');

      expect(game.recolorPet(PetVariant.v3), isTrue);
      expect(game.pet!.variant, PetVariant.v3);
      expect(game.balance, 100 - recolorPrice);
      await game.save();

      final restored = GameState();
      await restored.load();
      expect(restored.pet!.variant, PetVariant.v3);
    });

    test('без монет перекрасить нельзя', () async {
      final game = await readyGame();
      game.balance = recolorPrice - 1;
      expect(game.recolorPet(PetVariant.v2), isFalse);
      expect(game.pet!.variant, PetVariant.v1);
    });

    testWidgets('в магазине баланс — в верхней панели', (tester) async {
      await narrow(tester);
      final game = await readyGame();
      await tester.pumpWidget(FinnyApp(gameState: game));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Магазин'));
      await tester.pumpAndSettle();

      final inAppBar = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('🪙 ${game.balance}'),
      );
      expect(inAppBar, findsOneWidget);
      expect(find.text('🎨 Окраска питомца'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('огонёк и режим эксперта', () {
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

    test('опыт из режима эксперта поднимает уровень как в игре', () async {
      final game = await readyGame();
      final coins = game.balance;
      game.devAddXp(100);
      expect(game.pet!.level, 2);
      expect(game.balance, coins + levelUpCoins);
      expect(game.pendingLevelUp, isNotNull);
    });

    test('эксперт переключает возраст, эмоцию и дни', () async {
      final game = await readyGame();
      game.devSetLevel(adultLevel);
      expect(game.pet!.stage, Pet.stageForLevel(adultLevel));
      game.devSetHappiness(10);
      expect(game.pet!.emotion, PetEmotion.sad);
      game.devSkipDays(5);
      expect(game.day, 6);
      game.devSolveAllLessons();
      expect(game.nextLesson, isNull);
    });

    testWidgets('кнопка «Для экспертов» открывает режим эксперта',
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

      await tester.tap(find.text('Для экспертов'));
      await tester.pumpAndSettle();
      expect(find.text('🧪 Режим эксперта'), findsOneWidget);

      await tester.tap(find.text('+50 XP'));
      await tester.pumpAndSettle();
      expect(game.pet!.xp, 50);

      await tester.ensureVisible(find.text('Подросток (ур. $teenLevel)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Подросток (ур. $teenLevel)'));
      await tester.pumpAndSettle();
      expect(game.pet!.level, teenLevel);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('помощник выезжает при первом заходе в задания один раз',
      (tester) async {
    await narrow(tester);
    final game = await readyGame(age: 9);
    await tester.pumpWidget(FinnyApp(gameState: game));
    await tester.pumpAndSettle();
    expect(find.text('Покажи!'), findsNothing,
        reason: 'пока вкладку не открыли, помощника нет');

    await tester.tap(find.text('Задания'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Твой уровень — 3 класс'), findsOneWidget);

    await tester.tap(find.text('Покажи!'));
    await tester.pumpAndSettle();
    expect(find.text('Покажи!'), findsNothing);
    expect(game.questsGuideSeen, isTrue);
    expect(find.text('⭐ Твой уровень'), findsOneWidget);

    // Уходим и возвращаемся — второй раз не выезжает.
    await tester.tap(find.text('Питомец'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Задания'));
    await tester.pumpAndSettle();
    expect(find.text('Покажи!'), findsNothing);
    // Огонёк на разделе догорает сам.
    await tester.pump(const Duration(seconds: 1));
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
