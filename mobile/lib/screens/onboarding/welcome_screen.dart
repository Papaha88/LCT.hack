import 'package:flutter/material.dart';

import '../../widgets/finny_avatar.dart';
import '../../widgets/finny_bubble.dart';
import '../../widgets/kids_button.dart';

/// Шаг 1. Экран приветствия: Финни (без качания) + кнопка «Далее».
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 16),
                  FinnyAvatar(size: 150),
                  SizedBox(height: 20),
                  FinnyBubble(
                    text: 'Привет! Я — Финни, твой помощник!\n'
                        'Я помогу тебе научиться управлять монетками '
                        'и заботиться о питомце. Вместе мы станем '
                        'настоящими финансовыми экспертами!\n'
                        'Готов?',
                  ),
                ],
              ),
            ),
          ),
          KidsButton(
            text: 'Далее',
            icon: Icons.arrow_forward,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
