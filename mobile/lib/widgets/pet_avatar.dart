import 'package:flutter/material.dart';

import '../models/pet.dart';

/// Круглая карточка питомца: градиент окраски + эмодзи вида
/// + мордочка настроения. Один виджет рисует все 9 комбинаций.
class PetAvatar extends StatelessWidget {
  final PetType type;
  final PetVariant variant;
  final double size;
  final String? moodEmoji;
  final bool showLabel;

  const PetAvatar({
    super.key,
    required this.type,
    required this.variant,
    this.size = 140,
    this.moodEmoji,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final look = PetLook.of(type, variant);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [look.bgStart, look.bgEnd],
                ),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child:
                    Text(type.emoji, style: TextStyle(fontSize: size * 0.48)),
              ),
            ),
            if (moodEmoji != null)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(moodEmoji!,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
          ],
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: look.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              look.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
