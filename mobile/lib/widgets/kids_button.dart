import 'package:flutter/material.dart';

/// Большая детская кнопка на всю ширину.
class KidsButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  const KidsButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
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
        child: Text(text),
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
    return TextButton(
      onPressed: onPressed,
      child: const Text('← Назад', style: TextStyle(fontSize: 16)),
    );
  }
}
