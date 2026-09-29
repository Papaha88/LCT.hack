import 'package:flutter/material.dart';

/// Вид питомца: 3 варианта.
enum PetType { cat, dog, penguin }

/// Окраска: 3 варианта на каждый вид.
/// Итого 3 x 3 = 9 комбинаций кастомизации.
enum PetVariant { v1, v2, v3 }

extension PetTypeInfo on PetType {
  String get title {
    switch (this) {
      case PetType.cat:
        return 'Кошечка';
      case PetType.dog:
        return 'Собачка';
      case PetType.penguin:
        return 'Пингвинчик';
    }
  }

  String get emoji {
    switch (this) {
      case PetType.cat:
        return '🐱';
      case PetType.dog:
        return '🐶';
      case PetType.penguin:
        return '🐧';
    }
  }
}

/// Настроение питомца: из него берутся мордочка, короткая фраза
/// и анимация модели. Главное — самое срочное: голод важнее скуки.
enum PetMood { joyful, calm, hungry, dirty, sad }

/// Эмоция модели — зависит только от счастья:
/// меньше 33 — грустный, больше 66 — весёлый, между — обычный.
/// Для каждой эмоции у модели свой ролик и постер.
enum PetEmotion { sad, normal, happy }

/// Пороги эмоций по счастью.
const int sadBelow = 33;
const int happyAbove = 66;

/// Этап взросления — по уровню питомца. У каждого этапа своя модель.
enum PetStage { baby, teen, adult }

/// С какого уровня питомец — подросток и взрослый.
const int teenLevel = 12;
const int adultLevel = 35;

extension PetStageInfo on PetStage {
  String get title {
    switch (this) {
      case PetStage.baby:
        return 'Малыш 🌱';
      case PetStage.teen:
        return 'Подросток 🌿';
      case PetStage.adult:
        return 'Взрослый 🌳';
    }
  }
}

extension PetMoodInfo on PetMood {
  String get emoji {
    switch (this) {
      case PetMood.joyful:
        return '😄';
      case PetMood.calm:
        return '🙂';
      case PetMood.hungry:
        return '😋';
      case PetMood.dirty:
        return '😣';
      case PetMood.sad:
        return '😢';
    }
  }

  /// Короткая фраза питомца — одна строка, без длинных объяснений.
  String get phrase {
    switch (this) {
      case PetMood.joyful:
        return 'Мне так хорошо!';
      case PetMood.calm:
        return 'Всё хорошо';
      case PetMood.hungry:
        return 'Хочу кушать';
      case PetMood.dirty:
        return 'Пора умыться';
      case PetMood.sad:
        return 'Мне грустно…';
    }
  }
}

/// Внешний вид комбинации «вид + окраска».
class PetLook {
  final String label;
  final Color bgStart;
  final Color bgEnd;
  final Color accent;

  const PetLook({
    required this.label,
    required this.bgStart,
    required this.bgEnd,
    required this.accent,
  });

  static PetLook of(PetType type, PetVariant variant) {
    if (type == PetType.cat) {
      if (variant == PetVariant.v1) {
        return const PetLook(
          label: 'Рыжик',
          bgStart: Color(0xFFFFE0B2),
          bgEnd: Color(0xFFFFB74D),
          accent: Color(0xFFE65100),
        );
      }
      if (variant == PetVariant.v2) {
        return const PetLook(
          label: 'Дымок',
          bgStart: Color(0xFFCFD8DC),
          bgEnd: Color(0xFF90A4B0),
          accent: Color(0xFF37474F),
        );
      }
      return const PetLook(
        label: 'Ночка',
        bgStart: Color(0xFFB0B3C6),
        bgEnd: Color(0xFF5C5F78),
        accent: Color(0xFF8D6E63),
      );
    }
    if (type == PetType.dog) {
      if (variant == PetVariant.v1) {
        return const PetLook(
          label: 'Шоколад',
          bgStart: Color(0xFFD7CCC8),
          bgEnd: Color(0xFFA1887F),
          accent: Color(0xFF4E342E),
        );
      }
      if (variant == PetVariant.v2) {
        return const PetLook(
          label: 'Карамель',
          bgStart: Color(0xFFFFE0B2),
          bgEnd: Color(0xFFFFCC80),
          accent: Color(0xFFEF6C00),
        );
      }
      return const PetLook(
        label: 'Уголёк',
        bgStart: Color(0xFFBDBDBD),
        bgEnd: Color(0xFF616161),
        accent: Color(0xFF212121),
      );
    }
    // Пингвинчик
    if (variant == PetVariant.v1) {
      return const PetLook(
        label: 'Морячок',
        bgStart: Color(0xFFBBDEFB),
        bgEnd: Color(0xFF64B5F6),
        accent: Color(0xFF0D47A1),
      );
    }
    if (variant == PetVariant.v2) {
      return const PetLook(
        label: 'Льдинка',
        bgStart: Color(0xFFE0F7FA),
        bgEnd: Color(0xFF80DEEA),
        accent: Color(0xFF006064),
      );
    }
    return const PetLook(
      label: 'Пончик',
      bgStart: Color(0xFFF8BBD0),
      bgEnd: Color(0xFFF48FB1),
      accent: Color(0xFFAD1457),
    );
  }
}

