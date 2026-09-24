import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quests_data.dart';
import '../data/shop_data.dart';
import 'pet.dart';
import 'player_profile.dart';

int _stat(int v) => v < 0 ? 0 : (v > 100 ? 100 : v);

/// Общее состояние игры: профиль, питомец, деньги, цель,
/// задания, инвентарь, периоды.
///
/// Живёт в одном ChangeNotifier и раздаётся через [GameStateScope]
/// (см. lib/app.dart), чтобы не тянуть внешние state-менеджмент пакеты.
/// Сохраняется в SharedPreferences после каждого изменения.
class GameState extends ChangeNotifier {
  static const _prefsKey = 'finny_state_v1';

  PlayerProfile? profile;
  Pet? pet;

  /// Монетки в кошельке.
  int balance = 60;

  /// Монетки в копилке.
  int savings = 0;
  String goalName = 'Велосипед';
  int goalTarget = 300;

  /// Текущий период («День N»).
  int day = 1;
  bool onboardingDone = false;

  /// Тёмная тема включена (переключатель 🌙/☀️ в шапке)?
  bool isDark = false;

  /// Одноразовый флаг: только что прошли онбординг — показать «Секрет игры».
  bool justFinishedOnboarding = false;

  /// id предмета -> количество.
  Map<String, int> inventory = {'milk': 1, 'soap': 1, 'ball': 1};

  Set<String> questsDone = {};

  /// День выдачи текущего активного задания (для подсказки «висит > 1 периода»).
  int questGivenDay = 1;

  /// Дата последнего ежедневного бонуса (yyyy-MM-dd).
  String? lastBonusDate;

  /// Доход за новый период. Растёт с уровнем питомца.
  int get baseIncome => 40 + (pet?.level ?? 1) * 10;

  double get goalProgress {
    if (goalTarget <= 0) return 0;
    final p = savings / goalTarget;
    if (p < 0) return 0;
    if (p > 1) return 1;
    return p;
  }

  int get goalLeft {
    final left = goalTarget - savings;
    return left < 0 ? 0 : left;
  }

  Quest? get activeQuest {
    for (final q in questsCatalog) {
      if (!questsDone.contains(q.id)) return q;
    }
    return null;
  }

  String get nickname => profile?.nickname ?? 'Друг';

  /// Возраст игрока. `null` — сейв, сделанный до появления вопроса о возрасте.
  int? get age => profile?.age;

  Future<void> init() async {
    await load();
  }

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  /// Ежедневный бонус +15 монет. Возвращает true, если бонус выдан
  /// (тогда UI показывает диалог). Вызывать с главного экрана
  /// после первой отрисовки кадра.
  bool claimDailyBonusIfNeeded() {
    if (!onboardingDone || pet == null) return false;
    if (lastBonusDate == _today()) return false;
    lastBonusDate = _today();
    balance += 15;
    notifyListeners();
    save();
    return true;
  }

  Future<void> createProfile({
    required String nickname,
    required int age,
    required PetType type,
    required PetVariant variant,
    required String petName,
  }) async {
    profile = PlayerProfile(nickname: nickname, age: age);
    pet = Pet(
      type: type,
      variant: variant,
      name: petName,
      hunger: 100,
      happiness: 100,
      cleanliness: 100,
      xp: 0,
      level: 1,
    );
    balance = 60;
    savings = 0;
    goalName = 'Велосипед';
    goalTarget = 300;
    day = 1;
    inventory = {'milk': 1, 'soap': 1, 'ball': 1};
    questsDone = {};
    questGivenDay = 1;
    lastBonusDate = _today();
    onboardingDone = true;
    justFinishedOnboarding = true;
    notifyListeners();
    await save();
  }

  void _addXp(int amount) {
    final p = pet;
    if (p == null || amount <= 0) return;
    p.xp += amount;
    while (p.xp >= 100) {
      p.xp -= 100;
      p.level += 1;
    }
  }

  /// Использовать предмет из инвентаря.
  /// Возвращает текст эффекта или null, если предмета нет.
  String? useItem(String itemId) {
    final count = inventory[itemId] ?? 0;
    final p = pet;
    if (count <= 0 || p == null) return null;
    final item = shopCatalog.firstWhere((e) => e.id == itemId);
    inventory[itemId] = count - 1;
    p.hunger = _stat(p.hunger + item.hunger);
    p.happiness = _stat(p.happiness + item.happiness);
    p.cleanliness = _stat(p.cleanliness + item.cleanliness);
    _addXp(item.xp);
    notifyListeners();
    save();
    return item.effectText;
  }

  /// Купить предмет в рюкзачок. False — не хватило монет.
  bool buyItem(String itemId) {
    final item = shopCatalog.firstWhere((e) => e.id == itemId);
    if (balance < item.price) return false;
    balance -= item.price;
    inventory[itemId] = (inventory[itemId] ?? 0) + 1;
    notifyListeners();
    save();
    return true;
  }

  /// Положить монетки в копилку. False — не хватило монет.
  bool deposit(int amount) {
    if (amount <= 0 || balance < amount) return false;
    balance -= amount;
    savings += amount;
    _addXp(5);
    notifyListeners();
    save();
    return true;
  }

