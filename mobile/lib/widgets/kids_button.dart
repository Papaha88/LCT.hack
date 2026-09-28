import 'package:flutter/material.dart';

/// Большая детская кнопка на всю ширину.
///
/// [icon] — иконка после текста, например стрелка «дальше». Именно иконка,
/// а не символ в тексте: символов вроде «➜» нет в шрифте Roboto, и вместо
/// них на устройстве рисуется пустой квадрат. Material-иконки вшиты в APK.
class KidsButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final IconData? icon;

  const KidsButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: backgroundColor == null
            ? null
            : ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: Colors.white,
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flexible + обрезка: длинная подпись не выдавит иконку за кнопку.
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

/// Текстовая кнопка «назад» для шагов онбординга.
class BackLink extends StatelessWidget {
  final VoidCallback onPressed;

  const BackLink({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back, size: 20),
      label: const Text('Назад'),
    );
  }
}
