import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/shop_data.dart';

/// Магазин: еда, уход, игрушки.
/// Купленное падает в рюкзачок (тап по питомцу на главном экране).
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '🛍️ Магазин',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '🪙 ${game.balance}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Сначала важное — еда и уход! Потом — игрушки 🎁'),
        const SizedBox(height: 12),
        ...ItemKind.values.map(
          (kind) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${kind.emoji} ${kind.title}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...shopCatalog
                  .where((item) => item.kind == kind)
                  .map((item) {
                final owned = game.inventory[item.id] ?? 0;
                final afford = game.balance >= item.price;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text(item.emoji,
                              style:
                                  const TextStyle(fontSize: 36)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.title}${owned > 0 ? ' × $owned' : ''}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item.effectText,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(76, 44),
                            ),
                            onPressed: afford
                                ? () {
                                    final ok =
                                        GameStateScope.read(context)
                                            .buyItem(item.id);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(ok
                                            ? 'Куплено: ${item.title}! 🎉'
                                            : 'Не хватает монеток 😢'),
                                        behavior:
                                            SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                : null,
                            child: Text(
                              '🪙 ${item.price}',
                              style:
                                  const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }
}
