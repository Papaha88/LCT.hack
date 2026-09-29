import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../theme/kids_theme.dart';
import 'pet_model.dart';

/// Карточка-постер питомца для каруселей (онбординг, магазин):
/// фон окраски, постер модели, название и «Выбрано».
class PetPosterCard extends StatelessWidget {
  final PetType type;
  final PetVariant variant;
  final String title;
  final String? subtitle;
  final bool selected;
  final int level;

  const PetPosterCard({
    super.key,
    required this.type,
    required this.variant,
    required this.title,
    required this.selected,
    this.subtitle,
    this.level = 1,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final look = PetLook.of(type, variant);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            look.bgStart.withValues(alpha: 0.9),
            KidsTheme.pill(context),
          ],
        ),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outline,
          width: selected ? 3 : 1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => Center(
                    child: PetModel(
                      type: type,
                      variant: variant,
                      level: level,
                      emotion: PetEmotion.happy,
                      size: box.maxHeight.clamp(60.0, box.maxWidth) / 1.08,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              // Состояние — текстом, а не только цветом (требование ТЗ).
              Text(
                selected ? 'Выбрано' : (subtitle ?? 'Листай'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // Галочка иконкой, а не символом «✓»: его нет в Roboto.
          if (selected)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.check_circle, size: 26, color: scheme.primary),
            ),
        ],
      ),
    );
  }
}
