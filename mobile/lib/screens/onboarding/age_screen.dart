import 'package:flutter/material.dart';

import '../../models/player_profile.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/finny_avatar.dart';
import '../../widgets/finny_bubble.dart';
import '../../widgets/kids_button.dart';

/// Шаг 3. Возраст игрока: 7–11 лет, выбор кнопками — без клавиатуры.
/// Возраст показываем на главном экране, поменять можно в настройках.
class AgeScreen extends StatefulWidget {
  final int? selected;
  final VoidCallback onBack;
  final ValueChanged<int> onNext;

  const AgeScreen({
    super.key,
    required this.selected,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const FinnyAvatar(size: 96),
                  const SizedBox(height: 12),
                  const FinnyBubble(
                    text: 'Сколько тебе лет?\n'
                        'Так я буду объяснять понятнее 🎈',
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: PlayerProfile.ageChoices
                        .map(
                          (age) => _AgeChoice(
                            age: age,
                            selected: _selected == age,
                            onTap: () => setState(() => _selected = age),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          KidsButton(
            text: 'Далее',
            icon: Icons.arrow_forward,
            onPressed: _selected == null
                ? null
                : () => widget.onNext(_selected!),
          ),
          BackLink(onPressed: widget.onBack),
        ],
      ),
    );
  }
}

class _AgeChoice extends StatelessWidget {
  final int age;
  final bool selected;
  final VoidCallback onTap;

  const _AgeChoice({
    required this.age,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        // ТЗ: тач-таргет не меньше 48x48dp.
        constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : KidsTheme.pill(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? 3 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Галочка занимает место всегда — при выборе плашка не «прыгает».
            // Иконкой, а не символом «✓»: его нет в Roboto, и вместо галочки
            // получался пустой квадрат.
            SizedBox(
              width: 22,
              child: selected
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
            Text(
              '$age лет',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