/// Питомец: внешность + состояние + развитие.
class Pet {
  PetType type;
  PetVariant variant;
  String name;

  /// Статы 0..100.
  int hunger;
  int happiness;
  int cleanliness;

  /// Опыт 0..99 внутри текущего уровня.
  int xp;

  /// Уровень. Этап взросления — см. [stageOf] (12 и 35 — пороги).
  int level;

  Pet({
    required this.type,
    required this.variant,
    required this.name,
    required this.hunger,
    required this.happiness,
    required this.cleanliness,
    required this.xp,
    required this.level,
  });

  /// Этап по уровню: до [teenLevel] — малыш, до [adultLevel] — подросток,
  /// дальше — взрослый.
  static PetStage stageOf(int level) {
    if (level < teenLevel) return PetStage.baby;
    if (level < adultLevel) return PetStage.teen;
    return PetStage.adult;
  }

  /// Название этапа. Статикой — чтобы экран нового уровня мог сравнить
  /// «было → стало» и показать смену этапа отдельным подарком.
  static String stageForLevel(int level) => stageOf(level).title;

  /// Этап взросления для главного экрана.
  String get stage => stageForLevel(level);

  /// Эмоция модели — только от счастья (см. [sadBelow], [happyAbove]).
  PetEmotion get emotion {
    if (happiness < sadBelow) return PetEmotion.sad;
    if (happiness > happyAbove) return PetEmotion.happy;
    return PetEmotion.normal;
  }

  /// Фраза в облачке: сначала срочная просьба (голод, умыться),
  /// иначе — то же, что показывает модель (грусть, радость, спокойствие).
  PetMood get mood {
    if (hunger <= 40) return PetMood.hungry;
    if (cleanliness <= 40) return PetMood.dirty;
    switch (emotion) {
      case PetEmotion.sad:
        return PetMood.sad;
      case PetEmotion.happy:
        return PetMood.joyful;
      case PetEmotion.normal:
        return PetMood.calm;
    }
  }

  /// Мордочка настроения (состояние дублируется текстом и эмодзи,
  /// а не только цветом — требование ТЗ).
  String get moodEmoji {
    final minStat = [hunger, happiness, cleanliness]
        .reduce((a, b) => a < b ? a : b);
    if (minStat <= 25) return '😟';
    if (minStat <= 60) return '🙂';
    return '😊';
  }

  /// Текстовая подсказка при тапе по питомцу.
  String moodText() {
    if (hunger <= 40) return '$name голоден! Покорми меня 🍎';
    if (cleanliness <= 40) return '$name хочет умыться! 🧼';
    if (happiness <= 40) return '$name скучает! Поиграем? ⚽';
    return '$name счастлив! 💛';
  }

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'variant': variant.index,
        'name': name,
        'hunger': hunger,
        'happiness': happiness,
        'cleanliness': cleanliness,
        'xp': xp,
        'level': level,
      };

  factory Pet.fromJson(Map<String, dynamic> json) {
    int readInt(String key, int fallback) {
      final v = json[key];
      if (v is num) return v.toInt();
      return fallback;
    }

    var typeIndex = readInt('type', 0);
    if (typeIndex < 0 || typeIndex >= PetType.values.length) typeIndex = 0;
    var variantIndex = readInt('variant', 0);
    if (variantIndex < 0 || variantIndex >= PetVariant.values.length) {
      variantIndex = 0;
    }

    return Pet(
      type: PetType.values[typeIndex],
      variant: PetVariant.values[variantIndex],
      name: (json['name'] as String?) ?? 'Питомец',
      hunger: readInt('hunger', 100),
      happiness: readInt('happiness', 100),
      cleanliness: readInt('cleanliness', 100),
      xp: readInt('xp', 0),
      level: readInt('level', 1),
    );
  }
}
