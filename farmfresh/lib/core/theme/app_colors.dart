import 'package:flutter/material.dart';

/// Brand design tokens, carried through the [ThemeData] via a [ThemeExtension]
/// so every widget can read them with `Theme.of(context).extension<AppColors>()`
/// (see the `context.colors` helper in `theme_ext.dart`).
///
/// Values are lifted verbatim from the wireframe's CSS `:root` tokens so the
/// Flutter app matches the approved design 1:1, including dark mode.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.green,
    required this.greenDark,
    required this.greenSoft,
    required this.beige,
    required this.beigeDeep,
    required this.gold,
    required this.goldSoft,
    required this.ink,
    required this.muted,
    required this.line,
    required this.surface,
    required this.canvas,
    required this.tagSaveBg,
    required this.tagSaveFg,
  });

  final Color green;
  final Color greenDark;
  final Color greenSoft;
  final Color beige;
  final Color beigeDeep;
  final Color gold;
  final Color goldSoft;
  final Color ink;
  final Color muted;
  final Color line;
  final Color surface;
  final Color canvas;
  final Color tagSaveBg;
  final Color tagSaveFg;

  /// Light theme tokens — from the wireframe `:root`.
  static const light = AppColors(
    green: Color(0xFF2F6B46),
    greenDark: Color(0xFF1F4A30),
    greenSoft: Color(0xFFEAF2EC),
    beige: Color(0xFFF5EFE3),
    beigeDeep: Color(0xFFE9DFCA),
    gold: Color(0xFFC9A24B),
    goldSoft: Color(0xFFF4ECD8),
    ink: Color(0xFF26312B),
    muted: Color(0xFF7B857F),
    line: Color(0xFFE7E3D8),
    surface: Color(0xFFFFFFFF),
    canvas: Color(0xFFFFFFFF),
    tagSaveBg: Color(0xFFFBE9D2),
    tagSaveFg: Color(0xFFA25E12),
  );

  /// Dark theme tokens — from the wireframe `.phone.dark` re-map.
  static const dark = AppColors(
    green: Color(0xFF4FA674),
    greenDark: Color(0xFF2F6B46),
    greenSoft: Color(0xFF1D2A21),
    beige: Color(0xFF222A22),
    beigeDeep: Color(0xFF2C352C),
    gold: Color(0xFFD8B15C),
    goldSoft: Color(0xFF2C2614),
    ink: Color(0xFFEAF0EA),
    muted: Color(0xFF9AA49C),
    line: Color(0xFF2C352D),
    surface: Color(0xFF1E251F),
    canvas: Color(0xFF161B17),
    tagSaveBg: Color(0xFF3A2E1C),
    tagSaveFg: Color(0xFFE8C779),
  );

  @override
  AppColors copyWith({
    Color? green,
    Color? greenDark,
    Color? greenSoft,
    Color? beige,
    Color? beigeDeep,
    Color? gold,
    Color? goldSoft,
    Color? ink,
    Color? muted,
    Color? line,
    Color? surface,
    Color? canvas,
    Color? tagSaveBg,
    Color? tagSaveFg,
  }) {
    return AppColors(
      green: green ?? this.green,
      greenDark: greenDark ?? this.greenDark,
      greenSoft: greenSoft ?? this.greenSoft,
      beige: beige ?? this.beige,
      beigeDeep: beigeDeep ?? this.beigeDeep,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      surface: surface ?? this.surface,
      canvas: canvas ?? this.canvas,
      tagSaveBg: tagSaveBg ?? this.tagSaveBg,
      tagSaveFg: tagSaveFg ?? this.tagSaveFg,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      green: Color.lerp(green, other.green, t)!,
      greenDark: Color.lerp(greenDark, other.greenDark, t)!,
      greenSoft: Color.lerp(greenSoft, other.greenSoft, t)!,
      beige: Color.lerp(beige, other.beige, t)!,
      beigeDeep: Color.lerp(beigeDeep, other.beigeDeep, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      tagSaveBg: Color.lerp(tagSaveBg, other.tagSaveBg, t)!,
      tagSaveFg: Color.lerp(tagSaveFg, other.tagSaveFg, t)!,
    );
  }
}
