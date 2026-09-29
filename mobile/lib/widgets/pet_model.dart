import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../pet/pet_view.dart';
import '../services/pet_assets.dart';

/// Реакция питомца на действие — какой значок вылетит над ним.
enum PetReaction { happy, eat, sleep }

/// Питомец: модель нужного вида, окраски, возраста и эмоции.
///
/// - [animated] — живой ролик (`PetView`). Только для главного экрана:
///   ролики тяжёлые, а смотреть их нужно там, где питомец «живёт».
/// - иначе — постер (png) той же модели: онбординг, магазин, экран уровня.
/// - нет модели для этого вида — заглушка (круг окраски и эмодзи).
///
/// Возраст выбирается по [level] (см. [Pet.stageOf]), эмоция —
/// по [emotion]. На действие ([reaction] вырос) питомец подпрыгивает,
/// над ним вылетает значок, а живой ролик один раз играет «радость».
class PetModel extends StatefulWidget {
  final PetType type;
  final PetVariant variant;
  final int level;
  final double size;
  final PetEmotion emotion;
  final bool animated;

  /// Счётчик действий: каждое увеличение — одна реакция.
  final int reaction;
  final PetReaction reactionKind;

  const PetModel({
    super.key,
    required this.type,
    required this.variant,
    this.level = 1,
    this.size = 160,
    this.emotion = PetEmotion.normal,
    this.animated = false,
    this.reaction = 0,
    this.reactionKind = PetReaction.happy,
  });

  /// Живые ролики. Тесты выключают их (flutter_test_config.dart):
  /// бесконечная анимация не даёт `pumpAndSettle` дождаться покоя.
  static bool liveVideo = true;

  @override
  State<PetModel> createState() => _PetModelState();
}

class _PetModelState extends State<PetModel>
    with SingleTickerProviderStateMixin {
  /// Прыжок в первой трети, дальше летит значок реакции.
  late final AnimationController _react = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final PetController _video =
      PetController(idleState: PetAssets.clipFor(widget.emotion));

  @override
  void didUpdateWidget(covariant PetModel old) {
    super.didUpdateWidget(old);
    if (widget.emotion != old.emotion) {
      _video.loop(PetAssets.clipFor(widget.emotion));
    }
    if (widget.reaction > old.reaction) {
      _react.forward(from: 0);
      if (widget.reactionKind != PetReaction.sleep) {
        _video.playOnce('happy', immediate: true);
      }
    }
  }

  @override
  void dispose() {
    _video.dispose();
    _react.dispose();
    super.dispose();
  }

  static String _reactionEmoji(PetReaction kind) {
    switch (kind) {
      case PetReaction.eat:
        return '😋';
      case PetReaction.sleep:
        return '💤';
      case PetReaction.happy:
        return '💛';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final placeholder = _Placeholder(widget: widget);
    final folder =
        PetAssets.modelFolder(widget.type, widget.variant, widget.level);
    final poster = PetAssets.poster(
      widget.type,
      widget.variant,
      level: widget.level,
      emotion: widget.emotion,
    );

    final Widget body;
    if (widget.animated && PetModel.liveVideo && folder != null) {
      body = SizedBox(
        width: s,
        height: s,
        child: PetView(
          // Новый возраст или окраска — новая модель с чистого листа.
          key: ValueKey(folder),
          basePath: folder,
          controller: _video,
          placeholder: poster == null
              ? placeholder
              : Image.asset(poster, width: s, height: s),
        ),
      );
    } else if (poster != null) {
      body = Image.asset(
        poster,
        width: s,
        height: s,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else {
      body = placeholder;
    }

    return SizedBox(
      width: s,
      height: s * 1.08,
      child: AnimatedBuilder(
        animation: _react,
        child: body,
        builder: (context, child) {
          final r = _react.value;
          final active = _react.isAnimating;
          // Прыжок: вверх и обратно, при посадке — чуть «сплющился».
          final p = (r / 0.35).clamp(0.0, 1.0);
          final jump = active && p < 1 ? math.sin(p * math.pi) : 0.0;
          final squash = active && p > 0.8 && p < 1 ? (1 - p) * 0.4 : 0.0;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: jump * s * 0.12,
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.diagonal3Values(
                    1 + squash,
                    1 - squash + jump * 0.03,
                    1,
                  ),
                  child: child,
                ),
              ),
              if (active)
                Positioned(
                  top: s * 0.1 - r * s * 0.3,
                  right: s * 0.1,
                  child: Opacity(
                    opacity: (1 - r).clamp(0.0, 1.0),
                    child: Text(
                      _reactionEmoji(widget.reactionKind),
                      style: TextStyle(fontSize: s * 0.18),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Заглушка, пока для этого вида нет модели: круг окраски + эмодзи.
class _Placeholder extends StatelessWidget {
  final PetModel widget;

  const _Placeholder({required this.widget});

  @override
  Widget build(BuildContext context) {
    final s = widget.size * 0.9;
    final look = PetLook.of(widget.type, widget.variant);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: Container(
          width: s,
          height: s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [look.bgStart, look.bgEnd],
            ),
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Text(widget.type.emoji, style: TextStyle(fontSize: s * 0.5)),
        ),
      ),
    );
  }
}
