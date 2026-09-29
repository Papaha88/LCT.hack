import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/pet.dart';
import '../level_up/level_up_screen.dart';

/// Режим эксперта: быстро посмотреть всё, что в обычной игре занимает
/// дни, — возраст и эмоции питомца, уровни, финиш дорог, огонёк.
///
/// Открывается кнопкой «Для экспертов» в настройках. Работает через
/// методы GameState, поэтому правила игры (доход, траты, награды)
/// те же, что у ребёнка.
class DevScreen extends StatelessWidget {
  const DevScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final pet = game.pet;

    Future<void> xp(int amount) async {
      GameStateScope.read(context).devAddXp(amount);
      await showLevelUpIfNeeded(context);
    }

    void run(void Function() action) => action();

    return Scaffold(
      appBar: AppBar(title: const Text('🧪 Режим эксперта')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pet != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  '${pet.name}: уровень ${pet.level} • ${pet.stage}\n'
                  'XP ${pet.xp}/100 • счастье ${pet.happiness} '
                  '(${_emotionTitle(pet.emotion)})\n'
                  'День ${game.day} • 🪙 ${game.balance} • 🔥 ${game.streak}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          _Section(
            title: 'Уровень и опыт',
            hint: 'С наградами и экраном роста — как в игре',
            children: [
              _DevButton(label: '+50 XP', onTap: () => xp(50)),
              _DevButton(label: '+1 уровень', onTap: () => xp(100)),
              _DevButton(label: '+5 уровней', onTap: () => xp(500)),
              _DevButton(label: '+10 уровней', onTap: () => xp(1000)),
            ],
          ),
          _Section(
            title: 'Возраст модели',
            hint: 'Уровень сразу, без наград: '
                '1–${teenLevel - 1} малыш, $teenLevel–${adultLevel - 1} '
                'подросток, $adultLevel+ взрослый',
            children: [
              _DevButton(
                label: 'Малыш (ур. 1)',
                onTap: () => run(() => game.devSetLevel(1)),
              ),
              _DevButton(
                label: 'Подросток (ур. $teenLevel)',
                onTap: () => run(() => game.devSetLevel(teenLevel)),
              ),
              _DevButton(
                label: 'Взрослый (ур. $adultLevel)',
                onTap: () => run(() => game.devSetLevel(adultLevel)),
              ),
            ],
          ),
          _Section(
            title: 'Эмоция модели',
            hint: 'По счастью: <$sadBelow грустный, >$happyAbove весёлый',
            children: [
              _DevButton(
                label: '😢 Грустный',
                onTap: () => run(() => game.devSetHappiness(15)),
              ),
              _DevButton(
                label: '🙂 Обычный',
                onTap: () => run(() => game.devSetHappiness(50)),
              ),
              _DevButton(
                label: '😄 Весёлый',
                onTap: () => run(() => game.devSetHappiness(95)),
              ),
              _DevButton(
                label: 'Все статы 100',
                onTap: () => run(game.devRestorePet),
              ),
              _DevButton(
                label: 'Все статы 10',
                onTap: () => run(game.devDrainPet),
              ),
            ],
          ),
          _Section(
            title: 'Время и деньги',
            hint: 'Дни — с доходом и тратами, без «бумажки»',
            children: [
              _DevButton(
                label: '+1 день',
                onTap: () => run(() => game.devSkipDays(1)),
              ),
              _DevButton(
                label: '+5 дней',
                onTap: () => run(() => game.devSkipDays(5)),
              ),
              _DevButton(
                label: '+100 🪙',
                onTap: () => run(() => game.devAddCoins(100)),
              ),
              _DevButton(
                label: '+1000 🪙',
                onTap: () => run(() => game.devAddCoins(1000)),
              ),
              _DevButton(
                label: '🔥 +1 к огоньку',
                onTap: () => run(game.devBumpStreak),
              ),
            ],
          ),
          _Section(
            title: 'Задания',
            children: [
              _DevButton(
                label: 'Решить все',
                onTap: () => run(game.devSolveAllLessons),
              ),
              _DevButton(
                label: 'Сбросить задания',
                onTap: () => run(game.resetLessons),
              ),
              _DevButton(
                label: 'Показать помощника',
                onTap: () => run(game.devResetGuide),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _emotionTitle(PetEmotion e) {
    switch (e) {
      case PetEmotion.sad:
        return 'грустный';
      case PetEmotion.normal:
        return 'обычный';
      case PetEmotion.happy:
        return 'весёлый';
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? hint;
  final List<Widget> children;

  const _Section({required this.title, this.hint, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (hint != null)
            Text(
              hint!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _DevButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DevButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(minimumSize: const Size(96, 48)),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
