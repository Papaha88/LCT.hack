import 'package:flutter/material.dart';

import 'app.dart';
import 'models/game_state.dart';
import 'services/pet_assets.dart';

/// Точка входа: грузим сейв и запускаем приложение.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gameState = GameState();
  // Список моделей питомца (webp) и сейв грузим параллельно.
  await Future.wait([PetAssets.init(), gameState.init()]);
  runApp(FinnyApp(gameState: gameState));
}
