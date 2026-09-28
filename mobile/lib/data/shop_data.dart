/// Каталог магазина. Купленное падает в рюкзачок,
/// эффекты применяются при использовании (тап по питомцу на главном экране).
///
/// Отделы делятся на «Надо» (обязательные траты: еда, уход, здоровье)
/// и «Хочу» (игрушки, наряды, уют) — ребёнок видит разницу прямо на ценнике.
enum ItemKind { food, hygiene, health, fun, clothes, home }

extension ItemKindInfo on ItemKind {
  String get title {
    switch (this) {
      case ItemKind.food:
        return 'Еда';
      case ItemKind.hygiene:
        return 'Уход';
      case ItemKind.health:
        return 'Здоровье';
      case ItemKind.fun:
        return 'Игры';
      case ItemKind.clothes:
        return 'Наряды';
      case ItemKind.home:
        return 'Уют';
    }
  }

  String get emoji {
    switch (this) {
      case ItemKind.food:
        return '🍎';
      case ItemKind.hygiene:
        return '🧼';
      case ItemKind.health:
        return '💊';
      case ItemKind.fun:
        return '⚽';
      case ItemKind.clothes:
        return '🎀';
      case ItemKind.home:
        return '🛏️';
    }
  }

  /// Обязательная трата («надо») или желание («хочу»).
  bool get mandatory =>
      this == ItemKind.food ||
      this == ItemKind.hygiene ||
      this == ItemKind.health;
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

  /// Ярлык на карточке: «Хит», «Новинка», «Редкое»…
  final String? badge;

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
    this.badge,
  });

  bool get mandatory => kind.mandatory;
}

/// Скидка дня в процентах.
const int dealPercent = 30;

/// Товар со скидкой: каждый день новый, чтобы в магазин хотелось заглянуть.
ShopItem dealOfDay(int day) {
  final index = (day * 7 + 3) % shopCatalog.length;
  return shopCatalog[index];
}

int dealPrice(ShopItem item) {
  final price = (item.price * (100 - dealPercent) / 100).round();
  return price < 1 ? 1 : price;
}

