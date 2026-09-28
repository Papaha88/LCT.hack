import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/shop_data.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/action_spark.dart';

/// Магазин: еда, уход, игрушки.
/// Купленное падает в рюкзачок (тап по питомцу на главном экране).
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  /// Счётчики вспышек: «огонёк» играет на той покупке, которую сделали.
  final Map<String, int> _sparks = {};

  void _buy(String itemId, String title) {
    final game = GameStateScope.read(context);
    final ok = game.buyItem(itemId);
    if (ok) {
      setState(() => _sparks[itemId] = (_sparks[itemId] ?? 0) + 1);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ok ? 'Куплено: $title! 🎉' : 'Не хватает монеток 😢'),
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
        // Баланс отдельной плашкой: длинная подсказка ниже его не сжимает.
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: KidsTheme.pill(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '🪙 ${game.balance}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Сначала важное — еда и уход! Потом — игрушки 🎁'),
        const SizedBox(height: 12),
        ...ItemKind.values.map(
          (kind) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${kind.emoji} ${kind.title}',
                style: const TextStyle(
                  fontSize: 18,
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
                          // Огонёк вспыхивает на купленном предмете.
                          SparkOnAction(
                            trigger: _sparks[item.id] ?? 0,
                            spread: 30,
                            child: Text(item.emoji,
                                style: const TextStyle(fontSize: 36)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.title}${owned > 0 ? ' × $owned' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item.effectText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              // ТЗ: тач-таргет не меньше 48x48dp.
                              minimumSize: const Size(84, 48),
                            ),
                            onPressed: afford
                                ? () => _buy(item.id, item.title)
                                : null,
                            child: Text('🪙 ${item.price}'),
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
