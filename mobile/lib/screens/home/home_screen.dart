import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/shop_data.dart';
import '../../models/game_state.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/action_spark.dart';
import '../../widgets/finny_avatar.dart';
import '../../widgets/kids_button.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/stat_bar.dart';

/// Главный экран: приветствие с возрастом, баланс, уровень, цель, питомец,
/// статы, подсказка Финни, активное задание, смена периода.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Счётчик вспышек вокруг питомца: каждое действие увеличивает его
  /// на 1, и «огонёк» проигрывается заново.
  int _petSpark = 0;

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

  /// Тап по питомцу открывает рюкзачок. Подсказка о настроении и так
  /// написана под питомцем, поэтому снекбар здесь только мешал бы листу.
  Future<void> _onPetTap() async {
    final game = GameStateScope.read(context);
    if (game.pet == null) return;
    final used = await _openInventory(game);
    if (!mounted || used <= 0) return;
    setState(() => _petSpark++);
    _showSnack('${game.pet!.name} доволен! 💛');
  }

  /// Рюкзачок: купленная еда, уход и игрушки. Тап — использовать.
  ///
  /// Возвращает число использованных предметов: по нему главный экран
  /// понимает, что питомцу стоит показать «огонёк».
  Future<int> _openInventory(GameState game) async {
    final used = await showModalBottomSheet<int>(
      context: context,
      // Лист может занять больше половины экрана — иначе шесть предметов
      // в него не влезают.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _InventorySheet(game: game),
    );
    return used ?? 0;
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
    // Огонёк показываем после диалога — за ним его не было бы видно.
    if (mounted) setState(() => _petSpark++);
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final pet = game.pet;
    final scheme = Theme.of(context).colorScheme;

    if (pet == null) {
      return const Center(child: Text('Питомец не найден 😢'));
    }

    final hints = game.finnyHints();
    final quest = game.activeQuest;
    final age = game.age;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Приветствие: имя игрока и его возраст.
          Row(
            children: [
              Expanded(
                child: Text(
                  'Привет, ${game.nickname}!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (age != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: KidsTheme.pill(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '👦 $age лет',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Баланс • Уровень • День. Wrap, а не Row: на узких экранах
          // плашки переносятся на вторую строку, а не сжимают текст.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _Pill(emoji: '🪙', text: '${game.balance}'),
              _Pill(emoji: '⭐', text: 'Ур. ${pet.level}'),
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
                      const Text('🎯 Цель: '),
                      Expanded(
                        child: Text(
                          game.goalName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: KidsTheme.soft(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pet.stage,
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
                  GestureDetector(
                    onTap: _onPetTap,
                    child: SparkOnAction(
                      trigger: _petSpark,
                      spread: 52,
                      child: PetAvatar(
                        type: pet.type,
                        variant: pet.variant,
                        size: 150,
                        moodEmoji: pet.moodEmoji,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pet.moodText(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Нажми на питомца, чтобы открыть рюкзачок 🎒',
                    textAlign: TextAlign.center,
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
                      style: const TextStyle(height: 1.35),
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
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                              Text(
                                'Активное задание ⭐',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                quest.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('+${quest.reward} монет'),
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
            style: TextStyle(color: scheme.onSurfaceVariant),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KidsTheme.pill(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$emoji $text',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Рюкзачок питомца: список предметов, «Дать» и «огонёк» на использованном.
///
/// Список берётся снимком на момент открытия и не «дёргается», когда
/// предмет заканчивается: строка остаётся и показывает «закончился».
class _InventorySheet extends StatefulWidget {
  final GameState game;

  const _InventorySheet({required this.game});

  @override
  State<_InventorySheet> createState() => _InventorySheetState();
}

class _InventorySheetState extends State<_InventorySheet> {
  late final List<ShopItem> _items = shopCatalog
      .where((item) => (widget.game.inventory[item.id] ?? 0) > 0)
      .toList();

  final Map<String, int> _sparks = {};
  int _used = 0;
  String? _lastEffect;

  void _give(ShopItem item) {
    final effect = widget.game.useItem(item.id);
    if (effect == null) return;
    setState(() {
      _used += 1;
      _sparks[item.id] = (_sparks[item.id] ?? 0) + 1;
      _lastEffect = effect;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎒 Рюкзачок питомца',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Нажми «Дать», чтобы использовать предмет.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            if (_lastEffect != null) ...[
              const SizedBox(height: 10),
              _EffectLine(text: _lastEffect!),
            ],
            const SizedBox(height: 10),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Пока пусто... Загляни в магазин! 🛍️'),
              )
            else
              // Прокрутка с ограничением по высоте: шесть предметов
              // больше не переполняют лист.
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                  ),
                  child: AnimatedBuilder(
                    animation: game,
                    builder: (context, _) => ListView.separated(
                      shrinkWrap: true,
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final count = game.inventory[item.id] ?? 0;
                        return _InventoryRow(
                          item: item,
                          count: count,
                          spark: _sparks[item.id] ?? 0,
                          onGive: count > 0 ? () => _give(item) : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            KidsButton(
              text: 'Готово ✅',
              onPressed: () => Navigator.of(context).pop(_used),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final ShopItem item;
  final int count;

  /// Счётчик вспышек для этой строки.
  final int spark;
  final VoidCallback? onGive;

  const _InventoryRow({
    required this.item,
    required this.count,
    required this.spark,
    required this.onGive,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final empty = count <= 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      // minVerticalPadding держит строку не ниже 48dp по ТЗ.
      minVerticalPadding: 8,
      leading: SparkOnAction(
        trigger: spark,
        child: Text(item.emoji, style: const TextStyle(fontSize: 32)),
      ),
      title: Text(
        '${item.title} × $count',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        empty ? 'Закончился — загляни в магазин 🛍️' : item.effectText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: empty ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
      ),
      trailing: ElevatedButton(
        // ТЗ: тач-таргет не меньше 48x48dp.
        style: ElevatedButton.styleFrom(minimumSize: const Size(84, 48)),
        onPressed: onGive,
        child: const Text('Дать'),
      ),
    );
  }
}

/// Строка с результатом последнего действия — вместо снекбара, который
/// прятался за листом.
class _EffectLine extends StatelessWidget {
  final String text;

  const _EffectLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KidsTheme.soft(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
