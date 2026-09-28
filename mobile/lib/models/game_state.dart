import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/goals_data.dart';
import '../data/lessons_data.dart';
import '../data/shop_data.dart';
import '../data/skins_data.dart';
import '../services/name_filter.dart';
import 'pet.dart';
import 'player_profile.dart';

int _stat(int v) => v < 0 ? 0 : (v > 100 ? 100 : v);

/// Доход за период для конкретного уровня: 40 + уровень × 10.
///
/// Уровень растёт — растёт доход. Это главная «плюшка» развития, ради неё
/// и стоит вкладывать монетки: об этом же говорит «Секрет игры».
int incomeForLevel(int level) => 40 + level * 10;

/// Сколько монет даём за каждый новый уровень.
const int levelUpCoins = 25;

/// Бонус за возвращение в новый день.
const int dailyBonus = 15;

/// Сколько питомец «тратит» за прошедший день.
const int dayHungerCost = 15;
const int dayHappinessCost = 10;
const int dayCleanlinessCost = 12;

/// Событие «питомец вырос».
///
/// Награда начисляется сразу, а событие ждёт в [GameState.pendingLevelUp],
/// пока экран нового уровня его не заберёт: так он не потеряется, если
/// опыт прилетел из другого экрана (копилка, задания).
class LevelUpEvent {
  /// Уровень до роста и после.
  final int fromLevel;
  final int toLevel;

  /// Монетки за рост — всего, если уровней набралось несколько.
  final int coins;

  const LevelUpEvent({
    required this.fromLevel,
    required this.toLevel,
    required this.coins,
  });

  int get levelsGained => toLevel - fromLevel;

  int get incomeFrom => incomeForLevel(fromLevel);
  int get incomeTo => incomeForLevel(toLevel);

  String get stageFrom => Pet.stageForLevel(fromLevel);
  String get stageTo => Pet.stageForLevel(toLevel);

  /// Сменился ли этап взросления — самый заметный результат роста.
  bool get stageChanged => stageFrom != stageTo;
}

/// Итоги перехода к новому периоду — из них собирается «бумажка» с подсчётом.
class DaySummary {
  /// Новый день.
  final int day;

  /// Сколько монет принёс день.
  final int income;

  /// Сколько на самом деле потратил питомец. Не номинальные «−15», а реальная
  /// просадка: если сытость была 10, потеряется 10, и в бумажке будет 10.
  final int hungerLost;
  final int happinessLost;
  final int cleanlinessLost;

  final int balance;
  final int savings;
  final String goalName;
  final int goalTarget;

  const DaySummary({
    required this.day,
    required this.income,
    required this.hungerLost,
    required this.happinessLost,
    required this.cleanlinessLost,
    required this.balance,
    required this.savings,
    required this.goalName,
    required this.goalTarget,
  });

  int get goalLeft {
    final left = goalTarget - savings;
    return left < 0 ? 0 : left;
  }
}

/// Итог ответа на задание с дороги.
class LessonResult {
  final bool correct;

  /// Монеты начислены только за первое верное решение.
  final int reward;

  /// Задание уже было решено раньше — награды нет, это повторение.
  final bool alreadySolved;

