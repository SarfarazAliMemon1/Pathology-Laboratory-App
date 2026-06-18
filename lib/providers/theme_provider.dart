import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme_mode');
    state = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme(ThemeMode newMode) async {
    state = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', newMode == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
