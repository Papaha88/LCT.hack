import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/skins_data.dart';
import '../models/pet.dart';
import '../services/pet_assets.dart';

/// Питомец «вживую»: модель + эмоции.
///
/// Модель — анимированный WebP из `assets/pets/…` (см. [PetAssets]).
/// Пока файлов нет, рисуется заглушка: круг окраски (или цвета скина),
/// эмодзи вида и значок скина. Эмоции работают с обоими вариантами:
/// - в покое питомец «дышит»;
/// - грустный — поникает и покачивается;
/// - на действие ([reaction] вырос) подпрыгивает, над ним вылетает
///   значок реакции, а модель на время переключается на [reactionAnim].
class PetModel extends StatefulWidget {
  final PetType type;
  final PetVariant variant;
  final PetSkin? skin;
  final int level;
  final double size;
  final PetMood? mood;

  /// Счётчик действий: каждое увеличение — одна реакция.
  final int reaction;
  final PetAnim reactionAnim;

  const PetModel({
    super.key,
    required this.type,
    required this.variant,
    this.skin,
    this.level = 1,
    this.size = 160,
    this.mood,
    this.reaction = 0,
    this.reactionAnim = PetAnim.happy,
  });

  /// Постоянное «дыхание». Тесты выключают его (flutter_test_config.dart):
  /// бесконечная анимация не даёт `pumpAndSettle` дождаться покоя.
  static bool idleMotion = true;

  @override
  State<PetModel> createState() => _PetModelState();
}

class _PetModelState extends State<PetModel> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  /// Реакция целиком: прыжок в первой трети, дальше летит значок.
  /// Когда закончится — модель возвращается к покою.
  late final AnimationController _react = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _reacting = null);
      }
    });

  PetAnim? _reacting;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Системная настройка «убрать анимации» — питомец просто стоит.
    final calm = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (PetModel.idleMotion && !calm) {
      if (!_idle.isAnimating) _idle.repeat(reverse: true);
    } else {
      _idle.stop();
    }
  }

  @override
  void didUpdateWidget(covariant PetModel old) {
    super.didUpdateWidget(old);
    if (widget.reaction > old.reaction) {
      _reacting = widget.reactionAnim;
      _react.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _react.dispose();
    super.dispose();
  }

  PetAnim get _anim {
    if (_reacting != null) return _reacting!;
    if (widget.mood == PetMood.sad) return PetAnim.sad;
    return PetAnim.idle;
  }

  static String _reactionEmoji(PetAnim anim) {
    switch (anim) {
      case PetAnim.eat:
        return '😋';
      case PetAnim.sleep:
        return '💤';
      case PetAnim.sad:
        return '💧';
      case PetAnim.happy:
      case PetAnim.idle:
        return '💛';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final sad = _anim == PetAnim.sad;
    final path = PetAssets.resolve(
      type: widget.type,
      look: widget.skin?.id ?? widget.variant.name,
      anim: _anim,
      level: widget.level,
    );

    final body = path != null
        ? Image.asset(
            path,
            width: s,
            height: s,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _Placeholder(widget: widget),
          )
        : _Placeholder(widget: widget);

    return SizedBox(
      width: s,
      height: s * 1.12,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _react]),
        child: body,
        builder: (context, child) {
          final breathe = Curves.easeInOut.transform(_idle.value);
          final r = _react.value;
          final active = _react.isAnimating;
          // Прыжок в первой трети: вверх и обратно, при посадке — «сплющился».
          final p = (r / 0.35).clamp(0.0, 1.0);
          final jump = active && p < 1 ? math.sin(p * math.pi) : 0.0;
          final squash = active && p > 0.8 && p < 1 ? (1 - p) * 0.4 : 0.0;
          final scaleY = 1 + breathe * 0.025 - squash + jump * 0.04;
          final scaleX = 1 - breathe * 0.01 + squash;
          final tilt = sad ? math.sin(_idle.value * math.pi * 2) * 0.05 : 0.0;
          final droop = sad ? s * 0.04 : 0.0;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Тень: сжимается, когда питомец в прыжке.
              Positioned(
                bottom: 0,
                child: Container(
                  width: s * (0.6 - jump * 0.15),
                  height: s * 0.07,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(s),
                  ),
                ),
              ),
              Positioned(
                bottom: s * 0.03 + jump * s * 0.16 - droop,
                child: Transform.rotate(
                  angle: tilt,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
                    child: child,
                  ),
                ),
              ),
              if (active)
                Positioned(
                  top: s * 0.1 - r * s * 0.3,
                  right: s * 0.12,
                  child: Opacity(
                    opacity: (1 - r).clamp(0.0, 1.0),
                    child: Text(
                      _reactionEmoji(_reacting ?? PetAnim.happy),
                      style: TextStyle(fontSize: s * 0.2),
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

/// Заглушка до появления моделей: круг окраски/скина + эмодзи.
/// Настроение отдельным значком не рисуем — его показывает облачко
/// над питомцем и сама анимация (грусть, прыжок).
class _Placeholder extends StatelessWidget {
  final PetModel widget;

  const _Placeholder({required this.widget});

  @override
  Widget build(BuildContext context) {
    final s = widget.size * 0.92;
    final look = PetLook.of(widget.type, widget.variant);
    final skin = widget.skin;
    final colors =
        skin == null ? [look.bgStart, look.bgEnd] : [skin.bgStart, skin.bgEnd];
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              border: Border.all(color: Colors.white, width: 4),
            ),
            alignment: Alignment.center,
            child: Text(widget.type.emoji,
                style: TextStyle(fontSize: s * 0.5)),
          ),
          if (skin != null)
            Positioned(
              top: 0,
              left: widget.size * 0.06,
              child: _Badge(text: skin.emoji, size: widget.size * 0.26),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;

  const _Badge({required this.text, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
      ),
      child: Text(text, style: TextStyle(fontSize: size * 0.55)),
    );
  }
}
