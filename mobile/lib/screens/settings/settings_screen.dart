import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/pet.dart';

/// Настройки: профиль, сброс прогресса, о приложении.
/// Открываются шестерёнкой в AppBar (не занимают вкладку навигации).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final game = GameStateScope.read(context);
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Начать заново?'),
        content: const Text(
            'Питомец и все монетки исчезнут. Точно-точно?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Ой, нет!'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Да, заново'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await game.reset();
      // Приложение само переключится на онбординг, стек чистим:
      navigator.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final pet = game.pet;

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👋 ${game.nickname}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (pet != null) ...[
                    const SizedBox(height: 4),
                    Text(
                        '${pet.type.emoji} Питомец: ${pet.name} • ${pet.stage}'),
                    Text(
                      '📅 День ${game.day} • 🪙 ${game.balance} • '
                      '🐷 ${game.savings}',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Text('ℹ️',
                      style: TextStyle(fontSize: 24)),
                  title: const Text('О приложении'),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Финни 🐧'),
                      content: const Text(
                        'Игра для детей 7–11 лет: заботимся о питомце '
                        'и учимся управлять монетками!',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          child: const Text('Понятно'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Text('🔄',
                      style: TextStyle(fontSize: 24)),
                  title: const Text('Начать игру заново'),
                  subtitle:
                      const Text('Стереть питомца и монетки'),
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
