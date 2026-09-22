import 'package:flutter/material.dart';

import '../app.dart';
import 'bank/bank_screen.dart';
import 'home/home_screen.dart';
import 'plan/plan_screen.dart';
import 'quests/quests_screen.dart';
import 'settings/settings_screen.dart';
import 'shop/shop_screen.dart';

/// Каркас с нижней навигацией:
/// Питомец • План • Задания • Магазин • Банк.
/// Настройки открываются шестерёнкой в AppBar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    PlanScreen(),
    QuestsScreen(),
    ShopScreen(),
    BankScreen(),
  ];

  /// Заголовок шапки = название текущей страницы.
  static const _titles = [
    'Питомец 🐾',
    'Бюджет 📋',
    'Задания ⭐',
    'Покупка 🛍️',
    'Банк 🐷',
  ];

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Сменить тему',
            onPressed: () => GameStateScope.read(context).toggleTheme(),
            icon: Icon(game.isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: 'Настройки',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Text('🐾', style: TextStyle(fontSize: 22)),
            label: 'Питомец',
          ),
          BottomNavigationBarItem(
            icon: Text('📋', style: TextStyle(fontSize: 22)),
            label: 'План',
          ),
          BottomNavigationBarItem(
            icon: Text('⭐', style: TextStyle(fontSize: 22)),
            label: 'Задания',
          ),
          BottomNavigationBarItem(
            icon: Text('🛍️', style: TextStyle(fontSize: 22)),
            label: 'Магазин',
          ),
          BottomNavigationBarItem(
            icon: Text('🐷', style: TextStyle(fontSize: 22)),
            label: 'Банк',
          ),
        ],
      ),
    );
  }
}
