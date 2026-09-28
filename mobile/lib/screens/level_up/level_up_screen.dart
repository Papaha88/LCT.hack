import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/game_state.dart';
import '../../models/pet.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/action_spark.dart';
import '../../widgets/kids_button.dart';
import '../../widgets/pet_model.dart';

/// Показывает экран нового уровня, если питомец только что вырос.
///
/// Вызывать после действия, которое даёт опыт: покормил питомца, отложил
/// монетки в копилку, выполнил задание. Возвращает true, если экран показали:
/// тогда вызывающему стоит промолчать с обычной подсказкой, чтобы она
/// не висела поверх праздника.
Future<bool> showLevelUpIfNeeded(BuildContext context) async {
  if (!context.mounted) return false;
  final game = GameStateScope.read(context);
  final event = game.consumeLevelUp();
  final pet = game.pet;
  if (event == null || pet == null || !context.mounted) return false;

  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => LevelUpScreen(event: event, pet: pet),
    ),
  );
  return true;
}

/// Праздничный экран роста: питомец вырастает на глазах и показывает,
/// что дал новый уровень.
class LevelUpScreen extends StatefulWidget {
  final LevelUpEvent event;
  final Pet pet;

  const LevelUpScreen({super.key, required this.event, required this.pet});

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  /// Огонёк запускаем после первого кадра: на самой первой отрисовке виджет
  /// ещё не знает, что «действие произошло», и вспышку пропустит.
  int _sparkTrigger = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _sparkTrigger = 1);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Элемент появляется с задержкой. Место он занимает сразу, поэтому
  /// вёрстка не «прыгает»: элемент проявляется на месте и чуть поднимается.
  Widget _appear({required double from, required Widget child}) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        from.clamp(0.0, 1.0),
        (from + 0.3).clamp(0.0, 1.0),
        curve: Curves.easeOut,
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, inner) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * 16),
          child: inner,
        ),
      ),
      child: child,
    );
  }

  /// Питомец вырастает на глазах, вокруг вспыхивает огонёк.
  Widget _growingPet() {
    final grow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.5, curve: Curves.elasticOut),
    );
    return AnimatedBuilder(
      animation: grow,
      builder: (context, child) =>
          Transform.scale(scale: 0.4 + grow.value * 0.6, child: child),
      child: SparkOnAction(
        trigger: _sparkTrigger,
        spread: 96,
        child: PetModel(
          type: widget.pet.type,
          variant: widget.pet.variant,
          skin: GameStateScope.read(context).skin,
          level: widget.event.toLevel,
          size: 150,
          reaction: 1,
        ),
      ),
    );
  }

  /// Смена этапа взросления — самый заметный результат роста.
  Widget _stageBadge() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: KidsTheme.soft(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary, width: 2),
      ),
      child: Text(
        '${widget.pet.name} вырос: ${widget.event.stageTo}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  /// Что дал новый уровень. Всё подписано словами, а не только цветом (ТЗ).
  Widget _rewardsCard() {
    final event = widget.event;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🎁 Что дал новый уровень',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _RewardRow(
              emoji: '🪙',
              label: 'Монетки в кошелёк',
              value: '+${event.coins}',
            ),
            // Словами, а не стрелкой: символа «→» нет в Roboto.
            _RewardRow(
              emoji: '📈',
              label: 'Доход за день вырос',
              value: '+${event.incomeTo - event.incomeFrom}',
            ),
            const _RewardRow(
              emoji: '💛',
              label: 'Питомец полон сил',
              value: '100/100',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        // Малыш невысокий: если экран высокий, содержимое стоит по центру,
        // а не прилипает к верхнему краю.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _growingPet(),
                  const SizedBox(height: 4),
                  _appear(
                    from: 0.3,
                    child: Text(
                      'НОВЫЙ УРОВЕНЬ!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _appear(
                    from: 0.38,
                    child: Text(
                      'Уровень ${event.toLevel}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (event.levelsGained > 1) ...[
                    const SizedBox(height: 4),
                    _appear(
                      from: 0.44,
                      child: Text(
                        '+${event.levelsGained} уровня подряд!',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  if (event.stageChanged) ...[
                    const SizedBox(height: 12),
                    _appear(from: 0.52, child: _stageBadge()),
                  ],
                  const SizedBox(height: 20),
                  _appear(from: 0.6, child: _rewardsCard()),
                  const SizedBox(height: 20),
                  _appear(
                    from: 0.75,
                    child: KidsButton(
                      text: 'Играем дальше! 🚀',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _RewardRow({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          // Flexible + обрезка: длинная подпись не выдавит цифру за карточку.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
