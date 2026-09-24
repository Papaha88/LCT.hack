import 'dart:math' as math;

import 'package:flutter/material.dart';

/// «Огонёк» — короткая вспышка с искрами, которая проигрывается,
/// когда ребёнок что-то сделал: покормил питомца, купил предмет,
/// выполнил задание, положил монетки в копилку.
///
/// Рисуется кодом, без картинок и сторонних пакетов — как Финни.
/// Вспышка короткая (700 мс): ТЗ требует отклик на действие до 1 секунды.
///
/// Как пользоваться: обернуть то, рядом с чем должен вспыхнуть огонёк,
/// и увеличивать [trigger] на каждое действие.
///
/// ```dart
/// SparkOnAction(trigger: _sparks[item.id] ?? 0, child: Text(item.emoji))
/// ```
class SparkOnAction extends StatefulWidget {
  const SparkOnAction({
    super.key,
    required this.child,
    required this.trigger,
    this.spread = 26,
    this.color = const Color(0xFFFFB020),
  });

  final Widget child;

  /// 0 — огонёк ещё не играл. Вспышка запускается, когда значение растёт
  /// (счётчик: `_sparks[id] = (_sparks[id] ?? 0) + 1`) либо когда флаг
  /// переключается с 0 на 1 — обратный переход огонёк не запускает.
  final int trigger;

  /// Размер огонька и разлёт искр, в dp.
  final double spread;

  /// Основной цвет пламени.
  final Color color;

  @override
  State<SparkOnAction> createState() => _SparkOnActionState();
}

class _SparkOnActionState extends State<SparkOnAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..addStatusListener(_onStatus);

  bool _playing = false;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _playing = false);
    }
  }

  @override
  void didUpdateWidget(covariant SparkOnAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger > oldWidget.trigger) {
      setState(() => _playing = true);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      // Искры разлетаются за границы ребёнка — обрезать их нельзя.
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        if (_playing)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _SparkPainter(
                    progress: _controller.value,
                    spread: widget.spread,
                    color: widget.color,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Вспышка: расходящееся кольцо, восемь искр и огонёк в центре.
class _SparkPainter extends CustomPainter {
  const _SparkPainter({
    required this.progress,
    required this.spread,
    required this.color,
  });

  final double progress;
  final double spread;
  final Color color;

  /// Направления искр заданы заранее: вспышка выглядит одинаково при
  /// каждом действии, а не мерцает случайными углами при перерисовке.
  static const List<double> _directions = [
    -1.57,
    -0.79,
    0.0,
    0.79,
    1.57,
    2.36,
    3.14,
    3.93,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double fade = (1 - progress).clamp(0.0, 1.0).toDouble();
    if (fade <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOutCubic.transform(progress);

    // 1. Расходящееся кольцо.
    canvas.drawCircle(
      center,
      spread * (0.35 + 0.75 * eased),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * fade
        ..color = color.withValues(alpha: 0.55 * fade),
    );

    // 2. Искры разлетаются в стороны и гаснут.
    for (var i = 0; i < _directions.length; i++) {
      final angle = _directions[i];
      final distance = spread * (0.3 + 0.8 * eased);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(
        point,
        (1 - eased * 0.5) * 3.2,
        Paint()
          ..color = (i.isEven ? color : Colors.white)
              .withValues(alpha: 0.9 * fade),
      );
    }

    // 3. Огонёк в центре: вспыхивает на середине вспышки и гаснет.
    final double pop =
        math.sin(math.pi * progress).clamp(0.0, 1.0).toDouble();
    if (pop > 0) _drawFlame(canvas, center, pop, fade);
  }

  void _drawFlame(Canvas canvas, Offset center, double pop, double fade) {
    final height = spread * 1.5 * pop;
    final width = spread * 0.8 * pop;
    final top = center.dy - height * 0.62;
    final bottom = center.dy + height * 0.38;

    canvas.drawPath(
      _flamePath(center, width, height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.95 * fade),
            const Color(0xFFFF6D2B).withValues(alpha: 0.85 * fade),
          ],
        ).createShader(
          Rect.fromLTRB(
            center.dx - width,
            top,
            center.dx + width,
            bottom,
          ),
        ),
    );

    // Светящаяся серединка — чтобы огонёк читался как огонь, а не пятно.
    canvas.drawPath(
      _flamePath(center, width * 0.45, height * 0.55),
      Paint()..color = Colors.white.withValues(alpha: 0.85 * fade),
    );
  }

  /// Каплевидное пламя: острие сверху, округлое основание снизу.
  Path _flamePath(Offset center, double width, double height) {
    final top = center.dy - height * 0.62;
    final bottom = center.dy + height * 0.38;
    final waist = center.dy - height * 0.06;
    return Path()
      ..moveTo(center.dx, top)
      ..quadraticBezierTo(
          center.dx + width * 0.55, waist, center.dx + width * 0.34,
          center.dy + height * 0.16)
      ..quadraticBezierTo(
          center.dx + width * 0.18, bottom, center.dx, bottom)
      ..quadraticBezierTo(
          center.dx - width * 0.18, bottom, center.dx - width * 0.34,
          center.dy + height * 0.16)
      ..quadraticBezierTo(center.dx - width * 0.55, waist, center.dx, top)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.spread != spread ||
      oldDelegate.color != color;
}
