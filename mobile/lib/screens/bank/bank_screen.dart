import 'package:flutter/material.dart';

import '../../app.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/action_spark.dart';
import '../level_up/level_up_screen.dart';
import 'goal_sheet.dart';

/// Банк-копилка: цель, прогресс, пополнение и снятие.
class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  /// Счётчик вспышек: «огонёк» играет на копилке после пополнения.
  int _spark = 0;

  Future<void> _deposit(int amount) async {
    final game = GameStateScope.read(context);
    final ok = game.deposit(amount);
    if (!mounted) return;
    if (ok) setState(() => _spark++);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
              ok ? 'В копилку: +$amount 🐷' : 'Не хватает монеток 😢'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    if (ok && game.goalProgress >= 1) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('🎉 Цель достигнута!'),
          content: Text(
            'Мы накопили на «${game.goalName}»! '
            'Ты настоящий финансовый эксперт!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Ура!'),
            ),
          ],
        ),
      );
    }
    // Копилка даёт опыт — питомец мог дорасти до нового уровня.
    if (mounted) await showLevelUpIfNeeded(context);
  }

  Future<void> _editGoal() async {
    final game = GameStateScope.read(context);
    final changed = await showGoalSheet(context, game);
    if (!mounted || !changed) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Новая цель: ${game.goalEmoji} ${game.goalName}!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final reached = game.goalProgress >= 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Откладывай монетки на большую мечту!'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Огонёк вспыхивает на копилке после пополнения.
                  SparkOnAction(
                    trigger: _spark,
                    spread: 56,
                    child: const Text('🐷', style: TextStyle(fontSize: 64)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Цель: ${game.goalEmoji} ${game.goalName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: game.goalProgress,
                      minHeight: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reached
                        ? 'Накоплено! Можно праздновать! 🎉'
                        : 'Есть ${game.savings} из ${game.goalTarget} • '
                            'осталось ${game.goalLeft}',
                    textAlign: TextAlign.center,
                  ),
                  if (!reached && game.goalLeft > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Если откладывать по 25 🪙 в день — ещё '
                      '${(game.goalLeft + 24) ~/ 25} дн.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: KidsTheme.muted(context)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: _editGoal,
                    icon: const Text('✏️'),
                    label: Text(reached
                        ? 'Выбрать новую цель'
                        : 'Изменить цель'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'В кошельке: 🪙 ${game.balance}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [10, 25, 50]
                .map(
                  (amount) => Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: game.balance < amount
                            ? null
                            : () => _deposit(amount),
                        child: Text('+$amount'),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: game.savings < 10
                ? null
                : () => GameStateScope.read(context).withdraw(10),
            child: const Text('Забрать 10 из копилки'),
          ),
          const SizedBox(height: 4),
          Text(
            'Снятие из копилки сдвинет срок достижения цели 🐷',
            textAlign: TextAlign.center,
            style: TextStyle(color: KidsTheme.muted(context)),
          ),
        ],
      ),
    );
  }
}
