import 'package:flutter/material.dart';

import '../../models/pet.dart';
import '../../widgets/finny_avatar.dart';
import '../../widgets/finny_bubble.dart';
import '../../widgets/kids_button.dart';

/// Шаг 3а. Выбор вида питомца: кошечка / собачка / пингвинчик.
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
                  const FinnyAvatar(size: 84),
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
            text: 'Далее ➜',
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
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
            Text(type.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                type.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selected ? '✅' : '⬜',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
