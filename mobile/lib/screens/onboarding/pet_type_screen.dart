import 'package:flutter/material.dart';

import '../../models/pet.dart';
import '../../widgets/finny_bubble.dart';
import '../../widgets/kids_button.dart';
import '../../widgets/loop_carousel.dart';
import '../../widgets/pet_poster_card.dart';

/// Шаг 4а. Выбор вида питомца: карусель по кругу с постерами моделей.
/// Кто в центре — тот и выбран.
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
  late PetType _selected = widget.selected ?? PetType.cat;

  @override
  Widget build(BuildContext context) {
    final hello = widget.nickname.isEmpty
        ? 'Привет!'
        : 'Рад знакомству, ${widget.nickname}!';
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FinnyBubble(
                      text: '$hello Кто будет твоим питомцем? '
                          'Листай вправо и влево!',
                    ),
                  ),
                  const SizedBox(height: 16),
                  LoopCarousel(
                    itemCount: PetType.values.length,
                    initialIndex: _selected.index,
                    height: 300,
                    onChanged: (i) =>
                        setState(() => _selected = PetType.values[i]),
                    itemBuilder: (context, i, selected) => PetPosterCard(
                      type: PetType.values[i],
                      variant: PetVariant.v1,
                      title: PetType.values[i].title,
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
                  text: 'Выбираю: ${_selected.title}',
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
