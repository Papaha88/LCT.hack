import 'package:flutter/material.dart';

import '../../theme/kids_theme.dart';
import '../../widgets/finny_avatar.dart';
import '../../widgets/finny_bubble.dart';
import '../../widgets/kids_button.dart';

/// Шаг 6. Три главных правила игры.
class RulesScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;

  const RulesScreen({super.key, required this.onBack, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FinnyAvatar(size: 96),
                  SizedBox(height: 12),
                  FinnyBubble(
                      text: 'Вот три главных правила нашей игры:'),
                  SizedBox(height: 16),
                  _RuleCard(
                    emoji: '1️⃣',
                    title: 'Сначала важное',
                    text: 'Всегда покупай еду и уход. Это обязательно!',
                  ),
                  SizedBox(height: 10),
                  _RuleCard(
                    emoji: '2️⃣',
                    title: 'Потом интересное',
                    text: 'Можешь купить игрушку или украшение.',
                  ),
                  SizedBox(height: 10),
                  _RuleCard(
                    emoji: '3️⃣',
                    title: 'На мечту',
                    text:
                        'Откладывай монетки в копилку, чтобы накопить на большую цель.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Твой питомец будет расти и радоваться, если ты будешь '
                    'правильно распределять монетки! 💛',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          KidsButton(text: 'Понятно, давай играть! 🚀', onPressed: onNext),
          BackLink(onPressed: onBack),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String text;

  const _RuleCard({
    required this.emoji,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Цвет плашки, а не жёсткий белый: в тёмной теме текст пропадал.
        color: KidsTheme.pill(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
