import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Финни-помощник: котик с золотой монеткой (картинка
/// `assets/images/finny.jpg`, та же, что на иконке приложения).
///
/// Круглая аватарка с золотой рамкой. В режиме [waving] Финни
/// легонько покачивается — по умолчанию выключено: качание отвлекало.
class FinnyAvatar extends StatefulWidget {
  final double size;
  final bool waving;

  const FinnyAvatar({super.key, this.size = 120, this.waving = false});

  static const String asset = 'assets/images/finny.jpg';

  @override
  State<FinnyAvatar> createState() => _FinnyAvatarState();
}

class _FinnyAvatarState extends State<FinnyAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.waving) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant FinnyAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.waving && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.waving && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final ring = math.max(2.0, s * 0.04);
    final avatar = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD66B), Color(0xFFF5A623)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A623).withValues(alpha: 0.35),
            blurRadius: s * 0.12,
            offset: Offset(0, s * 0.04),
          ),
        ],
      ),
      padding: EdgeInsets.all(ring),
      child: ClipOval(
        child: Image.asset(
          FinnyAvatar.asset,
          fit: BoxFit.cover,
          // Картинка крупнее, чем нужно на экране: декодируем
          // под реальный размер, чтобы не тратить память.
          cacheWidth: (s * 3).round(),
          semanticLabel: 'Финни',
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFFFB347),
            alignment: Alignment.center,
            child: Text('🐱', style: TextStyle(fontSize: s * 0.5)),
          ),
        ),
      ),
    );

    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _controller,
        child: avatar,
        builder: (context, child) {
          final t = _controller.value * math.pi * 2;
          final tilt = widget.waving ? math.sin(t) * 0.08 : 0.0;
          final hop = widget.waving ? -math.sin(t * 2).abs() * s * 0.04 : 0.0;
          return Transform.translate(
            offset: Offset(0, hop),
            child: Transform.rotate(angle: tilt, child: child),
          );
        },
      ),
    );
  }
}
