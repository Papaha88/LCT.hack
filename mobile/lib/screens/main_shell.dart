import 'package:flutter/material.dart';

import '../app.dart';
import 'bank/bank_screen.dart';
import 'home/home_screen.dart';
import 'plan/plan_screen.dart';
import 'quests/quests_screen.dart';
import 'settings/settings_screen.dart';
import 'shop/shop_screen.dart';
import '../widgets/streak_flame.dart';

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

  /// Вкладки. Задания знают, открыты ли они: помощник в них выезжает
  /// только при настоящем заходе на вкладку.
  List<Widget> get _pages => [
        const HomeScreen(),
        const PlanScreen(),
        QuestsScreen(active: _index == _questsTab),
        const ShopScreen(),
        const BankScreen(),
      ];

  /// Заголовок шапки = название текущей страницы.
  static const _titles = [
    'Мой питомец',
    'План бюджета',
    'Дороги заданий',
    'Лавка',
    'Копилка',
  ];

  /// Номера вкладок в [_pages].
  static const int _questsTab = 2;
  static const int _shopTab = 3;

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
          // В магазине баланс висит в шапке — его видно при прокрутке.
          if (_index == _shopTab) _BalanceChip(balance: game.balance),
          const StreakFlame(),
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
        // ТЗ: текст не меньше 16sp.
        selectedFontSize: 16,
        unselectedFontSize: 16,
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

/// Баланс в шапке магазина.
class _BalanceChip extends StatelessWidget {
  final int balance;

  const _BalanceChip({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'В кошельке $balance монет',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '🪙 $balance',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
