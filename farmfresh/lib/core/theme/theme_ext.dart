import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Ergonomic access to brand tokens: `context.colors.green`, `context.text`.
extension ThemeContextX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
