import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/pet.dart';
import '../../models/player_profile.dart';
import '../../widgets/finny_avatar.dart';
import '../dev/dev_screen.dart';
import '../parent/parent_gate.dart';
import '../parent/parent_screen.dart';

/// Настройки: профиль, родительский режим, о приложении.
/// Открываются шестерёнкой в AppBar (не занимают вкладку навигации).
///
/// Смена возраста и сброс прогресса живут в родительском режиме —
/// туда пускаем только после «взрослых» примеров.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  /// Версия внизу экрана. Семь нажатий на неё — режим разработчика.
  static const String version = 'Версия 0.2.0';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Счётчик нажатий на версию (скрытый вход для разработчиков).
  int _versionTaps = 0;

  void _onVersionTap() {
    _versionTaps++;
    if (_versionTaps < 7) return;
    _versionTaps = 0;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DevScreen()),
    );
  }

  Future<void> _openParentMode(BuildContext context) async {
    final navigator = Navigator.of(context);
    final ok = await showParentGate(context);
    if (!ok) return;
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const ParentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final pet = game.pet;
    final age = game.age;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const FinnyAvatar(size: 72, waving: false),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👋 ${game.nickname}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          age == null
                              ? '👦 Возраст не указан'
                              : '👦 Возраст: ${PlayerProfile.labelFor(age)}',
                        ),
                        if (pet != null) ...[
                          Text(
                            '${pet.type.emoji} ${pet.name} • ${pet.stage}',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          Text(
                            '📅 День ${game.day} • 🪙 ${game.balance} • '
                            '🐷 ${game.savings}',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Text('👨‍👩‍👧',
                      style: TextStyle(fontSize: 24)),
                  title: const Text('Родительский режим'),
                  subtitle: const Text(
                      'Прогресс, возраст, сброс. Вход — через примеры'),
                  trailing: const Icon(Icons.lock_outline),
                  onTap: () => _openParentMode(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Text('ℹ️', style: TextStyle(fontSize: 24)),
                  title: const Text('О приложении'),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Финни 🐱'),
                      content: const Text(
                        'Заботимся о питомце, решаем задания и учимся '
                        'управлять монетками.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Понятно'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Обычная серая подпись — ничем не выдаёт, что на неё можно жать.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onVersionTap,
            child: SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  SettingsScreen.version,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}