  /// Забрать монетки из копилки.
  bool withdraw(int amount) {
    if (amount <= 0 || savings < amount) return false;
    savings -= amount;
    balance += amount;
    notifyListeners();
    save();
    return true;
  }

  /// Переключить светлую/тёмную тему.
  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
    save();
  }

  void updateGoal(String name, int target) {
    if (name.trim().isNotEmpty) goalName = name.trim();
    if (target >= 50) goalTarget = target;
    notifyListeners();
    save();
  }

  /// Возраст меняется в настройках — ребёнок растёт, а игра остаётся.
  void updateAge(int age) {
    final p = profile;
    if (p == null || !PlayerProfile.isValidAge(age)) return;
    profile = p.copyWith(age: age);
    notifyListeners();
    save();
  }

  bool completeQuest(String id) {
    if (questsDone.contains(id)) return false;
    final quest = questsCatalog.firstWhere((e) => e.id == id);
    questsDone.add(id);
    balance += quest.reward;
    _addXp(10);
    questGivenDay = day;
    notifyListeners();
    save();
    return true;
  }

  /// Переход к следующему периоду («новый день»).
  /// Возвращает начисленный доход — для диалога-анимации.
  int nextDay() {
    final income = baseIncome;
    day += 1;
    balance += income;
    final p = pet;
    if (p != null) {
      p.hunger = _stat(p.hunger - 15);
      p.happiness = _stat(p.happiness - 10);
      p.cleanliness = _stat(p.cleanliness - 12);
    }
    notifyListeners();
    save();
    return income;
  }

  /// Мягкие уведомления-помощники от Финни для главного экрана.
  List<String> finnyHints() {
    final p = pet;
    if (p == null) return const ['Давай создадим питомца! 🐾'];
    final hints = <String>[];
    if (p.hunger <= 40) hints.add('Я проголодался! Покорми меня 🍎');
    if (p.cleanliness <= 40) hints.add('Мне нужно умыться! 🧼');
    if (p.happiness <= 40) hints.add('Мне скучно... Поиграем? ⚽');
    if (goalProgress >= 1) {
      hints.add('Ура! Мы накопили на «$goalName»! 🎉');
    } else if (goalProgress >= 0.5) {
      hints.add('Ура, мы накопили половину на цель! 🎉');
    }
    if (activeQuest != null && day - questGivenDay > 1) {
      hints.add('Давай выполним задание и получим монетки? ⭐');
    }
    if (hints.isEmpty) {
      hints.add('Ты молодец! Продолжай заботиться о ${p.name} 💛');
    }
    return hints;
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{
        'profile': profile?.toJson(),
        'pet': pet?.toJson(),
        'balance': balance,
        'savings': savings,
        'goalName': goalName,
        'goalTarget': goalTarget,
        'day': day,
        'onboardingDone': onboardingDone,
        'isDark': isDark,
        'inventory': inventory,
        'questsDone': questsDone.toList(),
        'questGivenDay': questGivenDay,
        'lastBonusDate': lastBonusDate,
      };
      await prefs.setString(_prefsKey, jsonEncode(data));
    } catch (_) {
      // Ошибка сохранения не должна ронять игру.
    }
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final profileJson = decoded['profile'];
      if (profileJson is Map<String, dynamic>) {
        profile = PlayerProfile.fromJson(profileJson);
      }
      final petJson = decoded['pet'];
      if (petJson is Map<String, dynamic>) {
        pet = Pet.fromJson(petJson);
      }

      int readInt(String key, int fallback) {
        final v = decoded[key];
        if (v is num) return v.toInt();
        return fallback;
      }

      balance = readInt('balance', 60);
      savings = readInt('savings', 0);
      final g = decoded['goalName'];
      if (g is String && g.isNotEmpty) goalName = g;
      goalTarget = readInt('goalTarget', 300);
      day = readInt('day', 1);
      onboardingDone = decoded['onboardingDone'] == true;
      isDark = decoded['isDark'] == true;

      final inv = <String, int>{};
      final rawInv = decoded['inventory'];
      if (rawInv is Map) {
        rawInv.forEach((k, v) {
          if (k is String && v is num) inv[k] = v.toInt();
        });
      }
      if (inv.isNotEmpty) inventory = inv;

      final rawQuests = decoded['questsDone'];
      if (rawQuests is List) {
        questsDone = rawQuests.whereType<String>().toSet();
      }
      questGivenDay = readInt('questGivenDay', 1);
      final lb = decoded['lastBonusDate'];
      if (lb is String) lastBonusDate = lb;
    } catch (_) {
      // Битый сейв — начинаем заново, но приложение живёт.
    }
  }

  /// Полный сброс (кнопка «Начать заново» в настройках).
  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
    profile = null;
    pet = null;
    balance = 60;
    savings = 0;
    goalName = 'Велосипед';
    goalTarget = 300;
    day = 1;
    onboardingDone = false;
    isDark = false;
    justFinishedOnboarding = false;
    inventory = {};
    questsDone = {};
    questGivenDay = 1;
    lastBonusDate = null;
    notifyListeners();
  }
}
