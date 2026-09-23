import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/finny_avatar.dart';
import '../../widgets/finny_bubble.dart';
import '../../widgets/kids_button.dart';

/// Шаг 2. Знакомство: игровое имя.
/// Максимум 15 символов, пробелы по краям убираем автоматически.
class NicknameScreen extends StatefulWidget {
  final String initial;
  final VoidCallback onBack;
  final ValueChanged<String> onNext;

  const NicknameScreen({
    super.key,
    required this.initial,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _clean => _controller.text.trim();

  void _submit() {
    if (_clean.isEmpty) return;
    FocusScope.of(context).unfocus();
    widget.onNext(_clean);
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
                  const FinnyAvatar(size: 110),
                  const SizedBox(height: 16),
                  const FinnyBubble(
                    text: 'А как мне к тебе обращаться?\n'
                        'Придумай своё игровое имя! Это может быть '
                        'любое имя, которое тебе нравится.',
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    maxLength: 15,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Твоё имя',
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
          ),
          KidsButton(
            text: 'Отлично! 🎉',
            onPressed: _clean.isEmpty ? null : _submit,
          ),
          BackLink(onPressed: widget.onBack),
        ],
      ),
    );
  }
}
