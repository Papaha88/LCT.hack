import 'package:flutter/material.dart';

/// Карусель «по кругу»: листается свайпом бесконечно в обе стороны,
/// после последнего снова идёт первый. Центральная карточка крупнее,
/// соседние выглядывают по бокам — видно, что можно листать.
///
/// Под каруселью — точки-индикаторы и стрелки (для тех, кому свайп
/// неудобен; тач-таргеты 48dp).
class LoopCarousel extends StatefulWidget {
  final int itemCount;
  final int initialIndex;
  final double height;
  final ValueChanged<int> onChanged;

  /// Карточка номер [index]; [selected] — она сейчас в центре.
  final Widget Function(BuildContext context, int index, bool selected)
      itemBuilder;

  const LoopCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onChanged,
    this.initialIndex = 0,
    this.height = 280,
  });

  @override
  State<LoopCarousel> createState() => _LoopCarouselState();
}

class _LoopCarouselState extends State<LoopCarousel> {
  /// Стартуем «из середины» большого диапазона — листать можно долго
  /// в обе стороны, а номер карточки — это страница по модулю.
  static const int _loops = 1000;

  late final PageController _pages = PageController(
    viewportFraction: 0.62,
    initialPage: _loops * widget.itemCount + widget.initialIndex,
  );
  late int _page = _pages.initialPage;

  int get _index => _page % widget.itemCount;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _step(int delta) {
    _pages.animateToPage(
      _page + delta,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pages,
            onPageChanged: (page) {
              setState(() => _page = page);
              widget.onChanged(page % widget.itemCount);
            },
            itemBuilder: (context, page) {
              final index = page % widget.itemCount;
              final selected = page == _page;
              return AnimatedScale(
                scale: selected ? 1 : 0.82,
                duration: const Duration(milliseconds: 220),
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0.55,
                  duration: const Duration(milliseconds: 220),
                  child: GestureDetector(
                    // Тап по соседней карточке — перелистнуть к ней.
                    onTap: selected ? null : () => _step(page - _page),
                    child: widget.itemBuilder(context, index, selected),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Назад',
              onPressed: () => _step(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            for (var i = 0; i < widget.itemCount; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _index ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _index ? scheme.primary : scheme.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            IconButton(
              tooltip: 'Дальше',
              onPressed: () => _step(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}
