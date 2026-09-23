import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Финни-помощник: пингвинчик, нарисованный кодом (без картинок).
/// Правое крыло машет благодаря AnimationController.
class FinnyAvatar extends StatefulWidget {
  final double size;
  final bool waving;

  const FinnyAvatar({super.key, this.size = 120, this.waving = true});

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
      duration: const Duration(milliseconds: 600),
    );
    if (widget.waving) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant FinnyAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.waving && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.waving && _controller.isAnimating) {
      _controller.stop();
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
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final wave = widget.waving
              ? math.sin(_controller.value * math.pi * 2) * 0.45
              : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Тело
              Container(
                width: s * 0.72,
                height: s * 0.86,
                decoration: BoxDecoration(
                  color: const Color(0xFF33415C),
                  borderRadius: BorderRadius.circular(s * 0.36),
                ),
              ),
              // Животик
              Positioned(
                bottom: s * 0.10,
                child: Container(
                  width: s * 0.46,
                  height: s * 0.52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(s * 0.23),
                  ),
                ),
              ),
              // Левое крыло (спокойное)
              Positioned(
                left: s * 0.08,
                top: s * 0.34,
                child: Transform.rotate(
                  angle: 0.25,
                  child: Container(
                    width: s * 0.13,
                    height: s * 0.34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25304A),
                      borderRadius: BorderRadius.circular(s * 0.07),
                    ),
                  ),
                ),
              ),
              // Правое крыло (машет!)
              Positioned(
                right: s * 0.02,
                top: s * 0.16,
                child: Transform.rotate(
                  angle: -0.7 + wave,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: s * 0.13,
                    height: s * 0.36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25304A),
                      borderRadius: BorderRadius.circular(s * 0.07),
                    ),
                  ),
                ),
              ),
              // Глаза
              Positioned(
                top: s * 0.24,
                child: Row(
                  children: [
                    _eye(s),
                    SizedBox(width: s * 0.08),
                    _eye(s),
                  ],
                ),
              ),
              // Клюв
              Positioned(
                top: s * 0.40,
                child: CustomPaint(
                  size: Size(s * 0.16, s * 0.12),
                  painter: _BeakPainter(),
                ),
              ),
              // Ножки
              Positioned(
                bottom: 0,
                child: Row(
                  children: [
                    _foot(s),
                    SizedBox(width: s * 0.10),
                    _foot(s),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _eye(double s) => Container(
        width: s * 0.13,
        height: s * 0.16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(s * 0.07),
        ),
        child: Center(
          child: Container(
            width: s * 0.06,
            height: s * 0.08,
            decoration: const BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );

  Widget _foot(double s) => Container(
        width: s * 0.16,
        height: s * 0.07,
        decoration: BoxDecoration(
          color: const Color(0xFFFFB020),
          borderRadius: BorderRadius.circular(s * 0.035),
        ),
      );
}

class _BeakPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFB020);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
