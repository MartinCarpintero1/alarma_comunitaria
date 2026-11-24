import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadSavedTheme();
    return ThemeMode.dark; // Default to Nocturno
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLight = prefs.getBool('isLightMode') ?? false;
      state = isLight ? ThemeMode.light : ThemeMode.dark;
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final isCurrentDark = state == ThemeMode.dark;
    state = isCurrentDark ? ThemeMode.light : ThemeMode.dark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLightMode', state == ThemeMode.light);
    } catch (_) {}
  }
}
