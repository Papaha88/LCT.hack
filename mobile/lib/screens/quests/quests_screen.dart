import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/quests_data.dart';

/// Задания: выполнил — получил монетки.
class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '⭐ Задания',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
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
                    Text(q.emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(q.desc,
                              style: const TextStyle(fontSize: 14)),
                          Text(
                            '+${q.reward} монет 🪙',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (done)
                      const Text('✅',
                          style: TextStyle(fontSize: 26))
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(88, 44),
                        ),
                        onPressed: () {
                          GameStateScope.read(context)
                              .completeQuest(q.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Задание выполнено! +${q.reward} 🪙'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('Готово',
                            style: TextStyle(fontSize: 16)),
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
