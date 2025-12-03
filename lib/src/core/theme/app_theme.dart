import 'package:flutter/material.dart';

class AppColors {
  // Primary shades (from your Tailwind-like palette)
  static const primary50 = Color(0xFFF0F9FF);
  static const primary100 = Color(0xFFE0F2FE);
  static const primary200 = Color(0xFFBAE6FD);
  static const primary300 = Color(0xFF7DD3FC);
  static const primary400 = Color(0xFF38BDF8);
  // From interfaz_qr: --primary: #60A5FA (light), dark primary #3B82F6
  static const primary500 = Color(0xFF60A5FA);
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
  static const neutral50 = Color(0xFFF9FAFB); // interfaz_qr foreground base
  static const neutral100 = Color(0xFFF1F5F9);
  static const neutral200 = Color(0xFFE2E8F0);
  static const neutral300 = Color(0xFFCBD5E1);
  static const neutral400 = Color(0xFF94A3B8);
  static const neutral500 = Color(0xFF64748B);
  static const neutral600 = Color(0xFF4B5563); // switch bg in css
  static const neutral700 = Color(0xFF374151); // border/accent in css
  static const neutral800 = Color(0xFF1F2937); // card/popover in css
  static const neutral900 = Color(0xFF0F1419); // css background

  // Convenience
  static const background = neutral900; // default dark background per interfaz_qr
  static const surface = neutral800; // card

  // Additional tokens mirrored from interfaz_qr CSS variables
  static const foreground = neutral50; // text color
  static const card = neutral800; // --card
  static const cardForeground = neutral50; // --card-foreground
  static const popover = neutral800; // --popover
  static const popoverForeground = neutral50; // --popover-foreground
  static const primaryForeground = neutral900; // --primary-foreground
  static const secondary = Color(0xFF34D399); // --secondary
  static const secondaryForeground = Colors.white; // --secondary-foreground
  static const muted = neutral700; // --muted
  static const mutedForeground = Color(0xFF9CA3AF); // --muted-foreground
  static const accent = neutral700; // --accent
  static const accentForeground = neutral50; // --accent-foreground
  static const destructive = Color(0xFFF87171); // --destructive
  static const destructiveForeground = Colors.white; // --destructive-foreground
  static const border = neutral700; // --border
  static const input = Colors.transparent; // --input
  static const inputBackground = neutral800; // --input-background
  static const ring = primary500; // --ring
  static const success = Color(0xFF34D399);
  static const successForeground = Colors.white;
  static const warning = Color(0xFFFBBF24);
  static const warningForeground = neutral900;
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
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      surface: AppColors.surface,
      onSurface: AppColors.foreground,
      error: Colors.red.shade700,
      onError: Colors.white,
      tertiary: AppColors.secondary,
      onTertiary: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary500,
    primarySwatch: primarySwatch,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.foreground,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.primaryForeground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary600),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary600,
        side: BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: _textTheme,
    iconTheme: const IconThemeData(color: AppColors.foreground),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.neutral800,
      contentTextStyle: _textTheme.bodyMedium?.copyWith(color: AppColors.foreground),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF3B82F6), // dark primary
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      surface: AppColors.card,
      onSurface: AppColors.foreground,
      error: Colors.red.shade400,
      onError: Colors.white,
      tertiary: AppColors.secondary,
      onTertiary: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: Color(0xFF3B82F6),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.foreground,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF3B82F6),
        foregroundColor: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: Typography.material2021().white.apply(fontFamily: primaryFont),
    iconTheme: const IconThemeData(color: AppColors.foreground),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.neutral700,
      contentTextStyle: Typography.material2021().white.bodyMedium?.copyWith(
        color: AppColors.foreground,
      ),
    ),
  );
}
