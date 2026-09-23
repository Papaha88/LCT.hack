/// Каталог магазина. Купленное падает в рюкзачок,
/// эффекты применяются при использовании (тап по питомцу на главном экране).
enum ItemKind { food, hygiene, fun }

extension ItemKindInfo on ItemKind {
  String get title {
    switch (this) {
      case ItemKind.food:
        return 'Еда';
      case ItemKind.hygiene:
        return 'Уход';
      case ItemKind.fun:
        return 'Игры';
    }
  }

  String get emoji {
    switch (this) {
      case ItemKind.food:
        return '🍎';
      case ItemKind.hygiene:
        return '🧼';
      case ItemKind.fun:
        return '⚽';
    }
  }
}

class ShopItem {
  final String id;
  final String title;
  final String emoji;
  final int price;
  final ItemKind kind;

  /// Прирост статов при использовании.
  final int hunger;
  final int happiness;
  final int cleanliness;
  final int xp;
  final String effectText;

  const ShopItem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.price,
    required this.kind,
    this.hunger = 0,
    this.happiness = 0,
    this.cleanliness = 0,
    this.xp = 5,
    required this.effectText,
  });
}

const List<ShopItem> shopCatalog = [
  ShopItem(
    id: 'milk',
    title: 'Молочко',
    emoji: '🥛',
    price: 10,
    kind: ItemKind.food,
    hunger: 20,
    effectText: 'Вкусно! +20 к сытости 🥛',
  ),
  ShopItem(
    id: 'apple',
    title: 'Яблочко',
    emoji: '🍎',
    price: 8,
    kind: ItemKind.food,
    hunger: 15,
    happiness: 5,
    effectText: 'Хрум-хрум! +15 к сытости 🍎',
  ),
  ShopItem(
    id: 'cookie',
    title: 'Печенька',
    emoji: '🍪',
    price: 15,
    kind: ItemKind.food,
    hunger: 25,
    happiness: 10,
    effectText: 'Ням! +25 к сытости 🍪',
  ),
  ShopItem(
    id: 'soap',
    title: 'Мыло',
    emoji: '🧼',
    price: 12,
    kind: ItemKind.hygiene,
    cleanliness: 25,
    effectText: 'Чистота! +25 к чистоте 🧼',
  ),
  ShopItem(
    id: 'ball',
    title: 'Мячик',
    emoji: '⚽',
    price: 20,
    kind: ItemKind.fun,
    happiness: 25,
    effectText: 'Весело! +25 к счастью ⚽',
  ),
  ShopItem(
    id: 'teddy',
    title: 'Плюшевый мишка',
    emoji: '🧸',
    price: 40,
    kind: ItemKind.fun,
    happiness: 40,
    xp: 10,
    effectText: 'Обнимашки! +40 к счастью 🧸',
  ),
];
