import 'package:flutter/material.dart';

import '../../app.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/action_spark.dart';
import '../level_up/level_up_screen.dart';
import 'goal_sheet.dart';

/// Сколько монет в день советуем откладывать — для оценки срока цели.
const int _perDay = 25;

/// Сколько дней ещё копить при [_perDay] монетах в день.
int daysToGoal(int left) => left <= 0 ? 0 : (left + _perDay - 1) ~/ _perDay;

/// Копилка: цель, прогресс, пополнение и снятие.
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
    final wasReached = game.goalProgress >= 1;
    if (!game.deposit(amount)) return;
    setState(() => _spark++);
    if (!wasReached && game.goalProgress >= 1) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('🎉 Цель достигнута!'),
          content: Text('Ты накопил на «${game.goalName}»!'),
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

  /// Снятие — только после подтверждения: заранее показываем новую сумму
  /// и новый срок до цели (правило из ТЗ).
  Future<void> _withdraw(int amount) async {
    final game = GameStateScope.read(context);
    final newSavings = game.savings - amount;
    final newLeft = game.goalTarget - newSavings;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Забрать $amount 🪙?'),
        content: Text(
          'В копилке станет $newSavings из ${game.goalTarget}.\n'
          'До цели — ещё ${daysToGoal(newLeft)} дн. '
          '(было ${daysToGoal(game.goalLeft)}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Оставить'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Забрать'),
          ),
        ],
      ),
    );
    if (ok == true) game.withdraw(amount);
  }

  Future<void> _editGoal() async {
    final changed = await showGoalSheet(context, GameStateScope.read(context));
    if (changed && mounted) setState(() => _spark++);
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final reached = game.goalProgress >= 1;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              children: [
                SparkOnAction(
                  trigger: _spark,
                  spread: 56,
                  child: Text(game.goalEmoji,
                      style: const TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 8),
                Text(
                  game.goalName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: game.goalProgress),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, v, _) =>
                        LinearProgressIndicator(value: v, minHeight: 18),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reached
                      ? 'Накоплено! 🎉'
                      : '🐷 ${game.savings} из ${game.goalTarget}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (!reached)
                  Text(
                    'По $_perDay 🪙 в день — ещё ${daysToGoal(game.goalLeft)} дн.',
                    style: TextStyle(color: KidsTheme.muted(context)),
                  ),
                TextButton.icon(
                  onPressed: _editGoal,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: Text(reached ? 'Новая цель' : 'Изменить цель'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Отложить',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Flexible(
              child: Text(
                'В кошельке 🪙 ${game.balance}',
                textAlign: TextAlign.right,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [10, 25, 50]
              .map(
                (amount) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: game.savings < 10 ? null : () => _withdraw(10),
            child: const Text('Забрать 10 из копилки'),
          ),
        ),
      ],
    );
  }
}
