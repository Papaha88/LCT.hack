import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';

/// Банк-копилка: цель, прогресс, пополнение и снятие.
class BankScreen extends StatelessWidget {
  const BankScreen({super.key});

  void _deposit(BuildContext context, int amount) {
    final game = GameStateScope.read(context);
    final ok = game.deposit(amount);
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
      showDialog<void>(
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
  }

  Future<void> _editGoal(BuildContext context) async {
    final game = GameStateScope.read(context);
    final nameController = TextEditingController(text: game.goalName);
    final targetController =
        TextEditingController(text: game.goalTarget.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🎯 Моя цель'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'О чём мечтаешь?',
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Сколько монет нужно? (мин. 50)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    final name = nameController.text;
    final target =
        int.tryParse(targetController.text) ?? game.goalTarget;
    nameController.dispose();
    targetController.dispose();

    if (result == true) {
      game.updateGoal(name, target);
    }
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
          const Text(
            '🐷 Копилка',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Откладывай монетки на большую мечту!'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('🐷', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 8),
                  Text(
                    'Цель: ${game.goalName}',
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
                    style: const TextStyle(fontSize: 15),
                  ),
                  TextButton.icon(
                    onPressed: () => _editGoal(context),
                    icon: const Text('✏️'),
                    label: const Text('Изменить цель'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'В кошельке: 🪙 ${game.balance}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                            : () => _deposit(context, amount),
                        child: Text(
                          '+$amount',
                          style: const TextStyle(fontSize: 18),
                        ),
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
        ],
      ),
    );
  }
}
