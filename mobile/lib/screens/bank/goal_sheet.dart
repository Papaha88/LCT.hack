import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/goals_data.dart';
import '../../models/game_state.dart';
import '../../theme/kids_theme.dart';
import '../../widgets/kids_button.dart';

/// Лист «Моя цель»: готовые мечты одним нажатием или своя цель —
/// название, картинка и сколько монет нужно.
///
/// Накопленное при смене цели не пропадает — меняется только то,
/// на что копим.
Future<bool> showGoalSheet(BuildContext context, GameState game) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _GoalSheet(game: game),
  );
  return changed ?? false;
}

class _GoalSheet extends StatefulWidget {
  final GameState game;

  const _GoalSheet({required this.game});

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late String _emoji;
  String? _error;

  @override
  void initState() {
    super.initState();
    final game = widget.game;
    final isPreset = goalPresets.any((g) => g.title == game.goalName);
    _name = TextEditingController(text: isPreset ? '' : game.goalName);
    _target = TextEditingController(
        text: isPreset ? '' : game.goalTarget.toString());
    _emoji = isPreset ? goalEmojiChoices.first : game.goalEmoji;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  void _pickPreset(GoalPreset preset) {
    widget.game.updateGoal(preset.title, preset.price, emoji: preset.emoji);
    Navigator.of(context).pop(true);
  }

  void _saveCustom() {
    final name = _name.text.trim();
    final target = int.tryParse(_target.text);
    if (name.isEmpty) {
      setState(() => _error = 'Напиши, о чём мечтаешь ✏️');
      return;
    }
    if (target == null ||
        target < minGoalTarget ||
        target > maxGoalTarget) {
      setState(() => _error =
          'Сколько монет? От $minGoalTarget до $maxGoalTarget 🪙');
      return;
    }
    widget.game.updateGoal(name, target, emoji: _emoji);
    Navigator.of(context).pop(true);
  }

  void _bump(int delta) {
    final current = int.tryParse(_target.text) ?? 0;
    var next = current + delta;
    if (next < minGoalTarget) next = minGoalTarget;
    if (next > maxGoalTarget) next = maxGoalTarget;
    setState(() {
      _target.text = '$next';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final game = widget.game;
    return Padding(
      // Лист поднимается над клавиатурой.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            children: [
              const Text(
                '🎯 Моя цель',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'В копилке уже ${game.savings} 🪙 — они останутся с тобой.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              const Text(
                'Выбери мечту',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...goalPresets.map(
                (preset) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PresetTile(
                    preset: preset,
                    selected: preset.title == game.goalName,
                    onTap: () => _pickPreset(preset),
                  ),
                ),
              ),
              const Divider(height: 24),
              const Text(
                '✏️ Или придумай свою',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                maxLength: 24,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() => _error = null),
                decoration: const InputDecoration(
                  labelText: 'О чём мечтаешь?',
                  hintText: 'Например, «Наушники»',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              const Text('Картинка для цели'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: goalEmojiChoices
                    .map(
                      (e) => InkWell(
                        onTap: () => setState(() => _emoji = e),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: e == _emoji
                                ? scheme.primary.withValues(alpha: 0.18)
                                : KidsTheme.pill(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  e == _emoji ? scheme.primary : scheme.outline,
                              width: e == _emoji ? 3 : 1,
                            ),
                          ),
                          child:
                              Text(e, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _BumpButton(label: '−50', onTap: () => _bump(-50)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _target,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: (_) => setState(() => _error = null),
                      decoration: const InputDecoration(
                        labelText: 'Сколько монет?',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _BumpButton(label: '+50', onTap: () => _bump(50)),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFB3261E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              KidsButton(text: 'Сохранить свою цель', onPressed: _saveCustom),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final GoalPreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: KidsTheme.pill(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? 3 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(preset.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${preset.title} • ${preset.price} 🪙',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    preset.hint,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

class _BumpButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BumpButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 54),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
