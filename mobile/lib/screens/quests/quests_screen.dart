import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/quests_data.dart';
import '../../widgets/action_spark.dart';

/// Задания: выполнил — получил монетки.
class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  /// Счётчики вспышек: «огонёк» играет на выполненном задании.
  final Map<String, int> _sparks = {};

  void _complete(Quest quest) {
    GameStateScope.read(context).completeQuest(quest.id);
    setState(() => _sparks[quest.id] = (_sparks[quest.id] ?? 0) + 1);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Задание выполнено! +${quest.reward} 🪙'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Выполняй задания и получай монетки!'),
        const SizedBox(height: 12),
        ...questsCatalog.map((q) {
          final done = game.questsDone.contains(q.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    SparkOnAction(
                      trigger: _sparks[q.id] ?? 0,
                      spread: 30,
                      child: Text(q.emoji,
                          style: const TextStyle(fontSize: 36)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            q.desc,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '+${q.reward} монет 🪙',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (done)
                      const Text('✅', style: TextStyle(fontSize: 26))
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          // ТЗ: тач-таргет не меньше 48x48dp.
                          minimumSize: const Size(92, 48),
                        ),
                        onPressed: () => _complete(q),
                        child: const Text('Готово'),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
