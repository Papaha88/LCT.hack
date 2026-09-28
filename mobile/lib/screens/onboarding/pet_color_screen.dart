import 'package:flutter/material.dart';

import '../../models/pet.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/action_spark.dart';
import '../../widgets/finny_bubble.dart';
import '../../widgets/kids_button.dart';
import '../../widgets/pet_avatar.dart';

/// Шаг 4б. Выбор окраски: 3 варианта на каждый вид.
/// Всего 3 вида x 3 окраски = 9 комбинаций.
class PetColorScreen extends StatefulWidget {
  final PetType type;
  final PetVariant selected;
  final VoidCallback onBack;
  final ValueChanged<PetVariant> onNext;

  const PetColorScreen({
    super.key,
    required this.type,
    required this.selected,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<PetColorScreen> createState() => _PetColorScreenState();
}

class _PetColorScreenState extends State<PetColorScreen> {
  late PetVariant _selected;

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
                  const SizedBox(height: 8),
                  const FinnyBubble(
                    text: 'Выбери окраску для питомца! 🎨',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: PetVariant.values
                        .map(
                          (variant) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: _ColorCard(
                                type: widget.type,
                                variant: variant,
                                selected: _selected == variant,
                                onTap: () => setState(
                                    () => _selected = variant),
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
            onPressed: () => widget.onNext(_selected),
          ),
          BackLink(onPressed: widget.onBack),
        ],
      ),
    );
  }
}

class _ColorCard extends StatelessWidget {
  final PetType type;
  final PetVariant variant;
  final bool selected;
  final VoidCallback onTap;

  const _ColorCard({
    required this.type,
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final look = PetLook.of(type, variant);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
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
                // Огонёк вспыхивает, когда окраску выбрали.
                SparkOnAction(
                  trigger: selected ? 1 : 0,
                  spread: 30,
                  child: PetAvatar(type: type, variant: variant, size: 74),
                ),
                const SizedBox(height: 10),
                Text(
                  look.label,
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
