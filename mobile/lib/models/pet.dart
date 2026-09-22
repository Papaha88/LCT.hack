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
        label: 'Снежо�*',
        bgStart: Color(0xFFFFF8E1),
        bgEnd: Color(0xFFFFECB3),
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
        label: 'Уголё�*',
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

  /// Уровень. 1 = Малыш, 2 = Подросток, 3+ = Взрослый.
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

  /// Этап взросления для главного экрана.
  String get stage {
    if (level <= 1) return 'Малыш 🌱';
    if (level == 2) return 'Подросток 🌿';
    return 'Взрослый 🌳';
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
