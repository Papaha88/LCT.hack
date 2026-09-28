/// Цензура имён: игровое имя ребёнка и кличка питомца не должны содержать
/// русский мат и слова 18+.
///
/// Как работает:
/// 1. Строку приводим к «скелету»: нижний регистр, ё → е, транслит и
///    латинские/цифровые двойники букв → кириллица («blyat» → «блят»,
///    «xyй» → «хуй», «п1зда» → «пизда»), всё, кроме букв, выкидываем
///    («х.у.й»), повторы схлопываем («сууука» → «сука»).
/// 2. Вырезаем безобидные слова, внутри которых случайно сидит корень
///    («Глеб», «Аманда», «страх», «ребёнок»…), — чтобы не обидеть ребёнка
///    с обычным именем.
/// 3. Ищем запрещённые корни. Отдельно проверяем английские слова 18+.
///
/// Списки — константы ниже: их можно пополнять, не трогая логику.
class NameFilter {
  const NameFilter._();

  /// Можно ли использовать имя.
  static bool isAllowed(String name) => !containsBadWords(name);

  static bool containsBadWords(String text) {
    var skeleton = normalize(text);
    for (final safe in _safeWords) {
      skeleton = skeleton.replaceAll(safe, '-');
    }
    for (final root in _badRoots) {
      if (skeleton.contains(root)) return true;
    }

    var latin = _latinSkeleton(text);
    for (final safe in _latinSafe) {
      latin = latin.replaceAll(safe, '-');
    }
    for (final root in _latinBad) {
      if (latin.contains(root)) return true;
    }
    return false;
  }

  /// Кириллический «скелет» строки. Публичный — для тестов.
  static String normalize(String text) {
    var s = text.toLowerCase().replaceAll('ё', 'е');
    _digraphs.forEach((from, to) => s = s.replaceAll(from, to));

    final buffer = StringBuffer();
    String? last;
    String? lastRaw;
    for (final rune in s.runes) {
      var ch = String.fromCharCode(rune);
      // Повторы схлопываем ещё до замены: «cyyyka» — это одна «y».
      if (ch == lastRaw) continue;
      lastRaw = ch;
      if (ch == 'y') {
        // «huy» → «хуй», «xyi» → «хуи»: после гласной y — это «й».
        ch = last != null && _vowels.contains(last) ? 'й' : 'у';
      } else {
        ch = _lookalikes[ch] ?? ch;
      }
      if (!_isCyrillicLetter(ch)) continue;
      if (ch == last) continue;
      buffer.write(ch);
      last = ch;
    }
    return buffer.toString();
  }

  static String _latinSkeleton(String text) {
    final buffer = StringBuffer();
    String? last;
    for (final rune in text.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      final code = ch.codeUnitAt(0);
      if (code < 0x61 || code > 0x7A) continue; // только a..z
      if (ch == last) continue;
      buffer.write(ch);
      last = ch;
    }
    return buffer.toString();
  }

  static bool _isCyrillicLetter(String ch) {
    final code = ch.codeUnitAt(0);
    return code >= 0x0430 && code <= 0x044F; // а..я (ё уже заменена)
  }

  static const Set<String> _vowels = {'а', 'е', 'и', 'о', 'у', 'ы', 'э', 'ю', 'я'};

  /// Транслит из нескольких букв — заменяем до побуквенной замены.
  static const Map<String, String> _digraphs = {
    'sch': 'щ', 'shh': 'щ', 'sh': 'ш', 'ch': 'ч', 'zh': 'ж', 'kh': 'х',
    'ts': 'ц', 'ya': 'я', 'ja': 'я', 'yu': 'ю', 'ju': 'ю', 'yo': 'е',
    'ye': 'е',
  };

  /// Латиница, цифры и символы, которыми подменяют русские буквы.
  static const Map<String, String> _lookalikes = {
    'a': 'а', 'b': 'б', 'c': 'с', 'd': 'д', 'e': 'е', 'f': 'ф',
    'g': 'г', 'h': 'х', 'i': 'и', 'j': 'й', 'k': 'к', 'l': 'л',
    'm': 'м', 'n': 'н', 'o': 'о', 'p': 'п', 'q': 'к', 'r': 'р',
    's': 'с', 't': 'т', 'u': 'у', 'v': 'в', 'w': 'ш', 'x': 'х',
    'z': 'з',
    '0': 'о', '1': 'и', '3': 'з', '4': 'ч', '6': 'б', '8': 'в',
    '@': 'а', r'$': 'с', '€': 'е', '|': 'и',
  };

  /// Безобидные слова и имена, внутри которых есть «плохие» сочетания.
  /// В нормализованном виде (без повторов букв).
  static const List<String> _safeWords = [
    'глеб', 'хлеб', 'аманд', 'команд', 'мандарин', 'мандол', 'мандат',
    'оскорбл', 'себаст', 'гребл', 'гребн', 'гребен', 'ребен', 'колеба',
    'колебл', 'потребл', 'истреб', 'дебат', 'ребус', 'сабл', 'рубл',
    'корабл', 'оглобл', 'ансамбл', 'грабл', 'дирижабл', 'бляшк',
    'барсук', 'психуй', 'страхуй', 'страх', 'трахе', 'канал', 'банал',
    'педикюр', 'херувим', 'гандбол',
  ];

  /// Корни мата и 18+ (в нормализованном виде: без повторов букв).
  static const List<String> _badRoots = [
    // мат
    'хуй', 'хуе', 'хуя', 'хуи', 'хую', 'хйн', 'херн', 'нахер', 'похер',
    'пизд', 'пезд', 'пзд', 'ебан', 'ебал', 'ебат', 'ебен', 'ебет', 'ебис',
    'ебл', 'ебн', 'ебуч', 'ебун', 'заеб', 'уеб', 'выеб', 'въеб', 'поеб',
    'наеб', 'отеб', 'доеб', 'проеб', 'разеб', 'съеб', 'бля', 'блть',
    'сука', 'суки', 'сучк', 'сучар', 'мудак', 'мудил', 'мудозв', 'пидор',
    'пидар', 'пидр', 'педик', 'гандон', 'гондон', 'залуп', 'шлюх',
    'шалав', 'дроч', 'манда', 'курв',
    // грубое
    'говн', 'гавн', 'дерьм', 'срак', 'сран', 'жоп',
    // 18+
    'секс', 'порн', 'минет', 'трах', 'сиськ', 'член', 'пенис', 'вагин',
    'анальн', 'оргазм', 'эрот', 'проститут', 'голая', 'голый', 'нарко',
    'героин', 'кокаин', 'водка', 'пиво',
  ];

  static const List<String> _latinSafe = ['peacock', 'hancock', 'susex', 'esex'];

  static const List<String> _latinBad = [
    'fuck', 'fuk', 'shit', 'sex', 'porn', 'dick', 'bitch', 'pusy', 'cock',
    'whore', 'slut', 'penis', 'boob', 'nude', 'nsfw',
  ];
}
