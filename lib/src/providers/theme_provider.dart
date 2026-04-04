import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elara_player/src/theme/app_theme.dart';

class ThemeSettings {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final ThemeMode themeMode;

  const ThemeSettings({
    this.primaryColor = AppTheme.defaultPrimaryColor,
    this.secondaryColor = AppTheme.defaultSecondaryColor,
    this.accentColor = AppTheme.defaultAccentColor,
    this.themeMode = ThemeMode.system,
  });

  ThemeSettings copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    ThemeMode? themeMode,
  }) {
    return ThemeSettings(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeSettings> {
  ThemeNotifier() : super(const ThemeSettings());

  void updatePrimaryColor(Color color) {
    state = state.copyWith(primaryColor: color);
  }

  void updateSecondaryColor(Color color) {
    state = state.copyWith(secondaryColor: color);
  }

  void updateAccentColor(Color color) {
    state = state.copyWith(accentColor: color);
  }

  void updateThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeSettings>((ref) {
  return ThemeNotifier();
});
