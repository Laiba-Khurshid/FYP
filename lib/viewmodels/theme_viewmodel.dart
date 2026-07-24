import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/core/utils/app_constants.dart';
/// Manages and persists the app's [ThemeMode] (Light / Dark / System)
/// so the Settings screen's theme selector actually changes the app's
/// appearance and remembers the choice between launches.
class ThemeViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Loads the persisted theme choice, if any, on app start.
  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefKeyThemeMode);
    switch (saved) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyThemeMode, mode.name);
  }
}