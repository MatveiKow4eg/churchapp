import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options for the app.
enum AppThemeMode {
  system,
  light,
  dark,
}

@immutable
class ThemeState {
  const ThemeState({
    required this.mode,
    required this.accentColor,
  });

  final AppThemeMode mode;
  final Color accentColor;

  ThemeState copyWith({
    AppThemeMode? mode,
    Color? accentColor,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeState>((ref) {
  return ThemeController();
});

class ThemeController extends StateNotifier<ThemeState> {
  ThemeController()
      : super(
          const ThemeState(
            mode: AppThemeMode.dark,
            accentColor: Colors.yellow,
          ),
        ) {
    _load();
  }

  static const _modeKey = 'theme_mode';
  static const _accentKey = 'accent_color';

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(mode: mode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentKey, color.value);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final storedMode = prefs.getString(_modeKey);
    final storedAccent = prefs.getInt(_accentKey);

    AppThemeMode mode = state.mode;
    if (storedMode != null) {
      mode = AppThemeMode.values.firstWhere(
        (m) => m.name == storedMode,
        orElse: () => AppThemeMode.system,
      );
    }

    Color accent = state.accentColor;
    if (storedAccent != null) {
      accent = Color(storedAccent);
    }

    state = state.copyWith(mode: mode, accentColor: accent);
  }
}
