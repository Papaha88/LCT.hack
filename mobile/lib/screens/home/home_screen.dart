import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/lessons_data.dart';
import '../../data/shop_data.dart';
import '../../models/game_state.dart';
import '../../models/pet.dart';
import '../../models/player_profile.dart';
import '../../services/pet_assets.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/action_spark.dart';
import '../../widgets/day_paper.dart';
import '../../widgets/finny_avatar.dart';
import '../../widgets/kids_button.dart';
import '../../widgets/pet_model.dart';
import '../../widgets/stat_bar.dart';
import '../level_up/level_up_screen.dart';
import '../quests/quests_screen.dart';

/// Главный экран. Сверху — монеты, уровень, день; в центре — питомец
/// с настроением; ниже — цель, следующее задание и смена дня.
///
/// Текста минимум: состояние питомца видно по нему самому (мордочка,
/// фраза, анимация), а подсказка Финни появляется, только когда есть
/// что сказать.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Счётчик реакций питомца: каждое действие — прыжок и «огонёк».
  int _reaction = 0;
  PetAnim _reactionAnim = PetAnim.happy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterFirstFrame());
  }

  Future<void> _afterFirstFrame() async {
    if (!mounted) return;
    final game = GameStateScope.read(context);

    // Первый вход после онбординга — «Секрет игры» (один раз за игру).
    if (game.justFinishedOnboarding) {
      game.justFinishedOnboarding = false;
      final petName = game.pet?.name ?? 'питомец';
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('🤫 Секрет игры'),
          content: Text(
            'Планируй траты и решай задания — будешь получать больше '
            'монет, а $petName вырастет быстрее!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Круто!'),
            ),
          ],
        ),
      );
      return;
    }

    // Бонус за возвращение — плашкой сверху, без диалога.
    game.claimDailyBonusIfNeeded();
  }

  void _react(PetAnim anim) {
    if (!mounted) return;
    setState(() {
      _reaction++;
      _reactionAnim = anim;
    });
  }

  /// Тап по питомцу или по «Рюкзаку» — открыть рюкзачок.
  Future<void> _openBackpack() async {
    final game = GameStateScope.read(context);
    if (game.pet == null) return;
    final lastKind = await showModalBottomSheet<ItemKind>(
      context: context,
      // Лист может занять больше половины экрана.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _InventorySheet(game: game),
    );
    if (!mounted) return;
    // Кормление даёт опыт — питомец мог дорасти до нового уровня.
    await showLevelUpIfNeeded(context);
    if (lastKind != null) {
      _react(lastKind == ItemKind.food ? PetAnim.eat : PetAnim.happy);
    }
  }

  /// «Новый день»: доход и бумажка с итогами, питомец сладко спал.
  Future<void> _nextDay() async {
    final summary = GameStateScope.read(context).nextDay();
    if (!mounted) return;
    await showDayPaper(context, summary);
    _react(PetAnim.sleep);
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final pet = game.pet;
    final scheme = Theme.of(context).colorScheme;

    if (pet == null) {
      return const Center(child: Text('Питомец не найден 😢'));
    }

    final tip = game.finnyTip();
    final lesson = game.nextLesson;
    final retry = lesson != null && game.lessonsRetry.contains(lesson.id);
    final age = game.age;
    final mood = pet.mood;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (game.pendingBonus > 0) ...[
          _BonusBanner(
            amount: game.pendingBonus,
            petName: pet.name,
            onClose: game.dismissBonus,
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                'Привет, ${game.nickname}!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (age != null)
              _Chip(text: '👦 ${PlayerProfile.labelFor(age)}'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _Chip(text: '🪙 ${game.balance}', big: true)),
            const SizedBox(width: 8),
            Expanded(child: _Chip(text: '⭐ Ур. ${pet.level}', big: true)),
            const SizedBox(width: 8),
            Expanded(child: _Chip(text: '📅 ${game.day}', big: true)),
          ],
        ),
        const SizedBox(height: 12),

        // Питомец — главный герой экрана.
        _PetStage(
          pet: pet,
          mood: mood,
          skinLevel: pet.level,
          reaction: _reaction,
          reactionAnim: _reactionAnim,
          onTap: _openBackpack,
        ),
        const SizedBox(height: 12),

        if (tip != null) ...[
          _TipCard(text: tip),
          const SizedBox(height: 12),
        ],

        // Цель копилки — одна строка и полоска.
        _GoalCard(
          emoji: game.goalEmoji,
          name: game.goalName,
          progress: game.goalProgress,
          savings: game.savings,
          target: game.goalTarget,
        ),
        const SizedBox(height: 12),

        if (lesson != null)
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => openLesson(context, lesson),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: lesson.track.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(lesson.emoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            retry
                                ? '🔁 Повтори • +${lesson.reward} 🪙'
                                : '${lesson.track.emoji} +${lesson.reward} 🪙',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        // ТЗ: тач-таргет не меньше 48x48dp.
                        minimumSize: const Size(84, 48),
                        backgroundColor: lesson.track.color,
                      ),
                      onPressed: () => openLesson(context, lesson),
                      child: const Text('Решить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),

        KidsButton(
          text: 'Следующий день',
          icon: Icons.wb_sunny_outlined,
          onPressed: _nextDay,
        ),
        const SizedBox(height: 6),
        Text(
          'Доход за день: +${game.baseIncome} 🪙',
          textAlign: TextAlign.center,
          style: TextStyle(color: KidsTheme.muted(context)),
        ),
      ],
    );
  }
}

