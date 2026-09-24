/// Профиль игрока: игровое имя и возраст ребёнка.
/// Возраст спрашиваем в онбординге и показываем на главном экране —
/// по нему видно, что приложение подходит ребёнку по возрасту.
class PlayerProfile {
  final String nickname;

  /// Возраст ребёнка в годах. `null` — старый сейв, где возраста ещё не было.
  final int? age;

  const PlayerProfile({required this.nickname, this.age});

  /// Игра по ТЗ — для детей 7–11 лет. За пределами диапазона не пускаем.
  static const int minAge = 7;
  static const int maxAge = 11;

  /// Варианты для выбора — без клавиатуры, ребёнку так проще.
  static const List<int> ageChoices = [7, 8, 9, 10, 11];

  static bool isValidAge(int age) => age >= minAge && age <= maxAge;

  /// «9 лет» — для 7–11 форма всегда «лет», отдельные правила не нужны.
  String get ageText => age == null ? '' : '$age лет';

  PlayerProfile copyWith({String? nickname, int? age}) => PlayerProfile(
        nickname: nickname ?? this.nickname,
        age: age ?? this.age,
      );

  Map<String, dynamic> toJson() => {'nickname': nickname, 'age': age};

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final name = json['nickname'];
    final rawAge = json['age'];
    final parsedAge = rawAge is num ? rawAge.toInt() : null;
    return PlayerProfile(
      nickname: name is String && name.isNotEmpty ? name : 'Игрок',
      age: parsedAge != null && isValidAge(parsedAge) ? parsedAge : null,
    );
  }
}