const List<ShopItem> shopCatalog = [
  // ───── Еда ─────
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
    id: 'carrot',
    title: 'Морковка',
    emoji: '🥕',
    price: 6,
    kind: ItemKind.food,
    hunger: 10,
    effectText: 'Полезно и дёшево! +10 к сытости 🥕',
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
    badge: 'Хит',
  ),
  ShopItem(
    id: 'fish',
    title: 'Рыбка',
    emoji: '🐟',
    price: 18,
    kind: ItemKind.food,
    hunger: 30,
    happiness: 5,
    effectText: 'Свежая рыбка! +30 к сытости 🐟',
  ),
  ShopItem(
    id: 'dinner',
    title: 'Полноценный обед',
    emoji: '🍲',
    price: 25,
    kind: ItemKind.food,
    hunger: 50,
    effectText: 'Сытно! +50 к сытости 🍲',
    badge: 'Выгодно',
  ),

  // ───── Уход ─────
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
    id: 'shower',
    title: 'Тёплый душ',
    emoji: '🚿',
    price: 18,
    kind: ItemKind.hygiene,
    cleanliness: 35,
    effectText: 'Свежесть! +35 к чистоте 🚿',
  ),
  ShopItem(
    id: 'bath',
    title: 'Ванна с пеной',
    emoji: '🛁',
    price: 28,
    kind: ItemKind.hygiene,
    cleanliness: 55,
    happiness: 5,
    effectText: 'Пузырьки! +55 к чистоте 🛁',
  ),

  // ───── Здоровье ─────
  ShopItem(
    id: 'vitamins',
    title: 'Витамины',
    emoji: '💊',
    price: 20,
    kind: ItemKind.health,
    hunger: 10,
    happiness: 5,
    xp: 10,
    effectText: 'Бодрость! +10 к сытости и +10 опыта 💊',
  ),
  ShopItem(
    id: 'tea',
    title: 'Тёплый чай',
    emoji: '🍵',
    price: 14,
    kind: ItemKind.health,
    hunger: 5,
    happiness: 10,
    effectText: 'Уютно! +10 к счастью 🍵',
  ),
  ShopItem(
    id: 'vet',
    title: 'Осмотр у ветврача',
    emoji: '🏥',
    price: 45,
    kind: ItemKind.health,
    hunger: 20,
    happiness: 20,
    cleanliness: 20,
    xp: 15,
    effectText: 'Здоров! +20 ко всему и +15 опыта 🏥',
  ),

  // ───── Игры ─────
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
    id: 'balloon',
    title: 'Воздушный шарик',
    emoji: '🎈',
    price: 12,
    kind: ItemKind.fun,
    happiness: 15,
    effectText: 'Летит! +15 к счастью 🎈',
  ),
  ShopItem(
    id: 'paints',
    title: 'Краски',
    emoji: '🎨',
    price: 25,
    kind: ItemKind.fun,
    happiness: 25,
    xp: 10,
    effectText: 'Шедевр! +25 к счастью и +10 опыта 🎨',
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
  ShopItem(
    id: 'board_game',
    title: 'Настольная игра',
    emoji: '🎲',
    price: 35,
    kind: ItemKind.fun,
    happiness: 35,
    xp: 10,
    effectText: 'Твой ход! +35 к счастью 🎲',
    badge: 'Новинка',
  ),
  ShopItem(
    id: 'console',
    title: 'Игровая приставка',
    emoji: '🎮',
    price: 90,
    kind: ItemKind.fun,
    happiness: 60,
    xp: 20,
    effectText: 'Играем! +60 к счастью 🎮',
  ),

  // ───── Наряды ─────
  ShopItem(
    id: 'bow',
    title: 'Бантик',
    emoji: '🎀',
    price: 15,
    kind: ItemKind.clothes,
    happiness: 15,
    effectText: 'Красота! +15 к счастью 🎀',
  ),
  ShopItem(
    id: 'scarf',
    title: 'Шарфик',
    emoji: '🧣',
    price: 25,
    kind: ItemKind.clothes,
    happiness: 20,
    effectText: 'Тепло и модно! +20 к счастью 🧣',
  ),
  ShopItem(
    id: 'hat',
    title: 'Шляпа',
    emoji: '🎩',
    price: 30,
    kind: ItemKind.clothes,
    happiness: 25,
    effectText: 'Какой франт! +25 к счастью 🎩',
  ),
  ShopItem(
    id: 'crown',
    title: 'Корона',
    emoji: '👑',
    price: 120,
    kind: ItemKind.clothes,
    happiness: 70,
    xp: 25,
    effectText: 'Королевский питомец! +70 к счастью 👑',
    badge: 'Редкое',
  ),

  // ───── Уют ─────
  ShopItem(
    id: 'flower',
    title: 'Цветок в горшке',
    emoji: '🌷',
    price: 18,
    kind: ItemKind.home,
    happiness: 15,
    cleanliness: 5,
    effectText: 'Красиво! +15 к счастью 🌷',
  ),
  ShopItem(
    id: 'lamp',
    title: 'Ночник',
    emoji: '💡',
    price: 22,
    kind: ItemKind.home,
    happiness: 20,
    effectText: 'Не страшно ночью! +20 к счастью 💡',
  ),
  ShopItem(
    id: 'bed',
    title: 'Лежанка',
    emoji: '🛏️',
    price: 50,
    kind: ItemKind.home,
    happiness: 30,
    cleanliness: 10,
    xp: 10,
    effectText: 'Сладкий сон! +30 к счастью 🛏️',
  ),
  ShopItem(
    id: 'house',
    title: 'Домик',
    emoji: '🏠',
    price: 150,
    kind: ItemKind.home,
    happiness: 80,
    cleanliness: 20,
    xp: 30,
    effectText: 'Свой дом! +80 к счастью и +30 опыта 🏠',
    badge: 'Мечта',
  ),
];
