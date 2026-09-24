import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/pet.dart';
import '../../models/player_profile.dart';
import 'age_screen.dart';
import 'nickname_screen.dart';
import 'pet_color_screen.dart';
import 'pet_name_screen.dart';
import 'pet_type_screen.dart';
import 'rules_screen.dart';
import 'welcome_screen.dart';

/// Онбординг из 7 шагов на PageView (свайп выключен — только кнопки).
/// Черновик живёт здесь, в GameState сохраняем один раз — на финише.
///
/// Порядок: приветствие → имя → возраст → вид → окраска → имя питомца → правила.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pages = PageController();

  String _nickname = '';
  int? _age;
  PetType? _petType;
  PetVariant _petVariant = PetVariant.v1;
  String _petName = '';

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    final game = GameStateScope.read(context);
    await game.createProfile(
      nickname: _nickname,
      // Кнопка «Далее» на шаге возраста неактивна, пока возраст не выбран.
      age: _age ?? PlayerProfile.minAge,
      type: _petType ?? PetType.cat,
      variant: _petVariant,
      petName: _petName,
    );
    // Дальше App сам переключит home на MainShell.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            WelcomeScreen(onNext: () => _go(1)),
            NicknameScreen(
              initial: _nickname,
              onBack: () => _go(0),
              onNext: (value) {
                setState(() => _nickname = value);
                _go(2);
              },
            ),
            AgeScreen(
              selected: _age,
              onBack: () => _go(1),
              onNext: (value) {
                setState(() => _age = value);
                _go(3);
              },
            ),
            PetTypeScreen(
              nickname: _nickname,
              selected: _petType,
              onBack: () => _go(2),
              onNext: (type) {
                setState(() => _petType = type);
                _go(4);
              },
            ),
            PetColorScreen(
              type: _petType ?? PetType.cat,
              selected: _petVariant,
              onBack: () => _go(3),
              onNext: (variant) {
                setState(() => _petVariant = variant);
                _go(5);
              },
            ),
            PetNameScreen(
              initial: _petName,
              onBack: () => _go(4),
              onNext: (name) {
                setState(() => _petName = name);
                _go(6);
              },
            ),
            RulesScreen(
              onBack: () => _go(5),
              onNext: _finish,
            ),
          ],
        ),
      ),
    );
  }
}
