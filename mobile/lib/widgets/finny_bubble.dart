import 'package:flutter/material.dart';

/// Облачко речи Финни (хвостик сверху — к аватару).
class FinnyBubble extends StatelessWidget {
  final String text;
  final double fontSize;

  const FinnyBubble({super.key, required this.text, this.fontSize = 17});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.35,
              color: const Color(0xFF3A334E),
            ),
          ),
        ),
        Positioned(
          left: 34,
          top: -7,
          child: Transform.rotate(
            angle: 0.785,
            child: Container(width: 18, height: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
