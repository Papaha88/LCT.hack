import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finny_pet/app.dart';
import 'package:finny_pet/data/goals_data.dart';
import 'package:finny_pet/data/lessons_data.dart';
import 'package:finny_pet/data/shop_data.dart';
import 'package:finny_pet/models/game_state.dart';
import 'package:finny_pet/screens/parent/parent_gate.dart';
import 'package:finny_pet/screens/quests/lesson_screen.dart';
import 'package:finny_pet/screens/quests/quests_screen.dart';
import 'package:finny_pet/theme/kids_theme.dart';

import 'game_fixture.dart';

Lesson _first(LessonTrack track, int grade) =>
    lessonsOf(track).firstWhere((l) => l.grade == grade);

int _wrongChoice(Lesson l) => (l.correct + 1) % l.options.length;

void main() {
  group('каталог заданий', () {
    test('две дороги, у каждого задания корректный ответ и уникальный id', () {
      expect(lessonsOf(LessonTrack.math), isNotEmpty);
      expect(lessonsOf(LessonTrack.finance), isNotEmpty);
      expect(gradesOf(LessonTrack.math), [1, 2, 3, 4]);
      expect(gradesOf(LessonTrack.finance), [1, 2, 3]);

      final ids = lessonsCatalog.map((l) => l.id).toSet();
      expect(ids.length, lessonsCatalog.length, reason: 'id повторяются');
      for (final l in lessonsCatalog) {
        expect(l.options.length, 4, reason: l.id);
        expect(l.correct, inInclusiveRange(0, l.options.length - 1),
            reason: l.id);
        expect(l.options.toSet().length, l.options.length,
            reason: '${l.id}: одинаковые варианты');
      }
    });

    test('рекомендованный класс считается от возраста', () {
      expect(recommendedGrade(7, LessonTrack.math), 1);
      expect(recommendedGrade(8, LessonTrack.math), 2);
      expect(recommendedGrade(9, LessonTrack.math), 3);
      expect(recommendedGrade(10, LessonTrack.math), 4);
      // На финансовой дороге три класса — 10+ получает последний.
      expect(recommendedGrade(10, LessonTrack.finance), 3);
      expect(recommendedGrade(null, LessonTrack.finance), 1);
    });
  });

  group('ответы на задания', () {
    test('верный ответ даёт монеты один раз', () async {
      final game = await readyGame();
      final lesson = _first(LessonTrack.finance, 1);
      final before = game.balance;

      final result = game.answerLesson(lesson.id, lesson.correct);
      expect(result.correct, isTrue);
      expect(result.reward, lesson.reward);
      expect(game.balance, before + lesson.reward);
      expect(game.lessonsSolved, contains(lesson.id));

      final again = game.answerLesson(lesson.id, lesson.correct);
      expect(again.alreadySolved, isTrue);
      expect(again.reward, 0);
      expect(game.balance, before + lesson.reward,
          reason: 'повтор не должен давать монеты снова');
    });

    test('ошибка ничего не отнимает и создаёт задачу «Повтори»', () async {
      final game = await readyGame();
      final lesson = _first(LessonTrack.math, 2);
      final before = game.balance;

      final result = game.answerLesson(lesson.id, _wrongChoice(lesson));
      expect(result.correct, isFalse);
      expect(game.balance, before);
      expect(game.lessonsRetry, contains(lesson.id));
      expect(game.lessonMistakes, 1);
      expect(game.nextLesson?.id, lesson.id,
          reason: 'Финни первым делом предлагает повторить');

      game.answerLesson(lesson.id, lesson.correct);
      expect(game.lessonsRetry, isNot(contains(lesson.id)));
      expect(game.balance, before + lesson.reward,
          reason: 'после исправления награда всё равно положена');
    });

    test('следующее задание — из класса по возрасту, но открыты все',
        () async {
      final game = await readyGame(age: 9);
      expect(game.nextLesson?.grade, 3);

      // Задание другого класса тоже можно решить.
      final easy = _first(LessonTrack.math, 1);
      expect(game.answerLesson(easy.id, easy.correct).reward, easy.reward);
    });

    test('прогресс заданий переживает перезапуск', () async {
      final game = await readyGame();
      final ok = _first(LessonTrack.finance, 2);
      final bad = _first(LessonTrack.math, 3);
      game.answerLesson(ok.id, ok.correct);
      game.answerLesson(bad.id, _wrongChoice(bad));
      await game.save();

      final restored = GameState();
      await restored.load();
      expect(restored.lessonsSolved, {ok.id});
      expect(restored.lessonsRetry, {bad.id});
      expect(restored.lessonMistakes, 1);
    });

    test('родитель сбрасывает задания, монеты остаются', () async {
      final game = await readyGame();
      final lesson = _first(LessonTrack.finance, 1);
      game.answerLesson(lesson.id, lesson.correct);
      final balance = game.balance;

      game.resetLessons();
      expect(game.lessonsSolved, isEmpty);
      expect(game.balance, balance);
    });
  });

  group('копилка и магазин', () {
    test('своя цель сохраняется, накопленное остаётся', () async {
      final game = await readyGame();
      game.deposit(20);

      expect(game.updateGoal('Наушники', 420, emoji: '🎧'), isTrue);
      expect(game.goalName, 'Наушники');
      expect(game.goalTarget, 420);
      expect(game.goalEmoji, '🎧');
      expect(game.savings, 20);

      expect(game.updateGoal('  ', 420), isFalse, reason: 'пустое имя');
      expect(game.updateGoal('Мало', minGoalTarget - 1), isFalse);
      expect(game.goalName, 'Наушники');

      await game.save();
      final restored = GameState();
      await restored.load();
      expect(restored.goalEmoji, '🎧');
      expect(restored.goalTarget, 420);
    });

    test('каталог разнообразный: все отделы, «надо» и «хочу»', () {
      for (final kind in ItemKind.values) {
        expect(shopCatalog.where((i) => i.kind == kind), isNotEmpty,
            reason: 'отдел «${kind.title}» пуст');
      }
      expect(shopCatalog.where((i) => i.mandatory).length,
          greaterThanOrEqualTo(5));
      expect(shopCatalog.where((i) => !i.mandatory).length,
          greaterThanOrEqualTo(5));
      final ids = shopCatalog.map((i) => i.id).toSet();
      expect(ids.length, shopCatalog.length);
    });

    test('скидка дня списывает меньше монет', () async {
      final game = await readyGame();
      game.balance = 500;
      final deal = dealOfDay(game.day);
      expect(game.priceOf(deal), lessThan(deal.price));

      game.buyItem(deal.id);
      expect(game.balance, 500 - dealPrice(deal));
    });
  });

  test('примеры для родителей решаемы и не детские', () {
    final random = math.Random(7);
    for (var i = 0; i < 200; i++) {
      final examples = GateExample.generate(random);
      expect(examples.length, 2);
      for (final e in examples) {
        expect(e.answer, greaterThan(20));
      }
    }
  });

  testWidgets('обе дороги рисуются на 360dp в светлой и тёмной теме',
      (tester) async {
    await narrow(tester);
    for (final dark in [false, true]) {
      final game = await readyGame(age: 10, dark: dark);
      final retry = _first(LessonTrack.math, 1);
      game.answerLesson(retry.id, _wrongChoice(retry));

      // Чистое дерево: иначе вкладка вспомнит дорогу и прокрутку
      // с прошлого прохода.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(FinnyApp(gameState: game));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Задания'));
      await tester.pumpAndSettle();

      expect(find.text('Финансы'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Математика').first);
      await tester.pumpAndSettle();
      expect(find.text('🔁 Повтори — и получишь монетки'), findsOneWidget);

      final road = find
          .descendant(
            of: find.byType(QuestsScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(find.text('⭐ Твой уровень'), 300,
          scrollable: road);
      await tester.scrollUntilVisible(find.text('Рубли и копейки'), 300,
          scrollable: road);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'дорога математики переполнилась');
    }
  });

  testWidgets('решаем задание: ошибка, подсказка, верный ответ, награда',
      (tester) async {
    await narrow(tester);
    final game = await readyGame();
    final lesson = _first(LessonTrack.finance, 1);
    final before = game.balance;

    await tester.pumpWidget(GameStateScope(
      notifier: game,
      child: MaterialApp(
        theme: KidsTheme.light(),
        home: LessonScreen(lesson: lesson),
      ),
    ));
    await tester.pumpAndSettle();

    Future<void> tapOption(int i) async {
      final option = find.text(lesson.options[i]);
      await tester.scrollUntilVisible(option, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(option);
    }

    await tapOption(_wrongChoice(lesson));
    await tester.pumpAndSettle();
    expect(find.text('Подсказка Финни:'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(game.balance, before);

    await tapOption(lesson.correct);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('🎉 Верно! +${lesson.reward} 🪙'), findsOneWidget);
    expect(find.textContaining('Разбор:'), findsOneWidget);
    expect(game.balance, before + lesson.reward);
    expect(tester.takeException(), isNull);
  });

  testWidgets('родительский режим не открывается без верных примеров',
      (tester) async {
    await narrow(tester);
    SharedPreferences.setMockInitialValues({});
    final game = await readyGame();
    await tester.pumpWidget(FinnyApp(gameState: game));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Родительский режим'));
    await tester.pumpAndSettle();
    expect(find.text('👨‍👩‍👧 Только для взрослых'), findsOneWidget);

    // Неверный ответ — режим не открывается, примеры меняются.
    await tester.enterText(find.byKey(const ValueKey('gate_answer_0')), '1');
    await tester.enterText(find.byKey(const ValueKey('gate_answer_1')), '1');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('Неверно. Вот новые примеры.'), findsOneWidget);

    // Решаем то, что на экране.
    for (var i = 0; i < 2; i++) {
      final row = find.ancestor(
        of: find.byKey(ValueKey('gate_answer_$i')),
        matching: find.byType(Row),
      );
      final label = tester
          .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
          .map((t) => t.data ?? '')
          .firstWhere((t) => t.endsWith('='));
      final parts = label.replaceAll('=', '').trim().split(' ');
      final a = int.parse(parts[0]);
      final b = int.parse(parts[2]);
      final answer = parts[1] == '×' ? a * b : a - b;
      await tester.enterText(
          find.byKey(ValueKey('gate_answer_$i')), '$answer');
    }
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.text('👨‍👩‍👧 Родительский режим'), findsOneWidget);
    expect(find.text('Возраст: 9 лет'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
