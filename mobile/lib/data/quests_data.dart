/// Каталог заданий. Активное задание = первое невыполненное.
/// Награда падает в баланс при нажатии «Готово».
class Quest {
  final String id;
  final String title;
  final String desc;
  final int reward;
  final String emoji;

  const Quest({
    required this.id,
    required this.title,
    required this.desc,
    required this.reward,
    required this.emoji,
  });
}

const List<Quest> questsCatalog = [
  Quest(
    id: 'feed',
    title: 'Покорми питомца',
    desc: 'Нажми на питомца и дай ему что-нибудь вкусное',
    reward: 15,
    emoji: '🍎',
  ),
  Quest(
    id: 'save',
    title: 'Отложи монетки',
    desc: 'Положи хотя бы 10 монет в копилку',
    reward: 20,
    emoji: '🐷',
  ),
  Quest(
    id: 'toy',
    title: 'Повеселись',
    desc: 'Поиграй с питомцем: дай ему мячик или мишку',
    reward: 25,
    emoji: '🧸',
  ),
];
