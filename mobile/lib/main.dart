import 'package:flutter/material.dart';

import 'app.dart';
import 'models/game_state.dart';

/// Точка входа: грузим сейв и запускаем приложение.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gameState = GameState();
  await gameState.init();
  runApp(FinnyApp(gameState: gameState));
}
