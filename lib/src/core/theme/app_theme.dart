import 'package:flutter/material.dart';

class AppColors {
  // Primary shades (from your Tailwind-like palette)
  static const primary50 = Color(0xFFF0F9FF);
  static const primary100 = Color(0xFFE0F2FE);
  static const primary200 = Color(0xFFBAE6FD);
  static const primary300 = Color(0xFF7DD3FC);
  static const primary400 = Color(0xFF38BDF8);
  static const primary500 = Color(0xFF0EA5E9);
  static const primary600 = Color(0xFF0284C7);
  static const primary700 = Color(0xFF0369A1);
  static const primary800 = Color(0xFF075985);
  static const primary900 = Color(0xFF0C4A6E);

  // Secondary shades
  static const secondary50 = Color(0xFFFAF5FF);
  static const secondary100 = Color(0xFFF3E8FF);
  static const secondary200 = Color(0xFFE9D5FF);
  static const secondary300 = Color(0xFFD8B4FE);
  static const secondary400 = Color(0xFFC084FC);
  static const secondary500 = Color(0xFFA855F7);
  static const secondary600 = Color(0xFF9333EA);
  static const secondary700 = Color(0xFF7C3AED);
  static const secondary800 = Color(0xFF6B21A8);
  static const secondary900 = Color(0xFF581C87);

  // Neutral (gray) palette
  static const neutral50 = Color(0xFFF8FAFC);
  static const neutral100 = Color(0xFFF1F5F9);
  static const neutral200 = Color(0xFFE2E8F0);
  static const neutral300 = Color(0xFFCBD5E1);
  static const neutral400 = Color(0xFF94A3B8);
  static const neutral500 = Color(0xFF64748B);
  static const neutral600 = Color(0xFF475569);
  static const neutral700 = Color(0xFF334155);
  static const neutral800 = Color(0xFF1E293B);
  static const neutral900 = Color(0xFF0F172A);

  // Convenience
  static const background = neutral50;
  static const surface = Colors.white;
}

class AppTheme {
  // Primary swatch to allow uses that expect MaterialColor (if needed)
  static final MaterialColor primarySwatch =
      MaterialColor(AppColors.primary500.toARGB32(), const <int, Color>{
        50: AppColors.primary50,
        100: AppColors.primary100,
        200: AppColors.primary200,
        300: AppColors.primary300,
        400: AppColors.primary400,
        500: AppColors.primary500,
        600: AppColors.primary600,
        700: AppColors.primary700,
        800: AppColors.primary800,
        900: AppColors.primary900,
      });

  // Font family stack (uses Plus Jakarta Sans first; fallback to system fonts)
  static const String primaryFont = 'Plus Jakarta Sans';

  static final TextTheme _textTheme = Typography.material2021().black
      .apply(fontFamily: primaryFont)
      .copyWith(
        headlineSmall: const TextStyle(fontWeight: FontWeight.w700),
        titleLarge: const TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: const TextStyle(fontWeight: FontWeight.w400),
      );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary500,
      onPrimary: Colors.white,
      secondary: AppColors.secondary500,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.neutral900,
      error: Colors.red.shade700,
      onError: Colors.white,
      tertiary: AppColors.secondary300,
      onTertiary: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary500,
    primarySwatch: primarySwatch,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.neutral900,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary600),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary600,
        side: BorderSide(color: AppColors.primary200),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.neutral100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: _textTheme,
    iconTheme: const IconThemeData(color: AppColors.neutral700),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.neutral800,
      contentTextStyle: _textTheme.bodyMedium?.copyWith(color: Colors.white),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary300,
      onPrimary: AppColors.neutral900,
      secondary: AppColors.secondary300,
      onSecondary: Colors.white,
      surface: AppColors.neutral800,
      onSurface: AppColors.neutral50,
      error: Colors.red.shade400,
      onError: Colors.white,
      tertiary: AppColors.secondary400,
      onTertiary: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.neutral900,
    primaryColor: AppColors.primary300,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.neutral900,
      foregroundColor: AppColors.neutral50,
    ),
    cardTheme: CardThemeData(
      color: AppColors.neutral800,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary300,
        foregroundColor: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.neutral800,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: Typography.material2021().white.apply(fontFamily: primaryFont),
    iconTheme: const IconThemeData(color: AppColors.neutral50),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.neutral700,
      contentTextStyle: Typography.material2021().white.bodyMedium?.copyWith(
        color: Colors.white,
      ),
    ),
  );
}
