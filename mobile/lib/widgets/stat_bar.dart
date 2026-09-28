import 'package:flutter/material.dart';

import '../theme/kids_theme.dart';

/// Полоска стата: эмодзи + подпись + «78/100 • отлично!» + прогресс.
/// Важно: состояние дублируется текстом, а не только цветом (требование ТЗ).
class StatBar extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  const StatBar({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  String get _hint {
    if (value <= 25) return 'очень низко!';
    if (value <= 60) return 'так себе';
    return 'отлично!';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                // Flexible, а не просто Text: при крупном системном шрифте
                // подпись переносится, а не вылезает за карточку.
                Flexible(
                  child: Text(
                    '$value/100 • $_hint',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: KidsTheme.muted(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 12,
                backgroundColor: KidsTheme.soft(context),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
