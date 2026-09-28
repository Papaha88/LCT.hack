/// Готовые цели для копилки. Ребёнок может выбрать любую из них
/// или придумать свою (название, картинка, сколько монет).
class GoalPreset {
  final String title;
  final String emoji;
  final int price;

  /// Короткий совет Финни: сколько откладывать и как долго.
  final String hint;

  const GoalPreset({
    required this.title,
    required this.emoji,
    required this.price,
    required this.hint,
  });
}

/// Границы своей цели: меньше — копить неинтересно, больше — слишком долго.
const int minGoalTarget = 50;
const int maxGoalTarget = 5000;

const List<GoalPreset> goalPresets = [
  GoalPreset(
    title: 'Домик для питомца',
    emoji: '🏠',
    price: 150,
    hint: 'Первая мечта: по 50 монет — и через 3 дня домик твой!',
  ),
  GoalPreset(
    title: 'Самокат',
    emoji: '🛴',
    price: 200,
    hint: 'По 50 монет за день — самокат через 4 дня.',
  ),
  GoalPreset(
    title: 'Велосипед',
    emoji: '🚲',
    price: 300,
    hint: 'Большая цель! Откладывай понемногу, но каждый день.',
  ),
  GoalPreset(
    title: 'Поход в аквапарк',
    emoji: '🎢',
    price: 500,
    hint: 'Самая дальняя мечта — понадобится терпение.',
  ),
  GoalPreset(
    title: 'Железная дорога',
    emoji: '🚂',
    price: 250,
    hint: 'Монетка к монетке — как вагончик к вагончику.',
  ),
  GoalPreset(
    title: 'Подарок маме',
    emoji: '🎁',
    price: 120,
    hint: 'Копить на подарок близким — особенно приятно!',
  ),
];

/// Цель по умолчанию для нового профиля.
const GoalPreset defaultGoal = GoalPreset(
  title: 'Велосипед',
  emoji: '🚲',
  price: 300,
  hint: 'Большая цель! Откладывай понемногу, но каждый день.',
);

/// Картинки для своей цели — выбор кнопками, без клавиатуры.
const List<String> goalEmojiChoices = [
  '🎯', '🚲', '🛴', '🎮', '🧸', '📚', '⚽', '🎨', '🎧', '🎁', '🐠', '🏕️',
];
