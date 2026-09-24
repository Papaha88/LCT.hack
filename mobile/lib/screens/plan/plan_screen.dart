import 'package:flutter/material.dart';

import '../../app.dart';
import '../../widgets/kids_button.dart';

/// План бюджета: 3 правила + живые цифры + быстрое действие.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '📋 Мой план бюджета',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Трать монетки с умом — как настоящий эксперт!'),
          const SizedBox(height: 12),
          _BucketCard(
            emoji: '🍎',
            title: '1. Сначала важное',
            text: 'Еда и уход для питомца. Это обязательно!',
            footer: 'В кошельке: 🪙 ${game.balance}',
          ),
          const SizedBox(height: 10),
          _BucketCard(
            emoji: '🧸',
            title: '2. Потом интересное',
            text: 'Игрушка или украшение — если хватает монет.',
            footer:
                'В рюкзачке: 🎒 ${game.inventory.values.fold<int>(0, (a, b) => a + b)} предм.',
          ),
          const SizedBox(height: 10),
          _BucketCard(
            emoji: '🐷',
            title: '3. На мечту',
            text: 'Откладывай в копилку на цель «${game.goalName}».',
            footer:
                'Накоплено: 🪙 ${game.savings} из ${game.goalTarget}',
          ),
          const SizedBox(height: 16),
          KidsButton(
            text: 'Отложить 20 в копилку 🐷',
            onPressed: game.balance < 20
                ? null
                : () {
                    final ok = GameStateScope.read(context).deposit(20);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Копилка пополнена! +20 🐷'
                              : 'Не хватает монеток 😢'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  },
          ),
        ],
      ),
    );
  }
}

class _BucketCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String text;
  final String footer;

  const _BucketCard({
    required this.emoji,
    required this.title,
    required this.text,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(
                    footer,
                    // Подпись с цифрами не должна упираться в край карточки.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
