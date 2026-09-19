import 'package:flutter/material.dart';

import '../../models/pet.dart';
import '../../widgets/finny_bubble.dart';
import '../../widgets/kids_button.dart';
import '../../widgets/pet_avatar.dart';

/// Шаг 3б. Выбор окраски: 3 варианта на каждый вид.
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
            text: 'Далее ➜',
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                selected ? const Color(0xFF6C63FF) : Colors.transparent,
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PetAvatar(type: type, variant: variant, size: 78),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                look.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selected ? '✅ Выбрано' : '⬜',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
