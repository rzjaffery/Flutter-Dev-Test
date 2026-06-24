// lib/utils/app_theme.dart
// Centralised design tokens — colors, text styles, input decorations.

import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Palette ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF5C6BC0);       // Indigo 400
  static const Color primaryDark = Color(0xFF3949AB);   // Indigo 600
  static const Color accent = Color(0xFFFF7043);        // Deep Orange 400
  static const Color background = Color(0xFFF5F5F5);    // Grey 100
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE53935);

  // ── MaterialApp ThemeData ─────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
    ),
    cardTheme: CardTheme(
      color: surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

// ── Reusable validators ───────────────────────────────────────────────────────
class Validators {
  static String? email(String? val) {
    if (val == null || val.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(val.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? val) {
    if (val == null || val.isEmpty) return 'Password is required';
    if (val.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? required(String? val, [String label = 'This field']) {
    if (val == null || val.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? price(String? val) {
    if (val == null || val.trim().isEmpty) return 'Price is required';
    final parsed = double.tryParse(val.trim());
    if (parsed == null || parsed < 0) return 'Enter a valid price';
    return null;
  }
}