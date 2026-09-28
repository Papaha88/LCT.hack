import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/shop_data.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/action_spark.dart';

/// Магазин: шесть отделов (еда, уход, здоровье, игры, наряды, уют),
/// скидка дня и совет Финни. Купленное падает в рюкзачок
/// (тап по питомцу на главном экране).
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  /// Счётчики вспышек: «огонёк» играет на той покупке, которую сделали.
  final Map<String, int> _sparks = {};

  /// Выбранный отдел; null — «Все».
  ItemKind? _kind;

  void _buy(ShopItem item) {
    final game = GameStateScope.read(context);
    final price = game.priceOf(item);
    final ok = game.buyItem(item.id);
    if (ok) {
      setState(() => _sparks[item.id] = (_sparks[item.id] ?? 0) + 1);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Куплено: ${item.title}! Лежит в рюкзачке 🎒'
              : 'Не хватает ${price - game.balance} 🪙. '
                  'Реши задание на дороге — и заработаешь!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final deal = dealOfDay(game.day);
    final tip = shopTips[game.day % shopTips.length];
    final kinds = _kind == null ? ItemKind.values : [_kind!];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '💡 $tip',
                style: TextStyle(color: KidsTheme.muted(context)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
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
          ],
        ),
        const SizedBox(height: 12),
        _DealCard(
          item: deal,
          price: game.priceOf(deal),
          spark: _sparks[deal.id] ?? 0,
          onBuy: game.balance >= game.priceOf(deal) ? () => _buy(deal) : null,
        ),
        const SizedBox(height: 12),
        // Отделы: горизонтальная лента чипов, крупных для пальца.
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _KindChip(
                label: '🛍️ Все',
                selected: _kind == null,
                onTap: () => setState(() => _kind = null),
              ),
              ...ItemKind.values.map(
                (k) => _KindChip(
                  label: '${k.emoji} ${k.title}',
                  selected: _kind == k,
                  onTap: () => setState(() => _kind = k),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...kinds.map(
          (kind) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${kind.emoji} ${kind.title}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _NeedTag(mandatory: kind.mandatory),
                ],
              ),
              const SizedBox(height: 8),
              ...shopCatalog.where((item) => item.kind == kind).map(
                    (item) => _ItemCard(
                      item: item,
                      owned: game.inventory[item.id] ?? 0,
                      price: game.priceOf(item),
                      spark: _sparks[item.id] ?? 0,
                      onBuy: game.balance >= game.priceOf(item)
                          ? () => _buy(item)
                          : null,
                    ),
                  ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }
}

/// Строка эффектов: «🍎 +20  😊 +5» — видно пользу без чтения описания.
String effectsLine(ShopItem item) {
  final parts = <String>[
    if (item.hunger > 0) '🍎 +${item.hunger}',
    if (item.happiness > 0) '😊 +${item.happiness}',
    if (item.cleanliness > 0) '🧼 +${item.cleanliness}',
    if (item.xp > 5) '✨ +${item.xp}',
  ];
  return parts.join('   ');
}

class _ItemCard extends StatelessWidget {
  final ShopItem item;
  final int owned;
  final int price;
  final int spark;
  final VoidCallback? onBuy;

  const _ItemCard({
    required this.item,
    required this.owned,
    required this.price,
    required this.spark,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final discounted = price != item.price;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Огонёк вспыхивает на купленном предмете.
              SparkOnAction(
                trigger: spark,
                spread: 30,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: KidsTheme.soft(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(item.emoji,
                      style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.title}${owned > 0 ? ' × $owned' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (item.badge != null || discounted)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 2),
                        child: _Badge(
                          text: discounted
                              ? '🔥 −$dealPercent%'
                              : item.badge!,
                        ),
                      ),
                    Text(
                      effectsLine(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // ТЗ: тач-таргет не меньше 48x48dp.
                  minimumSize: const Size(84, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: onBuy,
                child: Text('🪙 $price'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Большая карточка «Скидка дня».
class _DealCard extends StatelessWidget {
  final ShopItem item;
  final int price;
  final int spark;
  final VoidCallback? onBuy;

  const _DealCard({
    required this.item,
    required this.price,
    required this.spark,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB547), Color(0xFFFF7A59)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SparkOnAction(
                trigger: spark,
                spread: 34,
                child:
                    Text(item.emoji, style: const TextStyle(fontSize: 44)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔥 Скидка дня −$dealPercent%',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Было ${item.price} 🪙',
                      style: const TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFD9480F),
              minimumSize: const Size(48, 48),
            ),
            onPressed: onBuy,
            child: Text('Купить за $price 🪙'),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : KidsTheme.pill(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// «Надо» / «Хочу» — текстом, а не только цветом (требование ТЗ).
class _NeedTag extends StatelessWidget {
  final bool mandatory;

  const _NeedTag({required this.mandatory});

  @override
  Widget build(BuildContext context) {
    final color =
        mandatory ? const Color(0xFF2E7D32) : const Color(0xFF8E24AA);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        mandatory ? '✅ Надо' : '💜 Хочу',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: KidsTheme.isDark(context) ? Colors.white : color,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE3B3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8A4B00),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
