import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/shop_data.dart';
import '../../models/pet.dart';
import '../../widgets/finny_avatar.dart';
import '../../widgets/kids_button.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/stat_bar.dart';

/// Главный экран: баланс, уровень, цель, питомец, статы,
/// подсказка Финни, активное задание, смена периода.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterFirstFrame());
  }

  Future<void> _afterFirstFrame() async {
    if (!mounted) return;
    final game = GameStateScope.read(context);

    // Первый вход после онбординга — «Секрет игры».
    if (game.justFinishedOnboarding) {
      game.justFinishedOnboarding = false;
      final petName = game.pet?.name ?? 'питомец';
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('🤫 Секрет игры'),
          content: Text(
            'Чем лучше ты планируешь свои траты и вкладываешь монеты '
            'в обучение, тем больше монет ты будешь получать в будущем, '
            'и тем быстрее $petName вырастет!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Круто! 🚀'),
            ),
          ],
        ),
      );
      return;
    }

    // Возвращение в новый день — ежедневный бонус +15.
    if (game.claimDailyBonusIfNeeded()) {
      if (!mounted) return;
      final petName = game.pet?.name ?? 'Питомец';
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('🎁 Ежедневный бонус'),
          content: Text('$petName рад тебя видеть! +15 монет 🪙'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Ура!'),
            ),
          ],
        ),
      );
    }
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  /// Тап по питомцу: текстовая подсказка + рюкзачок.
  void _onPetTap() {
    final game = GameStateScope.read(context);
    final pet = game.pet;
    if (pet == null) return;
    _showSnack(pet.moodText());
    _openInventory();
  }

  /// Рюкзачок: купленная еда, уход и игрушки. Тап — использовать.
  void _openInventory() {
    final game = GameStateScope.read(context);
    final owned = shopCatalog
        .where((item) => (game.inventory[item.id] ?? 0) > 0)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎒 Рюкзачок питомца',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text('Нажми «Дать», чтобы использовать предмет.'),
              const SizedBox(height: 12),
              if (owned.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Пока пусто... Загляни в магазин! 🛍️',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              else
                ...owned.map((item) {
                  final count = game.inventory[item.id] ?? 0;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(item.emoji,
                        style: const TextStyle(fontSize: 32)),
                    title: Text('${item.title} × $count'),
                    subtitle: Text(item.effectText),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(72, 44),
                      ),
                      onPressed: () {
                        final effect = game.useItem(item.id);
                        Navigator.of(sheetContext).pop();
                        if (effect != null) _showSnack(effect);
                      },
                      child: const Text('Дать',
                          style: TextStyle(fontSize: 16)),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  /// Кнопка переключения периода: «новый день» + начисление дохода.
  Future<void> _nextDay() async {
    final game = GameStateScope.read(context);
    final income = game.nextDay();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('☀️ День ${game.day}!'),
        content: Text(
          'Новый день наступил!\n'
          'Доход: +$income монет 🪙\n'
          'Не забудь покормить питомца!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отлично!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final pet = game.pet;

    if (pet == null) {
      return const Center(child: Text('Питомец не найден 😢'));
    }

    final hints = game.finnyHints();
    final quest = game.activeQuest;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Баланс • Уровень • День
          Row(
            children: [
              _Pill(emoji: '🪙', text: '${game.balance}'),
              const SizedBox(width: 8),
              _Pill(emoji: '⭐', text: 'Ур. ${pet.level}'),
              const SizedBox(width: 8),
              _Pill(emoji: '📅', text: 'День ${game.day}'),
            ],
          ),
          const SizedBox(height: 12),

          // Цель + накопления
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🎯 Цель: ',
                          style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          game.goalName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text('${(game.goalProgress * 100).round()}%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: game.goalProgress,
                      minHeight: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Накоплено ${game.savings} из ${game.goalTarget} • '
                    'осталось ${game.goalLeft}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Питомец + статы
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pet.stage,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _onPetTap,
                    child: PetAvatar(
                      type: pet.type,
                      variant: pet.variant,
                      size: 150,
                      moodEmoji: pet.moodEmoji,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pet.moodText(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Нажми на питомца, чтобы открыть рюкзачок 🎒',
                    style: TextStyle(fontSize: 13),
                  ),
                  const Divider(height: 24),
                  StatBar(
                    emoji: '🍎',
                    label: 'Сытость',
                    value: pet.hunger,
                    color: const Color(0xFF66BB6A),
                    onTap: () => _showSnack(pet.hunger <= 40
                        ? '${pet.name} голоден!'
                        : 'Сытость: ${pet.hunger}/100'),
                  ),
                  StatBar(
                    emoji: '😊',
                    label: 'Счастье',
                    value: pet.happiness,
                    color: const Color(0xFFFFB020),
                    onTap: () =>
                        _showSnack('Счастье: ${pet.happiness}/100'),
                  ),
                  StatBar(
                    emoji: '🧼',
                    label: 'Чистота',
                    value: pet.cleanliness,
                    color: const Color(0xFF4FC3F7),
                    onTap: () =>
                        _showSnack('Чистота: ${pet.cleanliness}/100'),
                  ),
                  StatBar(
                    emoji: '✨',
                    label: 'Опыт (XP)',
                    value: pet.xp,
                    color: const Color(0xFFAB47BC),
                    onTap: () => _showSnack(
                        'Уровень ${pet.level}: ${pet.xp}/100 XP'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Мягкое уведомление от Финни
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinnyAvatar(size: 56, waving: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hints.first,
                      style: const TextStyle(fontSize: 16, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Активное задание
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: quest == null
                  ? const Text(
                      '🎉 Все задания выполнены! Ты супер!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Row(
                      children: [
                        Text(quest.emoji,
                            style: const TextStyle(fontSize: 34)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Активное задание ⭐',
                                style: TextStyle(fontSize: 13),
                              ),
                              Text(
                                quest.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '+${quest.reward} монет',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          KidsButton(text: 'Следующий день 👉', onPressed: _nextDay),
          const SizedBox(height: 8),
          Text(
            'Доход за день: +${game.baseIncome} монет',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String emoji;
  final String text;

  const _Pill({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$emoji $text',
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
