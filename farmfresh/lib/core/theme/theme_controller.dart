import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the active [ThemeMode] and toggles light/dark.
///
/// Mirrors the wireframe's `toggleTheme()` (🌙 / ☀️). Persistence can be added
/// later by writing to `shared_preferences` inside [toggle].
class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void set(ThemeMode mode) => state = mode;
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
