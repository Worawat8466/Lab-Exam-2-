import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemeLocalDataSource {
  Future<ThemeMode> getThemeMode();
  Future<ThemeMode> toggleThemeMode();
}

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  const ThemeLocalDataSourceImpl(this._preferences);

  static const String _themeKey = 'app_theme_mode';

  final SharedPreferences _preferences;

  @override
  Future<ThemeMode> getThemeMode() async {
    final current = _preferences.getString(_themeKey);
    if (current == 'dark') {
      return ThemeMode.dark;
    }

    return ThemeMode.light;
  }

  @override
  Future<ThemeMode> toggleThemeMode() async {
    final current = await getThemeMode();
    final target = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    await _preferences.setString(
      _themeKey,
      target == ThemeMode.dark ? 'dark' : 'light',
    );

    return target;
  }
}
