import 'package:flutter/material.dart';

/// Rider identity: a delivery blue with amber/green accents.
const riderBlue = Color(0xFF2B5A8A);
const riderGold = Color(0xFFB4791B);
const riderGreen = Color(0xFF2F6B46);
const riderRed = Color(0xFFC0392B);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: riderBlue, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF10161C) : const Color(0xFFF3F5F8),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: dark ? const Color(0xFF16202B) : Colors.white,
      foregroundColor: dark ? Colors.white : const Color(0xFF1B2733),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? const Color(0xFF18232F) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dark ? const Color(0xFF26333F) : const Color(0xFFE3E7ED)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF18232F) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
