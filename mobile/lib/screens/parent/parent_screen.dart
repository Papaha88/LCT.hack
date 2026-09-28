import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/lessons_data.dart';
import '../../models/player_profile.dart';
import '../../theme/kids_theme.dart';

/// Родительский режим: прогресс ребёнка на дорогах, возраст
/// (от него зависят рекомендованные задания) и сбросы.
/// Открывается из настроек только после решения «взрослых» примеров.
class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  Future<void> _editAge(BuildContext context) async {
    final game = GameStateScope.read(context);
    final current = game.age;
    final picked = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('👦 Возраст ребёнка'),
        children: PlayerProfile.ageChoices
            .map(
              (age) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(age),
                // Галочка иконкой, а не символом «✓»: его нет в Roboto.
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: age == current
                          ? const Icon(Icons.check, size: 18)
                          : null,
                    ),
                    Text(PlayerProfile.labelFor(age),
                        style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (picked != null) game.updateAge(picked);
  }

  Future<bool> _confirm(
      BuildContext context, String title, String text, String yes) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(yes),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _resetLessons(BuildContext context) async {
    final game = GameStateScope.read(context);
    final ok = await _confirm(
      context,
      'Сбросить задания?',
      'Дороги «Математика» и «Финансы» начнутся заново. Монетки, питомец '
          'и копилка останутся.',
      'Сбросить',
    );
    if (ok) game.resetLessons();
  }

  Future<void> _resetAll(BuildContext context) async {
    final game = GameStateScope.read(context);
    final navigator = Navigator.of(context);
    final ok = await _confirm(
      context,
      'Начать игру заново?',
      'Питомец, монетки и весь прогресс будут удалены.',
      'Удалить всё',
    );
    if (ok) {
      await game.reset();
      // Приложение само переключится на онбординг, стек чистим.
      navigator.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final age = game.age;

    return Scaffold(
      appBar: AppBar(title: const Text('👨‍👩‍👧 Родительский режим')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📈 Прогресс: ${game.nickname}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  for (final track in LessonTrack.values) ...[
                    _TrackProgress(
                      track: track,
                      solved: game.solvedOn(track),
                      total: lessonsOf(track).length,
                      recommended: recommendedGrade(age, track),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    '❌ Ошибок за всё время: ${game.lessonMistakes}\n'
                    '🔁 Ждут повторения: ${game.lessonsRetry.length}\n'
                    '🐷 В копилке: ${game.savings} из ${game.goalTarget} '
                    '(${game.goalName})\n'
                    '📅 Игровой день: ${game.day}',
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Text('👦', style: TextStyle(fontSize: 24)),
                  title: Text(age == null
                      ? 'Возраст не указан'
                      : 'Возраст: ${PlayerProfile.labelFor(age)}'),
                  subtitle: const Text(
                      'По возрасту подбираются рекомендованные задания'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _editAge(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Text('🧹', style: TextStyle(fontSize: 24)),
                  title: const Text('Сбросить задания'),
                  subtitle: const Text('Пройти дороги с начала'),
                  onTap: () => _resetLessons(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Text('🔄', style: TextStyle(fontSize: 24)),
                  title: const Text('Начать игру заново'),
                  subtitle: const Text('Стереть питомца и монетки'),
                  onTap: () => _resetAll(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KidsTheme.soft(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '💡 Все задания открыты. Возраст лишь подсказывает ребёнку, '
              'с чего начать: 7 лет — 1 класс, 8 — 2, 9 — 3, 10+ — 4. '
              'Ошибка не отнимает монет: задание просто просит повторить.',
              style: TextStyle(height: 1.4, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackProgress extends StatelessWidget {
  final LessonTrack track;
  final int solved;
  final int total;
  final int recommended;

  const _TrackProgress({
    required this.track,
    required this.solved,
    required this.total,
    required this.recommended,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${track.emoji} ${track.title}: $solved из $total '
          '• рекомендован $recommended класс',
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : solved / total,
            minHeight: 12,
            color: track.color,
          ),
        ),
      ],
    );
  }
}
