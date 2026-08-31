import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider exposing the active ThemeMode state.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// State notifier allowing users to toggle between light (default), dark, and
/// system modes.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  /// Default constructor starting in light mode.
  ThemeModeNotifier() : super(ThemeMode.light);

  /// Switch to light mode.
  void setLight() => state = ThemeMode.light;

  /// Switch to dark mode.
  void setDark() => state = ThemeMode.dark;

  /// Switch to system following mode.
  void setSystem() => state = ThemeMode.system;

  /// Toggle between light and dark modes.
  void toggleTheme() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }
}
