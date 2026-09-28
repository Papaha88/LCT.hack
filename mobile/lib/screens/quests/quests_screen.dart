import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/lessons_data.dart';
import '../../models/game_state.dart';
import '../../models/player_profile.dart';
import '../../theme/kids_theme.dart';
import '../level_up/level_up_screen.dart';
import 'lesson_screen.dart';

/// Задания — две интерактивные дороги: «Математика» и «Финансы».
///
/// Дорога вьётся сверху вниз, на ней — кружки-задания, сгруппированные
/// по классам. Класс по возрасту подсвечен «Твой уровень», но открыты
/// все задания: можно идти вперёд или вернуться назад.
class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  LessonTrack _track = LessonTrack.finance;

  Future<void> _open(Lesson lesson) async {
    await openLesson(context, lesson);
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final age = game.age;
    final recommended = recommendedGrade(age, _track);
    final retry = lessonsOf(_track)
        .where((l) => game.lessonsRetry.contains(l.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: LessonTrack.values
              .map(
                (t) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: t == LessonTrack.values.first ? 6 : 0,
                      left: t == LessonTrack.values.first ? 0 : 6,
                    ),
                    child: _TrackTab(
                      track: t,
                      solved: game.solvedOn(t),
                      total: lessonsOf(t).length,
                      selected: _track == t,
                      onTap: () => setState(() => _track = t),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _AdviceCard(
          text: age == null
              ? 'Начни с 1 класса. Открыто всё!'
              : 'Для ${PlayerProfile.labelFor(age)} — $recommended класс ⭐. '
                  'Открыто всё!',
        ),
        if (retry.isNotEmpty) ...[
          const SizedBox(height: 10),
          _RetryCard(lessons: retry, onOpen: _open),
        ],
        const SizedBox(height: 8),
        ...gradesOf(_track).map(
          (grade) => _GradeSection(
            key: ValueKey('${_track.name}_$grade'),
            track: _track,
            grade: grade,
            recommended: grade == recommended,
            game: game,
            onOpen: _open,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            game.solvedOn(_track) == lessonsOf(_track).length
                ? '🏆 Дорога пройдена! Ты настоящий мастер!'
                : '🏁 Финиш дороги',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Открыть задание и после него показать рост питомца, если был.
Future<void> openLesson(BuildContext context, Lesson lesson) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)),
  );
  if (context.mounted) await showLevelUpIfNeeded(context);
}

class _TrackTab extends StatelessWidget {
  final LessonTrack track;
  final int solved;
  final int total;
  final bool selected;
  final VoidCallback onTap;

  const _TrackTab({
    required this.track,
    required this.solved,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = track.color;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : KidsTheme.pill(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : scheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(track.emoji, style: const TextStyle(fontSize: 28)),
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : scheme.onSurface,
                ),
              ),
              Text(
                '$solved из $total',
                style: TextStyle(
                  color: selected ? Colors.white : KidsTheme.muted(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final String text;

  const _AdviceCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: KidsTheme.soft(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text('🐱 $text', style: const TextStyle(height: 1.3)),
    );
  }
}

/// Временные задачи «Повтори» — появляются после ошибки.
class _RetryCard extends StatelessWidget {
  final List<Lesson> lessons;
  final Future<void> Function(Lesson) onOpen;

  const _RetryCard({required this.lessons, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔁 Повтори',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lessons
                  .map(
                    (l) => ActionChip(
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      avatar: Text(l.emoji),
                      label: Text(l.title),
                      onPressed: () => onOpen(l),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Кусок дороги одного класса: заголовок и извилистая тропинка с кружками.
class _GradeSection extends StatelessWidget {
  final LessonTrack track;
  final int grade;
  final bool recommended;
  final GameState game;
  final Future<void> Function(Lesson) onOpen;

  const _GradeSection({
    super.key,
    required this.track,
    required this.grade,
    required this.recommended,
    required this.game,
    required this.onOpen,
  });

  static const double _step = 96;
  static const double _node = 68;

  /// Кружок идёт змейкой в левой части: справа остаётся место для подписи.
  static double _xFraction(int i) => 0.24 + 0.12 * math.sin(i * 1.4);

  @override
  Widget build(BuildContext context) {
    final lessons =
        lessonsOf(track).where((l) => l.grade == grade).toList();
    final solved = lessons.where((l) => game.lessonsSolved.contains(l.id));
    final next = game.nextLesson;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: track.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: recommended ? track.color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$grade класс • ${solved.length}/${lessons.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      track.sectionTitle(grade),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (recommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: track.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '⭐ Твой уровень',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final centers = [
              for (var i = 0; i < lessons.length; i++)
                Offset(width * _xFraction(i + grade),
                    _step * i + _step / 2 + 4),
            ];
            final done = [
              for (final l in lessons) game.lessonsSolved.contains(l.id),
            ];
            return SizedBox(
              height: _step * lessons.length + 8,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RoadPainter(
                        centers: centers,
                        done: done,
                        color: track.color,
                        base: KidsTheme.soft(context),
                      ),
                    ),
                  ),
                  for (var i = 0; i < lessons.length; i++)
                    Positioned(
                      left: centers[i].dx - _node / 2,
                      right: 0,
                      top: centers[i].dy - _node / 2,
                      height: _node,
                      child: _LessonNode(
                        lesson: lessons[i],
                        solved: done[i],
                        retry: game.lessonsRetry.contains(lessons[i].id),
                        isNext: next?.id == lessons[i].id,
                        size: _node,
                        onTap: () => onOpen(lessons[i]),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LessonNode extends StatelessWidget {
  final Lesson lesson;
  final bool solved;
  final bool retry;
  final bool isNext;
  final double size;
  final VoidCallback onTap;

  const _LessonNode({
    required this.lesson,
    required this.solved,
    required this.retry,
    required this.isNext,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = lesson.track.color;
    final String status;
    if (solved) {
      status = 'Решено ✅';
    } else if (retry) {
      status = 'Повтори 🔁 +${lesson.reward} 🪙';
    } else {
      status = '+${lesson.reward} 🪙';
    }

    return Semantics(
      button: true,
      label: '${lesson.title}. $status',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Row(
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: solved ? color : KidsTheme.pill(context),
                      border: Border.all(
                        color: retry ? KidsTheme.warning : color,
                        width: isNext || retry ? 5 : 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: isNext ? 14 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(lesson.emoji,
                        style: const TextStyle(fontSize: 30)),
                  ),
                  if (solved)
                    const Positioned(
                      right: -2,
                      bottom: -2,
                      child: _Mark(
                        icon: Icons.check,
                        color: KidsTheme.success,
                      ),
                    )
                  else if (retry)
                    const Positioned(
                      right: -2,
                      bottom: -2,
                      child: _Mark(
                        icon: Icons.refresh,
                        color: KidsTheme.warning,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  Text(
                    isNext && !retry ? '📍 Иди сюда! $status' : status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant),
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

class _Mark extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _Mark({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}

/// Дорога: широкая мягкая лента через центры кружков, пройденная часть —
/// цветом дороги, поверх — пунктир «разметки».
class _RoadPainter extends CustomPainter {
  final List<Offset> centers;
  final List<bool> done;
  final Color color;
  final Color base;

  _RoadPainter({
    required this.centers,
    required this.done,
    required this.color,
    required this.base,
  });

  Path _segment(Offset a, Offset b) {
    final midY = (a.dy + b.dy) / 2;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.isEmpty) return;
    final road = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.9);

    // Дорога заходит в раздел сверху и уходит вниз — разделы стыкуются.
    final top = Offset(centers.first.dx, 0);
    final bottom = Offset(centers.last.dx, size.height);
    final points = [top, ...centers, bottom];

    for (var i = 0; i < points.length - 1; i++) {
      final segment = _segment(points[i], points[i + 1]);
      // Отрезок пройден, если решены оба кружка по его краям.
      final from = i - 1;
      final to = i;
      final passed = from >= 0 &&
          to < done.length &&
          done[from] &&
          done[to];
      road.color = passed ? color.withValues(alpha: 0.75) : base;
      canvas.drawPath(segment, road);

      for (final metric in segment.computeMetrics()) {
        var d = 0.0;
        while (d < metric.length) {
          canvas.drawPath(metric.extractPath(d, d + 8), dash);
          d += 16;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) =>
      old.color != color ||
      old.base != base ||
      old.centers.length != centers.length ||
      !_sameList(old.done, done) ||
      !_sameOffsets(old.centers, centers);

  static bool _sameList(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _sameOffsets(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
