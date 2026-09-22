import 'package:flutter/material.dart';

/// Тема «Финни» по макетам Figma: светлая и тёмная.
/// Фиолетовый #5552D9, мягкие карточки, круглые кнопки.
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

  static ThemeData light() {
    final scheme = ColorScheme.light(
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
    final scheme = ColorScheme.dark(
      primary: darkPrimary,
      secondary: secondary,
      surface: darkSurface,
      onSurface: darkOnSurface,
      onSurfaceVariant: const Color(0xFFB9BBE0),
      outline: darkOutline,
      tertiary: success,
    );
    return _build(scheme, cardColor: darkCard);
  }

  static ThemeData _build(ColorScheme scheme, {required Color cardColor}) {
    final isDark = scheme.brightness == Brightness.dark;
    final fill = isDark ? darkCard : Colors.white;
    final appBarBg = isDark ? darkCard : primary;

    return ThemeData.from(colorScheme: scheme).copyWith(
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
          minimumSize: const Size.fromHeight(54),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? darkPrimary : primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: warning,
        linearTrackColor: scheme.outline,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkPrimary : onSurface,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
