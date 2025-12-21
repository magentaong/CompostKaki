import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette - matching web app
  static const Color primaryGreen = Color(0xFF00796B);
  static const Color primaryGreenDark = Color(0xFF005A4B);
  static const Color primaryGreenLight = Color(0xFFE6FFF3);
  static const Color backgroundGray = Color(0xFFF3F3F3);
  static const Color textGray = Color(0xFF5A5A5A);
  static const Color borderGray = Color(0xFFE0E0E0);

  // Health Status Colors
  static const Color healthCritical = Color(0xFFE8B5B5);
  static const Color healthCriticalText = Color(0xFF6D2222);
  static const Color healthHealthy = Color(0xFFCBE7B5);
  static const Color healthNeedsAttention = Color(0xFFF0E1A6);
  static const Color healthNeedsAttentionText = Color(0xFF694F00);

  // Urgency Colors
  static const Color urgencyHigh = Color(0xFFE8B5B5);
  static const Color urgencyHighText = Color(0xFF6D2222);
  static const Color urgencyNormal = Color(0xFFF0E1A6);
  static const Color urgencyNormalText = Color(0xFF694F00);
  static const Color urgencyLow = Color(0xFFDCE8E1);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: primaryGreenLight,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        titleTextStyle: TextStyle(
          color: primaryGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
      ),
    );
  }
}
