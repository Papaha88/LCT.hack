import 'package:flutter/material.dart';

import '../models/pet.dart';

/// Скины (образы) питомца: по три на каждый вид.
///
/// Пока моделей нет, скин рисуется заглушкой: фон своего цвета и значок
/// образа поверх эмодзи питомца. Когда появятся анимированные модели
/// (webp), их достаточно положить в `assets/pets/<вид>/<id скина>/` —
/// код менять не нужно (см. `lib/services/pet_assets.dart`).
class PetSkin {
  final String id;
  final PetType type;
  final String title;

  /// Значок-заглушка образа (пока нет модели).
  final String emoji;
  final int price;
  final String description;
  final Color bgStart;
  final Color bgEnd;

  const PetSkin({
    required this.id,
    required this.type,
    required this.title,
    required this.emoji,
    required this.price,
    required this.description,
    required this.bgStart,
    required this.bgEnd,
  });
}

const List<PetSkin> skinsCatalog = [
  // Кошечка
  PetSkin(
    id: 'cat_astronaut',
    type: PetType.cat,
    title: 'Космонавт',
    emoji: '🚀',
    price: 60,
    description: 'Летим к звёздам!',
    bgStart: Color(0xFFB3C7FF),
    bgEnd: Color(0xFF5C6BC0),
  ),
  PetSkin(
    id: 'cat_princess',
    type: PetType.cat,
    title: 'Принцесса',
    emoji: '👑',
    price: 90,
    description: 'Настоящая королевская особа.',
    bgStart: Color(0xFFFFD1E8),
    bgEnd: Color(0xFFF06292),
  ),
  PetSkin(
    id: 'cat_detective',
    type: PetType.cat,
    title: 'Детектив',
    emoji: '🔍',
    price: 140,
    description: 'Найдёт каждую потерянную монетку.',
    bgStart: Color(0xFFD7CCC8),
    bgEnd: Color(0xFF8D6E63),
  ),
  // Собачка
  PetSkin(
    id: 'dog_firefighter',
    type: PetType.dog,
    title: 'Пожарный',
    emoji: '🚒',
    price: 60,
    description: 'Всегда спешит на помощь.',
    bgStart: Color(0xFFFFCDD2),
    bgEnd: Color(0xFFE53935),
  ),
  PetSkin(
    id: 'dog_football',
    type: PetType.dog,
    title: 'Футболист',
    emoji: '⚽',
    price: 90,
    description: 'Гол! И ещё один!',
    bgStart: Color(0xFFC8E6C9),
    bgEnd: Color(0xFF43A047),
  ),
  PetSkin(
    id: 'dog_chef',
    type: PetType.dog,
    title: 'Повар',
    emoji: '🍳',
    price: 140,
    description: 'Готовит самый вкусный обед.',
    bgStart: Color(0xFFFFF3C4),
    bgEnd: Color(0xFFFFB300),
  ),
  // Пингвинчик
  PetSkin(
    id: 'penguin_sailor',
    type: PetType.penguin,
    title: 'Капитан',
    emoji: '⚓',
    price: 60,
    description: 'Полный вперёд!',
    bgStart: Color(0xFFB3E5FC),
    bgEnd: Color(0xFF0288D1),
  ),
  PetSkin(
    id: 'penguin_scientist',
    type: PetType.penguin,
    title: 'Учёный',
    emoji: '🔬',
    price: 90,
    description: 'Изучает, как растут монетки.',
    bgStart: Color(0xFFE1BEE7),
    bgEnd: Color(0xFF8E24AA),
  ),
  PetSkin(
    id: 'penguin_rockstar',
    type: PetType.penguin,
    title: 'Рок-звезда',
    emoji: '🎸',
    price: 140,
    description: 'Зажигает на сцене!',
    bgStart: Color(0xFFFFE0B2),
    bgEnd: Color(0xFFFF7043),
  ),
];

List<PetSkin> skinsFor(PetType type) =>
    skinsCatalog.where((s) => s.type == type).toList();

PetSkin? skinById(String? id) {
  if (id == null) return null;
  for (final s in skinsCatalog) {
    if (s.id == id) return s;
  }
  return null;
}
