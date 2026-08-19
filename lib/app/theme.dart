import 'package:flutter/material.dart';

class AppTheme {
  static const brandBlue = Color(0xFF1557C0);
  static const brandGold = Color(0xFFF2B705);
  static const _lightGold = Color(0xFFFFE9A6);
  static const _deepNavy = Color(0xFF071A3A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: brandBlue).copyWith(
      primary: brandBlue,
      onPrimary: Colors.white,
      secondary: brandGold,
      onSecondary: _deepNavy,
      secondaryContainer: _lightGold,
      onSecondaryContainer: _deepNavy,
      tertiary: const Color(0xFFB27A00),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F9FD),
      appBarTheme: const AppBarTheme(centerTitle: false),
      navigationBarTheme: const NavigationBarThemeData(
        indicatorColor: _lightGold,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        indicatorColor: _lightGold,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: brandBlue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF8DB7FF),
          onPrimary: _deepNavy,
          secondary: const Color(0xFFFFD65A),
          onSecondary: _deepNavy,
          secondaryContainer: const Color(0xFF594500),
          onSecondaryContainer: const Color(0xFFFFE9A6),
          tertiary: const Color(0xFFFFC934),
        );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF091321),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF101E33)),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF101E33),
        indicatorColor: Color(0xFF594500),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xFF101E33),
        indicatorColor: Color(0xFF594500),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFFD65A),
        foregroundColor: _deepNavy,
      ),
    );
  }
}
