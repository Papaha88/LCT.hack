import 'package:flutter/material.dart';

import '../app.dart';
import 'action_spark.dart';

/// «Огонёк» в шапке: сколько дней подряд ребёнок что-то делал в игре.
///
/// Вспыхивает на каждое действие (кормление, покупка, копилка, задание) —
/// так любое действие в приложении получает отклик, где бы оно ни было.
/// Если сегодня действий ещё не было, огонёк бледный: «зажги его!».
class StreakFlame extends StatelessWidget {
  const StreakFlame({super.key});

  void _explain(BuildContext context, int streak, bool lit) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lit ? '🔥' : '🕯️', style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(
                streak == 0 ? 'Зажги огонёк!' : 'Огонёк: $streak дн. подряд',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lit
                    ? 'Сегодня огонёк уже горит. Приходи завтра!'
                    : 'Покорми питомца, реши задание или отложи монетки — '
                        'и огонёк загорится.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Понятно'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final lit = game.streakLitToday;
    return Semantics(
      button: true,
      label: 'Огонёк: ${game.streak} дней подряд',
      child: InkWell(
        onTap: () => _explain(context, game.streak, lit),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: SparkOnAction(
            trigger: game.actionPulse,
            spread: 30,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: lit ? 1 : 0.45,
                  child: const Text('🔥', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 2),
                Text(
                  '${game.streak}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
