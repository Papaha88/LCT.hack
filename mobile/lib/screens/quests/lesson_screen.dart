import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/lessons_data.dart';
import '../../models/game_state.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/action_spark.dart';
import '../../widgets/finny_avatar.dart';
import '../../widgets/finny_bubble.dart';
import '../../widgets/kids_button.dart';

/// Одно задание с дороги: ситуация, четыре варианта ответа кнопками,
/// после ответа — разбор и справка.
///
/// Ошибка не отнимает монет и прогресса: неверный вариант гаснет,
/// Финни подсказывает правило, и можно попробовать ещё раз.
class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  /// Варианты, которые уже выбирали и которые оказались неверными.
  final Set<int> _wrong = {};

  /// Выбранный верный вариант — задание решено.
  int? _right;
  LessonResult? _result;
  int _spark = 0;

  void _choose(int index) {
    if (_right != null || _wrong.contains(index)) return;
    final result =
        GameStateScope.read(context).answerLesson(widget.lesson.id, index);
    setState(() {
      _result = result;
      if (result.correct) {
        _right = index;
        _spark++;
      } else {
        _wrong.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final game = GameStateScope.of(context);
    final solvedBefore =
        game.lessonsSolved.contains(lesson.id) && _result == null;
    final scheme = Theme.of(context).colorScheme;
    final color = lesson.track.color;

    return Scaffold(
      appBar: AppBar(
        title: Text('${lesson.track.emoji} ${lesson.grade} класс'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                SparkOnAction(
                  trigger: _spark,
                  spread: 40,
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 3),
                    ),
                    child: Text(lesson.emoji,
                        style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        solvedBefore
                            ? 'Уже решено — можно повторить'
                            : 'Награда: +${lesson.reward} 🪙 и +$lessonXp ✨',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: FinnyAvatar(size: 52, waving: false),
                ),
                const SizedBox(width: 8),
                Expanded(child: FinnyBubble(text: lesson.question)),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < lesson.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionButton(
                  text: lesson.options[i],
                  state: _right == i
                      ? _OptionState.right
                      : _wrong.contains(i)
                          ? _OptionState.wrong
                          : _OptionState.idle,
                  locked: _right != null,
                  color: color,
                  onTap: () => _choose(i),
                ),
              ),
            if (_result != null) ...[
              const SizedBox(height: 6),
              _ResultPanel(lesson: lesson, result: _result!),
            ],
            const SizedBox(height: 16),
            if (_right != null)
              KidsButton(
                text: 'Дальше по дороге',
                icon: Icons.arrow_forward,
                backgroundColor: color,
                onPressed: () => Navigator.of(context).pop(),
              )
            else
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('Вернуться к дороге'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _OptionState { idle, right, wrong }

class _OptionButton extends StatelessWidget {
  final String text;
  final _OptionState state;
  final bool locked;
  final Color color;
  final VoidCallback onTap;

  const _OptionButton({
    required this.text,
    required this.state,
    required this.locked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    final Color border;
    IconData? icon;
    switch (state) {
      case _OptionState.right:
        bg = KidsTheme.success;
        fg = Colors.white;
        border = KidsTheme.success;
        icon = Icons.check_circle;
      case _OptionState.wrong:
        bg = const Color(0xFFFFE1E1);
        fg = const Color(0xFFB3261E);
        border = const Color(0xFFE57373);
        icon = Icons.cancel;
      case _OptionState.idle:
        bg = KidsTheme.pill(context);
        fg = locked ? scheme.onSurfaceVariant : scheme.onSurface;
        border = locked ? scheme.outline : color.withValues(alpha: 0.6);
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: state == _OptionState.idle && !locked ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                // Верно/неверно — и иконкой, не только цветом (ТЗ).
                Icon(icon, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final Lesson lesson;
  final LessonResult result;

  const _ResultPanel({required this.lesson, required this.result});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final String title;
    if (result.correct) {
      title = result.reward > 0
          ? '🎉 Верно! +${result.reward} 🪙'
          : '🎉 Верно! Ты это помнишь!';
    } else {
      title = result.alreadySolved
          ? '🤔 Не то. Попробуй ещё раз!'
          : '🤔 Не беда! Задание станет «Повтори» — монетки ещё ждут тебя.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KidsTheme.soft(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (result.correct) ...[
            Text('Разбор: ${lesson.answer}',
                style: const TextStyle(height: 1.35)),
            const SizedBox(height: 8),
          ] else ...[
            const Text('Подсказка Финни:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
          ],
          Text(
            '📘 ${lesson.note}',
            style: TextStyle(height: 1.35, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
