import 'package:flutter/material.dart';

import '../theme/kids_theme.dart';

/// Компактный стат для главного экрана: «🍎 78» и тонкая полоска.
///
/// Подпись («Сытость») не пишем — её заменяет эмодзи, а для экранного
/// диктора есть [Semantics]. Значение — числом: состояние видно не только
/// по цвету (требование ТЗ). Низкое значение ещё и мигает мягким фоном.
class StatMeter extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final Color color;

  /// Широкий вариант (опыт): эмодзи, полоска и «40/100» в одну строку.
  final bool wide;

  const StatMeter({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final low = !wide && value <= 25;
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value / 100),
        duration: const Duration(milliseconds: 400),
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: 10,
          backgroundColor: KidsTheme.soft(context),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
    final number = Text(
      wide ? '$value/100' : '$value',
      style: TextStyle(
        fontWeight: FontWeight.w800,
        color: low ? const Color(0xFFD84315) : KidsTheme.muted(context),
      ),
    );

    return Semantics(
      label: '$label: $value из 100',
      excludeSemantics: true,
      child: wide
          ? Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(child: bar),
                const SizedBox(width: 8),
                number,
              ],
            )
          : Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              decoration: BoxDecoration(
                color: low
                    ? const Color(0xFFFF7043).withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Flexible(child: number),
                    ],
                  ),
                  const SizedBox(height: 6),
                  bar,
                ],
              ),
            ),
    );
  }
}
