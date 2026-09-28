import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finny_pet/app.dart';
import 'package:finny_pet/data/shop_data.dart';
import 'package:finny_pet/models/game_state.dart';
import 'package:finny_pet/models/pet.dart';
import 'package:finny_pet/screens/onboarding/age_screen.dart';
import 'package:finny_pet/screens/onboarding/pet_color_screen.dart';
import 'package:finny_pet/theme/kids_theme.dart';
import 'package:finny_pet/widgets/action_spark.dart';
import 'package:finny_pet/widgets/pet_avatar.dart';

import 'real_fonts.dart';

/// Экран 360dp — минимальная ширина по ТЗ. Если вёрстка переполняется,
/// отчёт об ошибке роняет тест: именно этот класс ошибок ловил ребёнок.
Future<void> _narrow(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 720);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Готовое состояние: онбординг пройден, питомец есть.
Future<GameState> _readyGame({int age = 9}) async {
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
  return game;
}

/// Огонёк — это CustomPaint с приватным painter'ом.
Finder _spark() => find.byWidgetPredicate(
      (w) => w is CustomPaint && '${w.painter.runtimeType}' == '_SparkPainter',
    );

/// Нашёлся ли настоящий шрифт: от этого зависит, можно ли верить замерам ширины.
bool _realFonts = false;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Без настоящего шрифта тестовый движок рисует каждый символ квадратом
  // в кегль, и проверки ширины текста показывают переполнения там, где их нет.
  setUpAll(() async {
    _realFonts = await useRealFonts();
    // ignore: avoid_print
    print('REAL_FONTS_LOADED=$_realFonts\nискали в:\n${fontSearchPaths.join('\n')}');
  });

  test('возраст и питомец переживают перезапуск приложения', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameState();
    await game.createProfile(
      nickname: 'Кирилл',
      age: 9,
      type: PetType.cat,
      variant: PetVariant.v1,
      petName: 'Барсик',
    );

    final restored = GameState();
    await restored.load();

    expect(restored.nickname, 'Кирилл');
    expect(restored.age, 9);
    expect(restored.pet?.name, 'Барсик');
  });

  test('возраст вне 7–10+ лет не принимается', () async {
    final game = await _readyGame(age: 9);

    game.updateAge(3);
    expect(game.age, 9, reason: 'слишком маленький возраст не должен сохраняться');

    game.updateAge(11);
    expect(game.age, 9, reason: 'старше 10 — это вариант «10+», а не 11');

    game.updateAge(10);
    expect(game.age, 10);
  });

  testWidgets('главный экран показывает возраст игрока', (tester) async {
    await _narrow(tester);
    final game = await _readyGame(age: 9);
    await tester.pumpWidget(FinnyApp(gameState: game));
    await tester.pumpAndSettle();

    expect(find.text('Привет, Кирилл!'), findsOneWidget);
    expect(find.text('👦 9 лет'), findsOneWidget);
    expect(find.text('Барсик'), findsOneWidget);
  });

  testWidgets('все вкладки на 360dp рисуются без переполнений', (tester) async {
    await _narrow(tester);
    final game = await _readyGame();
    await tester.pumpWidget(FinnyApp(gameState: game));
    await tester.pumpAndSettle();

    for (final tab in ['План', 'Задания', 'Магазин', 'Банк', 'Питомец']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'вкладка «$tab» переполнилась на 360dp',
      );
    }
  });

  testWidgets('подписи нижней навигации влезают в свои ячейки', (tester) async {
    await _narrow(tester);
    final game = await _readyGame();
    await tester.pumpWidget(FinnyApp(gameState: game));
    await tester.pumpAndSettle();

    // Размер по ТЗ проверяем всегда — он от шрифта не зависит.
    for (final label in ['Питомец', 'План', 'Задания', 'Магазин', 'Банк']) {
      final finder = find.text(label);
      expect(finder, findsOneWidget);
      final style = tester.widget<Text>(finder).style ??
          DefaultTextStyle.of(tester.element(finder)).style;
      expect(
        style.fontSize ?? KidsTheme.minFontSize,
        greaterThanOrEqualTo(KidsTheme.minFontSize),
        reason: 'подпись «$label» мельче 16sp',
      );
    }

    if (!_realFonts) {
      // Служебный шрифт вдвое шире Roboto — мерить им ширину бессмысленно.
      markTestSkipped(
        'нет Roboto из кеша SDK: ширину подписей не проверить',
      );
      return;
    }

    const slot = 360 / 5;
    for (final label in ['Питомец', 'План', 'Задания', 'Магазин', 'Банк']) {
      final finder = find.text(label);
      final style = tester.widget<Text>(finder).style ??
          DefaultTextStyle.of(tester.element(finder)).style;
      final natural = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      expect(
        natural.width,
        lessThanOrEqualTo(slot),
        reason: 'подпись «$label» шире ячейки: '
            '${natural.width.toStringAsFixed(1)} из $slot',
      );
      expect(
        tester.getSize(finder).width,
        greaterThanOrEqualTo(natural.width - 2),
        reason: 'подпись «$label» обрезается многоточием',
      );
    }
  });

  testWidgets('в тёмной теме плашки не остаются белыми', (tester) async {
    await _narrow(tester);
    final game = await _readyGame();
    game.isDark = true;
    await tester.pumpWidget(FinnyApp(gameState: game));
    await tester.pumpAndSettle();

    final pillText = find.text('🪙 60').first;
    final container = tester.widget<Container>(
      find
          .ancestor(
            of: pillText,
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is BoxDecoration,
            ),
          )
          .first,
    );

    final background = (container.decoration! as BoxDecoration).color;
    final foreground = tester.widget<Text>(pillText).style?.color;

    expect(background, isNot(Colors.white),
        reason: 'в тёмной теме плашка не должна быть белой');
    expect(foreground, isNot(background),
        reason: 'текст не должен сливаться с плашкой');
  });

  testWidgets('огонёк вспыхивает на действие и гаснет сам', (tester) async {
    Widget host(int trigger) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SparkOnAction(
                trigger: trigger,
                child: const Text('🥛'),
              ),
            ),
          ),
        );

    await tester.pumpWidget(host(0));
    expect(_spark(), findsNothing, reason: 'до действия огонька быть не должно');

    await tester.pumpWidget(host(1));
    await tester.pump(const Duration(milliseconds: 120));
    expect(_spark(), findsOneWidget, reason: 'по действию должен вспыхнуть огонёк');

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(_spark(), findsNothing, reason: 'огонёк должен гаснуть сам');
  });

  testWidgets('рюкзачок: весь магазин не переполняет лист и прокручивается',
      (tester) async {
    await _narrow(tester);
    final game = await _readyGame();
    // Худший случай: в рюкзачке лежат все позиции магазина.
    game.inventory = {for (final item in shopCatalog) item.id: 2};

    await tester.pumpWidget(FinnyApp(gameState: game));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(PetAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PetAvatar));
    await tester.pumpAndSettle();

    expect(find.text('🎒 Рюкзачок питомца'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'рюкзачок переполнился');

    // Содержимое выше листа, но список прокручивается, а не вылезает.
    final list = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(Scrollable),
    );
    expect(list, findsOneWidget);
    expect(
      tester.state<ScrollableState>(list).position.maxScrollExtent,
      greaterThan(0),
      reason: 'список должен прокручиваться',
    );

    // Кормим: строка обновляется на месте, показывается эффект, играет огонёк.
    await tester.tap(find.text('Дать').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Молочко × 1'), findsOneWidget);
    // Строка эффекта — это Text без maxLines; у подписи предмета он есть,
    // поэтому по нему и отличаем одно от другого.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data ?? '').contains('Вкусно!') &&
            w.maxLines == null,
      ),
      findsOneWidget,
      reason: 'под листом должен появиться результат действия',
    );
    expect(_spark(), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Готово ✅'));
    await tester.pumpAndSettle();

    expect(find.textContaining('доволен'), findsOneWidget);

    // Даём снекбару уехать, чтобы тест не оставил висящий таймер.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('слайд окрасок и шаг возраста влезают на 360dp', (tester) async {
    await _narrow(tester);

    for (final scheme in [KidsTheme.light(), KidsTheme.dark()]) {
      await tester.pumpWidget(MaterialApp(
        theme: scheme,
        home: Scaffold(
          body: PetColorScreen(
            type: PetType.dog,
            selected: PetVariant.v1,
            onBack: () {},
            onNext: (_) {},
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Уголёк'), findsOneWidget);
      expect(find.text('Выбрано'), findsOneWidget);
      // Галочка выбранной карточки — иконка, а не символ: символа «✓»
      // нет в шрифтах Android, вместо него рисовался пустой квадрат.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'слайд окрасок переполняется',
      );

      await tester.pumpWidget(MaterialApp(
        theme: scheme,
        home: Scaffold(
          body: AgeScreen(
            selected: 9,
            onBack: () {},
            onNext: (_) {},
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('9 лет'), findsWidgets);
      expect(
        tester.takeException(),
        isNull,
        reason: 'шаг возраста переполняется',
      );
    }
  });
}
