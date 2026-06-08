import 'package:flutter/material.dart';

class AdminTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final cs = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E3A8A), // Navy blue
      brightness: Brightness.light,
      primary: const Color(0xFF1E3A8A),
      secondary: const Color(0xFF0D9488), // Teal
      background: const Color(0xFFF1F5F9), // Light grey background
      surface: Colors.white,
    );

    return base.copyWith(
      colorScheme: cs,
      scaffoldBackgroundColor: cs.background,
      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final cs = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6), // Blue
      brightness: Brightness.dark,
      primary: const Color(0xFF3B82F6),
      secondary: const Color(0xFF14B8A6),
      background: const Color(0xFF0F172A), // Deep navy dark
      surface: const Color(0xFF1E293B), // Slate card dark
    );

    return base.copyWith(
      colorScheme: cs,
      scaffoldBackgroundColor: cs.background,
      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
