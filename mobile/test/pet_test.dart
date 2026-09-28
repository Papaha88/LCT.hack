import 'package:flutter_test/flutter_test.dart';
import 'package:finny_pet/models/pet.dart';
import 'package:finny_pet/models/player_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('окраски питомца', () {
    test('все 9 названий читаются, без битых символов', () {
      expect(PetType.values.length * PetVariant.values.length, 9);

      for (final type in PetType.values) {
        for (final variant in PetVariant.values) {
          final label = PetLook.of(type, variant).label;
          expect(label, isNotEmpty);
          // � и «*» появлялись из-за сохранения файла в неверной кодировке —
          // именно их видел ребёнок на слайде окрасок.
          expect(
            label.contains('�'),
            isFalse,
            reason: 'битый символ в названии окраски: $label',
          );
          expect(
            label.contains('*'),
            isFalse,
            reason: 'лишний символ в названии окраски: $label',
          );
        }
      }
    });

    test('названия совпадают с README', () {
      expect(PetLook.of(PetType.cat, PetVariant.v1).label, 'Рыжик');
      expect(PetLook.of(PetType.cat, PetVariant.v2).label, 'Дымок');
      expect(PetLook.of(PetType.cat, PetVariant.v3).label, 'Снежок');
      expect(PetLook.of(PetType.dog, PetVariant.v1).label, 'Шоколад');
      expect(PetLook.of(PetType.dog, PetVariant.v2).label, 'Карамель');
      expect(PetLook.of(PetType.dog, PetVariant.v3).label, 'Уголёк');
      expect(PetLook.of(PetType.penguin, PetVariant.v1).label, 'Морячок');
      expect(PetLook.of(PetType.penguin, PetVariant.v2).label, 'Льдинка');
      expect(PetLook.of(PetType.penguin, PetVariant.v3).label, 'Пончик');
    });
  });

  group('возраст игрока', () {
    test('варианты 7, 8, 9 и 10+ принимаются', () {
      for (final age in PlayerProfile.ageChoices) {
        expect(PlayerProfile.isValidAge(age), isTrue);
      }
      expect(PlayerProfile.ageChoices, [7, 8, 9, 10]);
    });

    test('вне диапазона отбрасывается', () {
      expect(PlayerProfile.isValidAge(6), isFalse);
      expect(PlayerProfile.isValidAge(11), isFalse);
    });

    test('«9 лет» и «10+ лет» пишутся без ошибок', () {
      expect(const PlayerProfile(nickname: 'Кирилл', age: 9).ageText, '9 лет');
      expect(
          const PlayerProfile(nickname: 'Кирилл', age: 10).ageText, '10+ лет');
      expect(const PlayerProfile(nickname: 'Кирилл').ageText, '');
    });

    test('старый сейв с 11 годами превращается в 10+', () {
      final old = PlayerProfile.fromJson({'nickname': 'Кирилл', 'age': 11});
      expect(old.age, 10);
      expect(old.ageText, '10+ лет');
    });

    test('сейв без возраста и с битым возрастом не ломает загрузку', () {
      final withoutAge = PlayerProfile.fromJson({'nickname': 'Кирилл'});
      expect(withoutAge.age, isNull);

      final broken = PlayerProfile.fromJson({'nickname': 'Кирилл', 'age': 42});
      expect(broken.age, isNull);

      final ok = PlayerProfile.fromJson({'nickname': 'Кирилл', 'age': 10});
      expect(ok.age, 10);
    });
  });
}
