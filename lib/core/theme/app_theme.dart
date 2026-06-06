import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final cs = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return ThemeData.from(colorScheme: cs).copyWith(
      textTheme: ThemeData.light().textTheme.apply(bodyColor: Colors.black87),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        iconTheme: IconThemeData(color: cs.onPrimary),
        elevation: 2,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cs.surface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withAlpha((0.6 * 255).round()),
        showUnselectedLabels: true,
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark);
    return ThemeData.from(colorScheme: cs, textTheme: ThemeData.dark().textTheme).copyWith(
      textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        iconTheme: IconThemeData(color: cs.onSurface),
        elevation: 2,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cs.surface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withAlpha((0.6 * 255).round()),
        showUnselectedLabels: true,
      ),
    );
  }
}
