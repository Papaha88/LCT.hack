import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/pet.dart';
import '../level_up/level_up_screen.dart';

/// Режим разработчика: опыт, монеты и статы без прокрутки дней.
///
/// Открывается скрыто — 7 нажатий на строку версии внизу настроек.
/// Всё работает через обычные методы GameState, поэтому уровень,
/// награды и экран роста ведут себя как в настоящей игре.
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

    return Scaffold(
      appBar: AppBar(title: const Text('🛠 Разработчик')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pet != null)
            Text(
              'Уровень ${pet.level} (${Pet.stageForLevel(pet.level)}) • '
              'XP ${pet.xp}/100 • 🪙 ${game.balance}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 16),
          const Text('Опыт'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DevButton(label: '+10 XP', onTap: () => xp(10)),
              _DevButton(label: '+50 XP', onTap: () => xp(50)),
              _DevButton(label: '+1 уровень', onTap: () => xp(100)),
              _DevButton(label: '+3 уровня', onTap: () => xp(300)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Монеты и питомец'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DevButton(
                label: '+100 🪙',
                onTap: () => GameStateScope.read(context).devAddCoins(100),
              ),
              _DevButton(
                label: '+1000 🪙',
                onTap: () => GameStateScope.read(context).devAddCoins(1000),
              ),
              _DevButton(
                label: 'Статы 100',
                onTap: () => GameStateScope.read(context).devRestorePet(),
              ),
              _DevButton(
                label: 'Статы 10',
                onTap: () => GameStateScope.read(context).devDrainPet(),
              ),
            ],
          ),
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
