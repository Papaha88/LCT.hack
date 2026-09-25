import 'package:flutter/material.dart';

import '../models/game_state.dart';
import 'kids_button.dart';

/// «Бумажка» с итогами дня — показывается при переходе к новому периоду.
///
/// Диалогом, а не отдельным экраном: новый день наступает часто, занимать
/// весь экран каждый раз нельзя. Но выглядит она как записка, на которой
/// посчитано, что случилось за день: приход, расход, что осталось.
Future<void> showDayPaper(BuildContext context, DaySummary summary) {
  return showDialog<void>(
    context: context,
    builder: (_) => DayPaper(summary: summary),
  );
}

/// Записка с подсчётом дня: бумага, пунктир и точечные лидеры, как в чеке.
///
/// Бумага светлая и в тёмной теме — она читается как настоящий листок
/// в руках, а не как часть интерфейса. Поэтому цвета здесь свои, а не из темы.
class DayPaper extends StatelessWidget {
  static const Color paper = Color(0xFFFDFBF3);
  static const Color ink = Color(0xFF2B2A33);
  static const Color inkSoft = Color(0xFF6E6B7B);
  static const Color inkFaint = Color(0xFFC9C4B4);
  static const Color plus = Color(0xFF2E7D32);
  static const Color minus = Color(0xFFB24A2F);

  final DaySummary summary;

  const DayPaper({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: PhysicalShape(
          clipper: const _TornPaperClipper(),
          color: paper,
          elevation: 12,
          shadowColor: Colors.black45,
          child: SingleChildScrollView(
            // Снизу запас под зубцы — иначе кнопка прилипнет к рваному краю.
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '☀️ День ${summary.day}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const Text(
                  'Итоги дня',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: inkSoft),
                ),
                const SizedBox(height: 10),
                const _DashedLine(),
                const SizedBox(height: 6),
                _row('🪙', 'Доход за день', '+${summary.income}', plus),
                _lostRow('🍎', 'Сытость', summary.hungerLost),
                _lostRow('😊', 'Счастье', summary.happinessLost),
                _lostRow('🧼', 'Чистота', summary.cleanlinessLost),
                const SizedBox(height: 6),
                const _DashedLine(),
                const SizedBox(height: 6),
                _row('💰', 'В кошельке', '${summary.balance}', ink),
                _row('🐷', 'В копилке', '${summary.savings}', ink),
                _row('🎯', 'Осталось до цели', '${summary.goalLeft}', ink),
                const SizedBox(height: 8),
                const _DashedLine(doubleLine: true),
                const SizedBox(height: 12),
                Text(
                  'Копим на «${summary.goalName}» 🎯',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, color: inkSoft),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Не забудь покормить питомца! 🐾',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: inkSoft),
                ),
                const SizedBox(height: 16),
                KidsButton(
                  text: 'Играем дальше!',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Строка с точечным лидером: подпись слева, цифра прижата вправо.
  Widget _row(String emoji, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            // Подпись занимает не больше 60% строки, остальное — точки.
            // Без этого цифра не прижимается к краю, как в чеке.
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: ink),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: _DotsLine()),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Просадка за день. Ноль показываем прочерком: «−0» выглядит как ошибка.
  Widget _lostRow(String emoji, String label, int lost) {
    return _row(emoji, label, lost == 0 ? '—' : '−$lost', minus);
  }
}

/// Точечный лидер в строке, как в чеке.
class _DotsLine extends StatelessWidget {
  const _DotsLine();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _DashPainter(dash: 1.6, gap: 4.4),
      child: SizedBox(height: 18),
    );
  }
}

/// Пунктирная линия. [doubleLine] — двойная, как итоговая черта в чеке.
class _DashedLine extends StatelessWidget {
  final bool doubleLine;

  const _DashedLine({this.doubleLine = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CustomPaint(
          painter: _DashPainter(dash: 6, gap: 5),
          child: SizedBox(height: 4),
        ),
        if (doubleLine)
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: CustomPaint(
              painter: _DashPainter(dash: 6, gap: 5),
              child: SizedBox(height: 4),
            ),
          ),
      ],
    );
  }
}

/// Рисует пунктир: и точки-лидеры в строках, и линии-разделители.
/// Толщина и цвет общие, меняются только шаг и промежуток.
class _DashPainter extends CustomPainter {
  const _DashPainter({this.dash = 6, this.gap = 5});

  static const double _thickness = 2;
  static const Color _color = DayPaper.inkFaint;

  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _color
      ..strokeWidth = _thickness
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      final end = x + dash > size.width ? size.width : x + dash;
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) =>
      oldDelegate.dash != dash || oldDelegate.gap != gap;
}

/// Низ бумажки — рваный край: зубцы, как у оторванного чека.
class _TornPaperClipper extends CustomClipper<Path> {
  const _TornPaperClipper();

  /// Высота зубца и радиус верхних углов.
  static const double _tooth = 12;
  static const double _radius = 18;

  @override
  Path getClip(Size size) {
    final bottom = size.height - _tooth;
    final path = Path()
      ..moveTo(0, _radius)
      ..quadraticBezierTo(0, 0, _radius, 0)
      ..lineTo(size.width - _radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, _radius)
      ..lineTo(size.width, bottom);

    final teeth = (size.width / (_tooth * 2)).floor().clamp(1, 200);
    final step = size.width / teeth;
    for (var i = 0; i < teeth; i++) {
      final right = size.width - step * i;
      path.lineTo(right - step / 2, bottom - _tooth);
      path.lineTo(right - step, bottom);
    }

    return path
      ..lineTo(0, _radius)
      ..close();
  }

  @override
  bool shouldReclip(_TornPaperClipper oldDelegate) => false;
}
