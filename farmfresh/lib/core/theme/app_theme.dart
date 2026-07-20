import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'dimens.dart';

/// Builds the light and dark [ThemeData] for FarmFresh.
///
/// The brand tokens live in [AppColors] (a [ThemeExtension]); this file wires
/// them into Material's [ColorScheme], text theme, and component themes so
/// stock widgets (buttons, inputs, cards) inherit the brand automatically.
abstract class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.green,
      onPrimary: Colors.white,
      secondary: c.gold,
      onSecondary: const Color(0xFF231D0C),
      surface: c.surface,
      onSurface: c.ink,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
    );

    final textTheme = _textTheme(base.textTheme, c.ink, c.muted);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: c.line),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: c.beige,
        side: BorderSide(color: c.line),
        labelStyle: textTheme.labelLarge,
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: c.muted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: c.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: c.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: c.green, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.green,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.green,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: c.green, width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.green,
        unselectedItemColor: c.muted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color ink, Color muted) {
    TextStyle s(double size, FontWeight w, {Color? color, double? height}) =>
        TextStyle(
          fontSize: size,
          fontWeight: w,
          color: color ?? ink,
          height: height,
        );
    return base.copyWith(
      displaySmall: s(26, FontWeight.w800),
      headlineSmall: s(20, FontWeight.w800),
      titleLarge: s(16, FontWeight.w700),
      titleMedium: s(15, FontWeight.w700),
      titleSmall: s(13, FontWeight.w700),
      bodyLarge: s(14, FontWeight.w400, height: 1.4),
      bodyMedium: s(13, FontWeight.w400, height: 1.4),
      bodySmall: s(11.5, FontWeight.w400, color: muted),
      labelLarge: s(12.5, FontWeight.w600),
      labelSmall: s(10.5, FontWeight.w700),
    );
  }
}