  const LessonResult({
    required this.correct,
    required this.reward,
    required this.alreadySolved,
  });
}

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
  String goalName = defaultGoal.title;
  String goalEmoji = defaultGoal.emoji;
  int goalTarget = defaultGoal.price;

  /// Текущий период («День N»).
  int day = 1;
  bool onboardingDone = false;

  /// Тёмная тема включена (переключатель 🌙/☀️ в шапке)?
  bool isDark = false;

  /// Одноразовый флаг: только что прошли онбординг — показать «Секрет игры».
  bool justFinishedOnboarding = false;

  /// id предмета -> количество.
  Map<String, int> inventory = {'milk': 1, 'soap': 1, 'ball': 1};

  /// Решённые задания с дорог «Математика» и «Финансы».
  Set<String> lessonsSolved = {};

  /// Временные задачи «Повтори»: задания, где ребёнок ошибся. Ошибка
  /// не отнимает прогресс — задание просто просит попробовать ещё раз.
  Set<String> lessonsRetry = {};

  /// Сколько всего было ошибок — для родительского режима.
  int lessonMistakes = 0;

  /// День последнего решённого задания (для подсказки «давно не решали»).
  int lessonGivenDay = 1;

  /// Дата последнего ежедневного бонуса (yyyy-MM-dd).
  String? lastBonusDate;

  /// Купленные скины (навсегда, не расходуются).
  Set<String> ownedSkins = {};

  /// Надетый скин; null — обычная окраска.
  String? skinId;

  /// «Огонёк»: сколько дней подряд ребёнок что-то делал в игре.
  int streak = 0;

  /// Дата последнего действия (yyyy-MM-dd) — для подсчёта огонька.
  String? lastActionDate;

  /// Счётчик действий за сессию: растёт на каждое действие, по нему
  /// огонёк в шапке вспыхивает. Не сохраняется.
  int actionPulse = 0;

  /// Бонус за возвращение, который ещё не показали на главной.
  /// Показывается плашкой, а не диалогом. Не сохраняется.
  int pendingBonus = 0;

  /// Новый уровень, который ещё не показали ребёнку: награда уже начислена,
  /// ждёт только экран. Живёт до перезапуска — показывать «поздравление»
  /// после холодного старта было бы странно.
  LevelUpEvent? pendingLevelUp;

  /// Доход за новый период. Растёт с уровнем питомца.
  int get baseIncome => incomeForLevel(pet?.level ?? 1);

  /// Забирает событие роста для экрана нового уровня.
  /// Возвращает null, если показывать нечего.
  LevelUpEvent? consumeLevelUp() {
    final event = pendingLevelUp;
    pendingLevelUp = null;
    return event;
  }

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

  /// Следующее задание, которое советует Финни: сначала «Повтори»,
  /// потом — нерешённое своего уровня, потом — любое нерешённое.
  Lesson? get nextLesson {
    for (final id in lessonsRetry) {
      final lesson = lessonById(id);
      if (lesson != null) return lesson;
    }
    for (final track in LessonTrack.values) {
      final grade = recommendedGrade(age, track);
      for (final l in lessonsOf(track)) {
        if (l.grade == grade && !lessonsSolved.contains(l.id)) return l;
      }
    }
    for (final l in lessonsCatalog) {
      if (!lessonsSolved.contains(l.id)) return l;
    }
    return null;
  }

  /// Сколько заданий решено на дороге.
  int solvedOn(LessonTrack track) =>
      lessonsOf(track).where((l) => lessonsSolved.contains(l.id)).length;

  /// Цена предмета с учётом «скидки дня».
  int priceOf(ShopItem item) =>
      item.id == dealOfDay(day).id ? dealPrice(item) : item.price;

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
    balance += dailyBonus;
    pendingBonus = dailyBonus;
    notifyListeners();
    save();
    return true;
  }

  /// Плашку бонуса закрыли.
  void dismissBonus() {
    if (pendingBonus == 0) return;
    pendingBonus = 0;
    notifyListeners();
  }

  /// Любое полезное действие: кормление, покупка, копилка, задание.
  /// Первое действие за календарный день продлевает огонёк.
  void _registerAction() {
    actionPulse += 1;
    final today = _today();
    if (lastActionDate == today) return;
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    streak = lastActionDate == yesterday ? streak + 1 : 1;
    lastActionDate = today;
  }

  /// Огонёк горит, если сегодня уже было действие.
  bool get streakLitToday => lastActionDate == _today();

  /// Скин, надетый на питомца (только своего вида).
  PetSkin? get skin {
    final s = skinById(skinId);
    if (s == null || s.type != pet?.type) return null;
    return s;
  }

  /// Купить скин. False — не хватило монет или уже куплен.
  bool buySkin(String id) {
    final s = skinById(id);
    if (s == null || ownedSkins.contains(id) || balance < s.price) {
      return false;
    }
    balance -= s.price;
    ownedSkins.add(id);
    skinId = id;
    _registerAction();
    notifyListeners();
    save();
    return true;
  }

  /// Надеть купленный скин или снять (null).
  void equipSkin(String? id) {
    if (id != null && !ownedSkins.contains(id)) return;
    skinId = id;
    notifyListeners();
    save();
  }

  // ───── Режим разработчика (скрыт в настройках) ─────

  /// Опыт без прокрутки дней. Уровень и награды — как в обычной игре.
  void devAddXp(int amount) {
    _addXp(amount);
    notifyListeners();
    save();
  }

  void devAddCoins(int amount) {
    balance += amount;
    notifyListeners();
    save();
  }

  /// Статы питомца на 100 — чтобы проверять экраны без кормления.
  void devRestorePet() {
    final p = pet;
    if (p == null) return;
    p.hunger = 100;
    p.happiness = 100;
    p.cleanliness = 100;
    notifyListeners();
    save();
  }

  /// Статы питомца на минимум — проверить грустное настроение.
  void devDrainPet() {
    final p = pet;
    if (p == null) return;
    p.hunger = 10;
    p.happiness = 10;
    p.cleanliness = 10;
    notifyListeners();
    save();
  }

  Future<void> createProfile({
    required String nickname,
    required int age,
    required PetType type,
    required PetVariant variant,
    required String petName,
  }) async {
    // Экраны онбординга уже не пускают мат, но сейв защищаем и здесь.
    profile = PlayerProfile(
      nickname: NameFilter.isAllowed(nickname) ? nickname : 'Игрок',
      age: age,
    );
    pet = Pet(
      type: type,
      variant: variant,
      name: NameFilter.isAllowed(petName) ? petName : 'Питомец',
      hunger: 100,
      happiness: 100,
      cleanliness: 100,
      xp: 0,
      level: 1,
    );
    balance = 60;
    savings = 0;
    goalName = defaultGoal.title;
    goalEmoji = defaultGoal.emoji;
    goalTarget = defaultGoal.price;
    day = 1;
    inventory = {'milk': 1, 'soap': 1, 'ball': 1};
    lessonsSolved = {};
    lessonsRetry = {};
    lessonMistakes = 0;
    lessonGivenDay = 1;
    ownedSkins = {};
    skinId = null;
    streak = 0;
    lastActionDate = null;
    lastBonusDate = _today();
    pendingLevelUp = null;
    onboardingDone = true;
    justFinishedOnboarding = true;
    notifyListeners();
    await save();
  }

  /// Начисляет опыт. Если питомец дорос до нового уровня — сразу выдаёт
  /// награду и запоминает событие, чтобы экран мог его показать.
  ///
  /// Доход за день растёт сам (он считается от уровня), отдельно его
  /// повышать не нужно — экран просто показывает разницу.
  void _addXp(int amount) {
    final p = pet;
    if (p == null || amount <= 0) return;
    final fromLevel = p.level;
    p.xp += amount;
    while (p.xp >= 100) {
      p.xp -= 100;
      p.level += 1;
    }
    if (p.level == fromLevel) return;

    final gained = p.level - fromLevel;
    final coins = levelUpCoins * gained;
    balance += coins;
    p.hunger = 100;
    p.happiness = 100;
    p.cleanliness = 100;
    pendingLevelUp = LevelUpEvent(
      fromLevel: fromLevel,
      toLevel: p.level,
      coins: coins,
    );
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
    _registerAction();
    notifyListeners();
    save();
    return item.effectText;
  }

  /// Купить предмет в рюкзачок. False — не хватило монет.
  bool buyItem(String itemId) {
    final item = shopCatalog.firstWhere((e) => e.id == itemId);
    final price = priceOf(item);
    if (balance < price) return false;
    balance -= price;
    inventory[itemId] = (inventory[itemId] ?? 0) + 1;
    _registerAction();
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
    _registerAction();
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

  /// Сменить цель копилки: готовую из списка или свою.
  /// Накопленное остаётся в копилке — меняется только то, на что копим.
  /// False — цель не подходит (пустое название или слишком мало монет).
  bool updateGoal(String name, int target, {String? emoji}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || target < minGoalTarget || target > maxGoalTarget) {
      return false;
    }
    goalName = trimmed;
    goalTarget = target;
    if (emoji != null && emoji.isNotEmpty) goalEmoji = emoji;
    notifyListeners();
    save();
    return true;
  }

  /// Возраст меняется в настройках — ребёнок растёт, а игра остаётся.
  void updateAge(int age) {
    final p = profile;
    if (p == null || !PlayerProfile.isValidAge(age)) return;
    profile = p.copyWith(age: age);
    notifyListeners();
    save();
  }

  /// Ответ на задание с дороги.
  ///
  /// Верно в первый раз — монеты и опыт. Ошибка ничего не отнимает:
  /// задание становится временной задачей «Повтори», пока его не решат.
  LessonResult answerLesson(String id, int choice) {
    final lesson = lessonById(id);
    if (lesson == null) {
      return const LessonResult(
          correct: false, reward: 0, alreadySolved: false);
    }
    final already = lessonsSolved.contains(id);
    final correct = choice == lesson.correct;
    var reward = 0;
    if (correct) {
      lessonsRetry.remove(id);
      if (!already) {
        lessonsSolved.add(id);
        reward = lesson.reward;
        balance += reward;
        _addXp(lessonXp);
        lessonGivenDay = day;
      }
      _registerAction();
    } else if (!already) {
      lessonsRetry.add(id);
      lessonMistakes += 1;
    }
    notifyListeners();
    save();
    return LessonResult(
      correct: correct,
      reward: reward,
      alreadySolved: already,
    );
  }

  /// Родительский режим: пройти дороги заново (монеты и питомец остаются).
  void resetLessons() {
    lessonsSolved = {};
    lessonsRetry = {};
    lessonMistakes = 0;
    lessonGivenDay = day;
    notifyListeners();
    save();
  }

  /// Переход к следующему периоду («новый день»).
  /// Возвращает итоги — из них собирается «бумажка» с подсчётом.
  DaySummary nextDay() {
    final income = baseIncome;
    day += 1;
    balance += income;

    var hungerLost = 0;
    var happinessLost = 0;
    var cleanlinessLost = 0;
    final p = pet;
    if (p != null) {
      final hungerBefore = p.hunger;
      final happinessBefore = p.happiness;
      final cleanlinessBefore = p.cleanliness;
      p.hunger = _stat(p.hunger - dayHungerCost);
      p.happiness = _stat(p.happiness - dayHappinessCost);
      p.cleanliness = _stat(p.cleanliness - dayCleanlinessCost);
      hungerLost = hungerBefore - p.hunger;
      happinessLost = happinessBefore - p.happiness;
      cleanlinessLost = cleanlinessBefore - p.cleanliness;
    }
    notifyListeners();
    save();
    return DaySummary(
      day: day,
      income: income,
      hungerLost: hungerLost,
      happinessLost: happinessLost,
      cleanlinessLost: cleanlinessLost,
      balance: balance,
      savings: savings,
      goalName: goalName,
      goalTarget: goalTarget,
    );
  }

  /// Одна короткая подсказка Финни для главного экрана или null.
  ///
  /// Голод, грязь и скуку показывает сам питомец (настроение), поэтому
  /// здесь только то, чего по нему не видно: цель и задания.
  String? finnyTip() {
    if (pet == null) return null;
    if (goalProgress >= 1) return 'Цель «$goalName» накоплена! 🎉';
    if (lessonsRetry.isNotEmpty) return 'Попробуем задание ещё раз? 🔁';
    if (nextLesson != null && day - lessonGivenDay > 1) {
      return 'Реши задание — получишь монетки ⭐';
    }
    return null;
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
        'goalEmoji': goalEmoji,
        'goalTarget': goalTarget,
        'day': day,
        'onboardingDone': onboardingDone,
        'isDark': isDark,
        'inventory': inventory,
        'lessonsSolved': lessonsSolved.toList(),
        'lessonsRetry': lessonsRetry.toList(),
        'lessonMistakes': lessonMistakes,
        'lessonGivenDay': lessonGivenDay,
        'lastBonusDate': lastBonusDate,
        'ownedSkins': ownedSkins.toList(),
        'skinId': skinId,
        'streak': streak,
        'lastActionDate': lastActionDate,
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
      final ge = decoded['goalEmoji'];
      if (ge is String && ge.isNotEmpty) goalEmoji = ge;
      goalTarget = readInt('goalTarget', defaultGoal.price);
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

      Set<String> readIds(String key) {
        final raw = decoded[key];
        if (raw is! List) return {};
        // Задания, которых больше нет в каталоге, просто пропускаем.
        return raw
            .whereType<String>()
            .where((id) => lessonById(id) != null)
            .toSet();
      }

      lessonsSolved = readIds('lessonsSolved');
      lessonsRetry = readIds('lessonsRetry')..removeAll(lessonsSolved);
      lessonMistakes = readInt('lessonMistakes', 0);
      lessonGivenDay = readInt('lessonGivenDay', 1);
      final lb = decoded['lastBonusDate'];
      if (lb is String) lastBonusDate = lb;

      final rawSkins = decoded['ownedSkins'];
      if (rawSkins is List) {
        ownedSkins = rawSkins
            .whereType<String>()
            .where((id) => skinById(id) != null)
            .toSet();
      }
      final sk = decoded['skinId'];
      skinId = sk is String && ownedSkins.contains(sk) ? sk : null;
      streak = readInt('streak', 0);
      final la = decoded['lastActionDate'];
      if (la is String) lastActionDate = la;
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
    goalName = defaultGoal.title;
    goalEmoji = defaultGoal.emoji;
    goalTarget = defaultGoal.price;
    day = 1;
    onboardingDone = false;
    isDark = false;
    justFinishedOnboarding = false;
    inventory = {};
    lessonsSolved = {};
    lessonsRetry = {};
    lessonMistakes = 0;
    lessonGivenDay = 1;
    ownedSkins = {};
    skinId = null;
    streak = 0;
    lastActionDate = null;
    actionPulse = 0;
    pendingBonus = 0;
    lastBonusDate = null;
    pendingLevelUp = null;
    notifyListeners();
  }
}
