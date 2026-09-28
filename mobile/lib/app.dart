import 'package:flutter/material.dart';

import 'models/game_state.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'theme/kids_theme.dart';

/// Корень приложения: слушает GameState и переключает
/// онбординг <-> главный экран с навигацией.
class FinnyApp extends StatelessWidget {
  final GameState gameState;

  const FinnyApp({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return GameStateScope(
      notifier: gameState,
      child: AnimatedBuilder(
        animation: gameState,
        builder: (context, _) => MaterialApp(
          title: 'Финни — финансовый питомец',
          debugShowCheckedModeBanner: false,
          theme: KidsTheme.light(),
          darkTheme: KidsTheme.dark(),
          themeMode: gameState.isDark ? ThemeMode.dark : ThemeMode.light,
          home: gameState.onboardingDone
              ? const MainShell()
              : const OnboardingFlow(),
        ),
      ),
    );
  }
}

/// Простая раздача GameState вниз по дереву без внешних пакетов
/// (лёгкая замена Provider'а: InheritedWidget + ChangeNotifier).
class GameStateScope extends InheritedNotifier<GameState> {
  const GameStateScope({
    super.key,
    required GameState super.notifier,
    required super.child,
  });

  /// С подпиской на изменения (для build-методов экранов).
  static GameState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<GameStateScope>();
    assert(scope != null, 'GameStateScope не найден над виджетом');
    return scope!.notifier!;
  }

  /// Без подписки (для обработчиков нажатий и диалогов).
  static GameState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<GameStateScope>();
    assert(scope != null, 'GameStateScope не найден над виджетом');
    return scope!.notifier!;
  }
}
