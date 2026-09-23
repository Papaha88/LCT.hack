/// Профиль игрока: пока только игровое имя.
/// Расширение: аватар, звук, выбранная тема.
class PlayerProfile {
  final String nickname;

  const PlayerProfile({required this.nickname});

  Map<String, dynamic> toJson() => {'nickname': nickname};

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final name = json['nickname'];
    return PlayerProfile(
      nickname: name is String && name.isNotEmpty ? name : 'Игрок',
    );
  }
}
