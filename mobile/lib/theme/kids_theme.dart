import 'package:flutter/material.dart';

/// Тема «Финни» по макетам Figma: светлая и тёмная.
/// Фиолетовый #5552D9, мягкие карточки, круглые кнопки.
///
/// Здесь же — три цветовых helper'а для «плашек» внутри карточек
/// (пилюли на главной, облачко Финни, карточки выбора окраски).
/// Раньше они были жёстко белыми: в тёмной теме текст на белом пропадал.
class KidsTheme {
  static const Color primary = Color(0xFF5552D9);
  static const Color secondary = Color(0xFF7A76F0);
  static const Color surface = Color(0xFFF7F7FF);
  static const Color onSurface = Color(0xFF1B1D4D);
  static const Color onSurfaceVariant = Color(0xFF5B5C7B);
  static const Color success = Color(0xFF43C465);
  static const Color warning = Color(0xFFFFB547);
  static const Color outline = Color(0xFFE3E4F2);

  // Тёмная палитра (глубокий фиолетово-синий).
  static const Color darkPrimary = Color(0xFF8B88FF);
  static const Color darkSurface = Color(0xFF151735);
  static const Color darkCard = Color(0xFF23264F);
  static const Color darkOnSurface = Color(0xFFF2F3FF);
  static const Color darkOutline = Color(0xFF3A3D6B);

  /// Минимальный размер текста по ТЗ. Меньше — нельзя.
  static const double minFontSize = 16;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Цвет «плашки» поверх карточки: белый в светлой теме, карточный в тёмной.
  static Color pill(BuildContext context) =>
      isDark(context) ? darkCard : Colors.white;

  /// Мягкий фон второстепенных элементов: дорожки прогресса, бейджи.
  static Color soft(BuildContext context) =>
      isDark(context) ? const Color(0xFF2E3160) : const Color(0xFFEDE7F6);

  /// Приглушённый текст подписей («78/100 • отлично!»).
  static Color muted(BuildContext context) =>
      isDark(context) ? const Color(0xFFB9BBE0) : const Color(0xFF5A5470);

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      tertiary: success,
    );
    return _build(scheme, cardColor: Colors.white);
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: darkPrimary,
      secondary: secondary,
      surface: darkSurface,
      onSurface: darkOnSurface,
      onSurfaceVariant: Color(0xFFB9BBE0),
      outline: darkOutline,
      tertiary: success,
    );
    return _build(scheme, cardColor: darkCard);
  }

  /// ТЗ требует текст не меньше 16sp. Ступени, которые Material даёт
  /// мельче (12–14sp), поднимаем до 16 — крупные не трогаем.
  static TextTheme _textTheme(Color color) {
    final base = Typography.material2021()
        .black
        .apply(bodyColor: color, displayColor: color);
    return base.copyWith(
      bodyLarge: base.bodyLarge?.copyWith(fontSize: minFontSize),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: minFontSize),
      bodySmall: base.bodySmall?.copyWith(fontSize: minFontSize),
      titleSmall: base.titleSmall?.copyWith(fontSize: minFontSize),
      labelLarge: base.labelLarge?.copyWith(fontSize: minFontSize),
      labelMedium: base.labelMedium?.copyWith(fontSize: minFontSize),
      labelSmall: base.labelSmall?.copyWith(fontSize: minFontSize),
    );
  }

  static ThemeData _build(ColorScheme scheme, {required Color cardColor}) {
    final isDark = scheme.brightness == Brightness.dark;
    final fill = isDark ? darkCard : Colors.white;
    final appBarBg = isDark ? darkCard : primary;

    return ThemeData.from(colorScheme: scheme)
        .copyWith(
          textTheme: _textTheme(scheme.onSurface),
          primaryTextTheme: _textTheme(Colors.white),
        )
        .copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outline, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? darkPrimary : primary,
          foregroundColor: Colors.white,
          elevation: 0,
          // ТЗ: тач-таргет не меньше 48x48dp — держим высоту 54.
          minimumSize: const Size(48, 54),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: minFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? darkPrimary : primary,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontSize: minFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: warning,
        linearTrackColor: scheme.outline,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkPrimary : onSurface,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: minFontSize,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: minFontSize,
          height: 1.35,
          color: scheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: TextStyle(
          fontSize: minFontSize,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: minFontSize,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
