import 'package:flutter/material.dart';

class AppTheme {
  // GLOBAL STATE FOR SETTINGS
  static final ValueNotifier<bool> isDarkNotifier = ValueNotifier(true);
  static final ValueNotifier<String> fontFamilyNotifier =
      ValueNotifier('Verdana');
  static final ValueNotifier<double> fontScaleNotifier = ValueNotifier(1.0);

  // NEW: Dynamic Primary Color
  static final ValueNotifier<Color> primaryColorNotifier =
      ValueNotifier(const Color(0xFF38BDF8));

  // STATIC COLORS
  static const Color bgDark = Color(0xFF0F172A);
  static const Color cardBgDark = Color(0xFF1E293B);
  static const Color cardBgLight = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textLight = Color(0xFFF1F5F9);
  static const Color textGrey = Color(0xFF888888);
  static const Color neonGold = Color(0xFFFFD700);
  static const Color cardBg = Color(0xFF1E293B);

  // GETTER FOR DYNAMIC COLOR
  static Color get neonBlue => primaryColorNotifier.value;

  static const List<Color> colorOptions = [
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFF818CF8), // Indigo
    Color(0xFF34D399), // Emerald
    Color(0xFFF472B6), // Pink
    Color(0xFFFB923C), // Orange
  ];

  // 6 FONT OPTIONS
  static const Map<String, String> fontOptions = {
    "Modern": "Verdana",
    "Classic": "Times New Roman",
    "Code": "Courier",
    "Elegant": "Georgia",
    "Clean": "Arial",
    "System": "Roboto",
  };

  // DYNAMIC TEXT STYLES
  static TextStyle get headerStyle => TextStyle(
        fontFamily: fontFamilyNotifier.value,
        fontWeight: FontWeight.bold,
        fontSize: 24 * fontScaleNotifier.value,
        letterSpacing: 0.5,
      );

  static TextStyle get bodyStyle => TextStyle(
        fontFamily: fontFamilyNotifier.value,
        fontSize: 14 * fontScaleNotifier.value,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get codeStyle => TextStyle(
        fontFamily: 'Courier',
        fontSize: 12 * fontScaleNotifier.value,
        fontWeight: FontWeight.w600,
      );

  // ALIASES
  static TextStyle get fontTech => headerStyle;
  static TextStyle get fontCode => codeStyle;

  // DARK THEME
  static ThemeData get darkTheme => ThemeData(
        scaffoldBackgroundColor: bgDark,
        brightness: Brightness.dark,
        primaryColor: neonBlue,
        cardColor: cardBgDark,
        iconTheme: const IconThemeData(color: textLight),
        textTheme: TextTheme(
          displayLarge: headerStyle.copyWith(color: textLight),
          titleLarge: headerStyle.copyWith(
              fontSize: 20 * fontScaleNotifier.value, color: textLight),
          bodyLarge: bodyStyle.copyWith(color: textLight),
          bodyMedium: bodyStyle.copyWith(color: Colors.grey.shade400),
        ),
      );

  // LIGHT THEME
  static ThemeData get lightTheme => ThemeData(
        scaffoldBackgroundColor: bgLight,
        brightness: Brightness.light,
        primaryColor: neonBlue,
        cardColor: cardBgLight,
        iconTheme: const IconThemeData(color: textDark),
        textTheme: TextTheme(
          displayLarge: headerStyle.copyWith(color: textDark),
          titleLarge: headerStyle.copyWith(
              fontSize: 20 * fontScaleNotifier.value, color: textDark),
          bodyLarge: bodyStyle.copyWith(color: textDark),
          bodyMedium: bodyStyle.copyWith(color: Colors.grey.shade600),
        ),
      );
}
