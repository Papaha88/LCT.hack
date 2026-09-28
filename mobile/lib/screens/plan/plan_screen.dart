import 'package:flutter/material.dart';

import '../../app.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/action_spark.dart';
import '../../widgets/kids_button.dart';
import '../level_up/level_up_screen.dart';

/// План бюджета: три шага «важное → интересное → мечта» с живыми цифрами.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  int _spark = 0;

  Future<void> _save20() async {
    if (!GameStateScope.read(context).deposit(20)) return;
    setState(() => _spark++);
    // Копилка даёт опыт — питомец мог дорасти до уровня.
    await showLevelUpIfNeeded(context);
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final items = game.inventory.values.fold<int>(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Трать с умом — в три шага',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _Step(
          number: 1,
          emoji: '🍎',
          title: 'Сначала важное',
          text: 'Еда и уход',
          value: '🪙 ${game.balance}',
          color: const Color(0xFF43A047),
        ),
        _Step(
          number: 2,
          emoji: '🧸',
          title: 'Потом интересное',
          text: 'Игрушки и наряды',
          value: '🎒 $items',
          color: const Color(0xFF8E24AA),
        ),
        _Step(
          number: 3,
          emoji: game.goalEmoji,
          title: 'На мечту',
          text: game.goalName,
          value: '🐷 ${game.savings}/${game.goalTarget}',
          color: const Color(0xFFF08A24),
          last: true,
        ),
        const SizedBox(height: 16),
        SparkOnAction(
          trigger: _spark,
          spread: 48,
          child: KidsButton(
            text: 'Отложить 20 в копилку',
            icon: Icons.savings_outlined,
            onPressed: game.balance < 20 ? null : _save20,
          ),
        ),
      ],
    );
  }
}

/// Шаг плана: номер в кружке, линия к следующему шагу, цифры справа.
class _Step extends StatelessWidget {
  final int number;
  final String emoji;
  final String title;
  final String text;
  final String value;
  final Color color;
  final bool last;

  const _Step({
    required this.number,
    required this.emoji,
    required this.title,
    required this.text,
    required this.value,
    required this.color,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: KidsTheme.muted(context)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        value,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
