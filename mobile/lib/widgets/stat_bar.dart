import 'package:flutter/material.dart';

/// Полоска стата: эмодзи + подпись + «78/100» + прогресс.
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
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$value/100 • $_hint',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5A5470),
                    fontWeight: FontWeight.w600,
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
                backgroundColor: const Color(0xFFEDE7F6),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
