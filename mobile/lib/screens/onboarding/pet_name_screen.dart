import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/names_data.dart';
import '../../services/name_filter.dart';
import '../../widgets/finny_avatar.dart';
import '../../widgets/finny_bubble.dart';
import '../../widgets/kids_button.dart';

/// Шаг 5. Имя питомца + кубик со случайными именами (10 штук).
class PetNameScreen extends StatefulWidget {
  final String initial;
  final VoidCallback onBack;
  final ValueChanged<String> onNext;

  const PetNameScreen({
    super.key,
    required this.initial,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<PetNameScreen> createState() => _PetNameScreenState();
}

class _PetNameScreenState extends State<PetNameScreen> {
  late final TextEditingController _controller;
  final _random = Random();

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

  /// Мат и слова 18+ в имени не пропускаем.
  bool get _blocked => _clean.isNotEmpty && !NameFilter.isAllowed(_clean);

  void _rollDice() {
    final current = _controller.text;
    var next = current;
    // Крутим, пока не выпадет другое имя (максимум 10 попыток).
    for (var i = 0; i < 10 && next == current; i++) {
      next = dicePetNames[_random.nextInt(dicePetNames.length)];
    }
    _controller.text = next;
    _controller.selection =
        TextSelection.fromPosition(TextPosition(offset: next.length));
    setState(() {});
  }

  void _submit() {
    if (_clean.isEmpty || _blocked) return;
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
                    text: 'Как ты назовёшь своего нового друга?\n'
                        'Нажми на кубик 🎲, если хочешь случайное имя!',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          maxLength: 15,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'Имя питомца',
                            counterText: '',
                            errorText: _blocked
                                ? 'Такое имя не подойдёт — придумай другое'
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _rollDice,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text('🎲', style: TextStyle(fontSize: 30)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          KidsButton(
            text: 'Готово ✅',
            onPressed: _clean.isEmpty || _blocked ? null : _submit,
          ),
          BackLink(onPressed: widget.onBack),
        ],
      ),
    );
  }
}
