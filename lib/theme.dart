import 'package:flutter/material.dart';

class AppTheme {
  // Colors extracted from globals.css
  static const Color primary = Color(0xFF21C45D); // hsl(142, 71%, 45%)
  static const Color background = Color(0xFFF8F9FA); // hsl(210, 17%, 98%)
  static const Color foreground = Color(0xFF020617); // hsl(222.2, 84%, 4.9%)
  static const Color card = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFF1F5F9);
  static const Color mutedForeground = Color(0xFF64748B);
  static const Color destructive = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        background: background,
        surface: card,
        onPrimary: Colors.white,
        onBackground: foreground,
        onSurface: foreground,
        error: destructive,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter', // Assuming we will add Inter font later
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: foreground,
        elevation: 0,
      ),
    );
  }
}
