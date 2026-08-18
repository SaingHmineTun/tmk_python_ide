import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF55C2A3);

  static ThemeData light() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F7F8),
    appBarTheme: const AppBarTheme(centerTitle: false),
  );

  static ThemeData dark() => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF101418),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF171C21)),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF171C21),
    ),
  );
}
