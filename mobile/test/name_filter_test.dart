import 'package:flutter_test/flutter_test.dart';

import 'package:finny_pet/services/name_filter.dart';

void main() {
  test('обычные имена и клички проходят', () {
    const ok = [
      'Кирилл', 'Глеб', 'Аманда', 'Максим', 'Max', 'Alex', 'Ребус',
      'Мурзик', 'Барсик', 'Снежок', 'Рекс', 'Шарик', 'Пушок', 'Кексик',
      'Звёздочка', 'Тимошка', 'Пушистик', 'Педро', 'Вадик', 'Радик',
      'Сабля', 'Барсук', 'Страх', 'Эпоха', 'Команда', 'Мандарин',
      'Ребёнок', 'Себастьян', 'Хлебушек', 'Дебаты', 'Canal', 'Nick',
      'Бенедикт', 'Кузя', 'Соня', 'Лиза', 'Хасан', 'Сухарик', 'Шерхан',
    ];
    for (final name in ok) {
      expect(NameFilter.isAllowed(name), isTrue, reason: name);
    }
  });

  test('мат и 18+ не проходят, в том числе с обходами', () {
    const bad = [
      'хуй', 'Хуйло', 'х.у.й', 'ХУУУЙ', 'xyй', 'huy', 'пизда', 'п1зда',
      'pizda', 'ебать', 'Заебал', 'блядь', 'blyat', 'Бля', 'сука', 'cyka',
      'suka', 'мудак', 'пидор', 'гандон', 'залупа', 'шлюха', 'дрочер',
      'говно', 'жопа', 'секс', 'Порно', 'sexy', 'fuck', 'FuCk', 'shit',
      'bitch', 'dick', 'член', 'сиськи', 'Трахать', 'наркоман', 'пиво',
      'ё6аный', 'Ребёнок-хуй',
    ];
    for (final name in bad) {
      expect(NameFilter.isAllowed(name), isFalse, reason: name);
    }
  });

  test('скелет убирает разделители, повторы и латиницу', () {
    expect(NameFilter.normalize('Х..У..Й'), 'хуй');
    expect(NameFilter.normalize('cyyyka'), 'сука');
    expect(NameFilter.normalize('blyat'), 'блят');
  });
}