/// Сцена питомца: имя, этап, модель с эмоциями, фраза и статы.
class _PetStage extends StatelessWidget {
  final Pet pet;
  final PetMood mood;
  final int skinLevel;
  final int reaction;
  final PetAnim reactionAnim;
  final VoidCallback onTap;

  const _PetStage({
    required this.pet,
    required this.mood,
    required this.skinLevel,
    required this.reaction,
    required this.reactionAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final look = PetLook.of(pet.type, pet.variant);
    final skin = game.skin;
    final tint = skin?.bgEnd ?? look.bgEnd;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tint.withValues(alpha: KidsTheme.isDark(context) ? 0.35 : 0.28),
            Theme.of(context).cardTheme.color ?? scheme.surface,
          ],
        ),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _Chip(text: pet.stage),
            ],
          ),
          const SizedBox(height: 4),
          // Фраза питомца — облачком над головой.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _SpeechBubble(
              key: ValueKey(mood),
              text: '${mood.emoji} ${mood.phrase}',
            ),
          ),
          Semantics(
            button: true,
            label: 'Питомец ${pet.name}. Открыть рюкзак',
            child: GestureDetector(
              onTap: onTap,
              child: SparkOnAction(
                trigger: reaction,
                spread: 56,
                child: PetModel(
                  type: pet.type,
                  variant: pet.variant,
                  skin: skin,
                  level: skinLevel,
                  size: 176,
                  mood: mood,
                  reaction: reaction,
                  reactionAnim: reactionAnim,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatMeter(
                  emoji: '🍎',
                  label: 'Сытость',
                  value: pet.hunger,
                  color: const Color(0xFF66BB6A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatMeter(
                  emoji: '😊',
                  label: 'Счастье',
                  value: pet.happiness,
                  color: const Color(0xFFFFB020),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatMeter(
                  emoji: '🧼',
                  label: 'Чистота',
                  value: pet.cleanliness,
                  color: const Color(0xFF4FC3F7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StatMeter(
            emoji: '✨',
            label: 'Опыт',
            value: pet.xp,
            color: const Color(0xFFAB47BC),
            wide: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onTap,
              icon: const Icon(Icons.backpack_outlined),
              label: const Text('Рюкзак'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: KidsTheme.pill(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 8),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _BonusBanner extends StatelessWidget {
  final int amount;
  final String petName;
  final VoidCallback onClose;

  const _BonusBanner({
    required this.amount,
    required this.petName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC857), Color(0xFFFF9F43)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$petName рад тебя видеть! +$amount 🪙',
              style: const TextStyle(
                color: Color(0xFF4A2A00),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Закрыть',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Color(0xFF4A2A00)),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;

  const _TipCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: KidsTheme.soft(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const FinnyAvatar(size: 40, waving: false),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String emoji;
  final String name;
  final double progress;
  final int savings;
  final int target;

  const _GoalCard({
    required this.emoji,
    required this.name,
    required this.progress,
    required this.savings,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '$savings / $target',
                        style: TextStyle(color: KidsTheme.muted(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Плашка «🪙 60», «⭐ Ур. 2»: цвет — из темы, чтобы в тёмной не белеть.
class _Chip extends StatelessWidget {
  final String text;
  final bool big;

  const _Chip({required this.text, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: big ? 10 : 6),
      alignment: big ? Alignment.center : null,
      decoration: BoxDecoration(
        color: KidsTheme.pill(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
/// Закрывается с отделом последнего предмета — по нему питомец реагирует.
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
  ItemKind? _lastKind;
  String? _lastEffect;

  void _give(ShopItem item) {
    final effect = widget.game.useItem(item.id);
    if (effect == null) return;
    setState(() {
      _lastKind = item.kind;
      _sparks[item.id] = (_sparks[item.id] ?? 0) + 1;
      _lastEffect = effect;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
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
              onPressed: () => Navigator.of(context).pop(_lastKind),
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
