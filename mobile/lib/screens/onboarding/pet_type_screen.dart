import 'package:flutter/material.dart';

import '../../models/pet.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/action_spark.dart';
import '../../widgets/finny_avatar.dart';
import '../../widgets/finny_bubble.dart';
import '../../widgets/kids_button.dart';

/// Шаг 4а. Выбор вида питомца: кошечка / собачка / пингвинчик.
class PetTypeScreen extends StatefulWidget {
  final String nickname;
  final PetType? selected;
  final VoidCallback onBack;
  final ValueChanged<PetType> onNext;

  const PetTypeScreen({
    super.key,
    required this.nickname,
    required this.selected,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<PetTypeScreen> createState() => _PetTypeScreenState();
}

class _PetTypeScreenState extends State<PetTypeScreen> {
  PetType? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final hello = widget.nickname.isEmpty
        ? 'Привет!'
        : 'Рад знакомству, ${widget.nickname}!';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const FinnyAvatar(size: 84, waving: false),
                  const SizedBox(height: 12),
                  FinnyBubble(
                    text: '$hello\n'
                        'Теперь давай создадим твоего питомца. Ты сможешь '
                        'выбрать, как он будет выглядеть, и дать ему имя.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: PetType.values
                        .map(
                          (type) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: _TypeCard(
                                type: type,
                                selected: _selected == type,
                                onTap: () =>
                                    setState(() => _selected = type),
                              ),
                            ),
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
            onPressed:
                _selected == null ? null : () => widget.onNext(_selected!),
          ),
          BackLink(onPressed: widget.onBack),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final PetType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            decoration: BoxDecoration(
              color: KidsTheme.pill(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outline,
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Огонёк вспыхивает, когда вид выбрали.
                SparkOnAction(
                  trigger: selected ? 1 : 0,
                  spread: 32,
                  child: Text(type.emoji,
                      style: const TextStyle(fontSize: 46)),
                ),
                const SizedBox(height: 8),
                Text(
                  type.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                // Состояние показано текстом, а не только цветом (требование ТЗ).
                Text(
                  selected ? 'Выбрано' : 'Выбрать',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                    color:
                        selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Галочка иконкой, а не символом «✓»: его нет в Roboto, и вместо
          // галочки получался пустой квадрат. Material-иконки вшиты в APK.
          if (selected)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.check_circle,
                  size: 22, color: scheme.primary),
            ),
        ],
      ),
    );
  }
}
