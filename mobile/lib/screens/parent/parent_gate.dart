import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Пример для входа в родительский режим.
class GateExample {
  final String text;
  final int answer;

  const GateExample(this.text, this.answer);

  /// Два «взрослых» примера: умножение двузначного на однозначное
  /// и вычитание трёхзначных с переходом через разряд. Ребёнку 7–10 лет
  /// в уме так быстро не посчитать, взрослому — несложно.
  static List<GateExample> generate(math.Random random) {
    final a = 13 + random.nextInt(37); // 13..49
    final b = 6 + random.nextInt(4); // 6..9
    var c = 400 + random.nextInt(500); // 400..899
    if (c % 10 == 9) c -= 5;
    // Единицы вычитаемого больше, чем у уменьшаемого, — нужен переход
    // через десяток.
    final ones = c % 10 + 1 + random.nextInt(9 - c % 10);
    final d = 120 + random.nextInt(26) * 10 + ones; // 121..379
    return [
      GateExample('$a × $b', a * b),
      GateExample('$c − $d', c - d),
    ];
  }
}

/// Проверка «ты взрослый?» перед родительским режимом.
/// Возвращает true, если оба примера решены верно.
Future<bool> showParentGate(BuildContext context, {math.Random? random}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ParentGateDialog(random: random ?? math.Random()),
  );
  return ok ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  final math.Random random;

  const _ParentGateDialog({required this.random});

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  late List<GateExample> _examples;
  late List<TextEditingController> _controllers;
  String? _error;

  @override
  void initState() {
    super.initState();
    _newExamples();
  }

  void _newExamples() {
    _examples = GateExample.generate(widget.random);
    _controllers = [for (final _ in _examples) TextEditingController()];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _check() {
    for (var i = 0; i < _examples.length; i++) {
      if (int.tryParse(_controllers[i].text.trim()) != _examples[i].answer) {
        final old = _controllers;
        setState(() {
          _error = 'Неверно. Вот новые примеры.';
          _newExamples();
        });
        // Старые поля ещё рисуются в этом кадре — освобождаем после него.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final c in old) {
            c.dispose();
          }
        });
        return;
      }
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('👨‍👩‍👧 Только для взрослых'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Чтобы открыть родительский режим, реши примеры:'),
            const SizedBox(height: 12),
            for (var i = 0; i < _examples.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_examples[i].text} =',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 96,
                      child: TextField(
                        key: ValueKey('gate_answer_$i'),
                        controller: _controllers[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        onSubmitted: (_) => _check(),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFB3261E),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: _check,
          child: const Text('Войти'),
        ),
      ],
    );
  }
}
