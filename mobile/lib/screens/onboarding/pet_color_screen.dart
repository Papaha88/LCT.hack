import 'package:flutter/material.dart';

import '../../models/pet.dart';
import '../../widgets/finny_bubble.dart';
import '../../widgets/kids_button.dart';
import '../../widgets/loop_carousel.dart';
import '../../widgets/pet_poster_card.dart';

/// Шаг 4б. Выбор окраски: карусель по кругу с постерами моделей.
/// 3 вида × 3 окраски = 9 комбинаций.
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
  late PetVariant _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    final label = PetLook.of(widget.type, _selected).label;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: FinnyBubble(text: 'Выбери окраску! 🎨'),
                  ),
                  const SizedBox(height: 16),
                  LoopCarousel(
                    // Смена вида — новая карусель с чистого листа.
                    key: ValueKey(widget.type),
                    itemCount: PetVariant.values.length,
                    initialIndex: _selected.index,
                    height: 300,
                    onChanged: (i) =>
                        setState(() => _selected = PetVariant.values[i]),
                    itemBuilder: (context, i, selected) => PetPosterCard(
                      type: widget.type,
                      variant: PetVariant.values[i],
                      title: PetLook.of(widget.type, PetVariant.values[i])
                          .label,
                      selected: selected,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                KidsButton(
                  text: 'Выбираю: $label',
                  icon: Icons.arrow_forward,
                  onPressed: () => widget.onNext(_selected),
                ),
                BackLink(onPressed: widget.onBack),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
