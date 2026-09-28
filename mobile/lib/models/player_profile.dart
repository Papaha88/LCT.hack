/// Профиль игрока: игровое имя и возраст ребёнка.
/// Возраст спрашиваем в онбординге и показываем на главном экране.
/// По нему же подбираем рекомендованный уровень заданий.
class PlayerProfile {
  final String nickname;

  /// Возраст ребёнка в годах. `null` — старый сейв, где возраста ещё не было.
  /// Всё, что старше 10, хранится как 10 и показывается как «10+ лет».
  final int? age;

  const PlayerProfile({required this.nickname, this.age});

  /// Младший возраст — 7 лет, старший — «10+»: дальше отдельные ступени
  /// не нужны, задания у старших всё равно одни.
  static const int minAge = 7;
  static const int maxAge = 10;

  /// Варианты для выбора — без клавиатуры, ребёнку так проще.
  /// Последний вариант (10) показывается как «10+ лет».
  static const List<int> ageChoices = [7, 8, 9, 10];

  static bool isValidAge(int age) => age >= minAge && age <= maxAge;

  /// Подпись возраста: «9 лет», а для старшей ступени — «10+ лет».
  static String labelFor(int age) => age >= maxAge ? '$maxAge+ лет' : '$age лет';

  String get ageText => age == null ? '' : labelFor(age!);

  PlayerProfile copyWith({String? nickname, int? age}) => PlayerProfile(
        nickname: nickname ?? this.nickname,
        age: age ?? this.age,
      );

  Map<String, dynamic> toJson() => {'nickname': nickname, 'age': age};

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final name = json['nickname'];
    final rawAge = json['age'];
    var parsedAge = rawAge is num ? rawAge.toInt() : null;
    // Старые сейвы хранили «11 лет» отдельно — теперь это «10+».
    if (parsedAge == 11) parsedAge = maxAge;
    return PlayerProfile(
      nickname: name is String && name.isNotEmpty ? name : 'Игрок',
      age: parsedAge != null && isValidAge(parsedAge) ? parsedAge : null,
    );
  }
}
