import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  static const String _darkModeKey = 'isDarkMode';

  bool get isDarkMode => _isDarkMode;
  ThemeData get theme =>
      _isDarkMode ? AppTheme.getDarkTheme() : AppTheme.getLightTheme();

  ThemeProvider() {
    _loadThemePreference();
  }

  // 加载主题偏好
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  // 切换主题
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }

  // 设置主题
  Future<void> setDarkMode(bool darkMode) async {
    if (_isDarkMode != darkMode) {
      _isDarkMode = darkMode;
      _saveThemePreference();
      notifyListeners();
    }
  }

  // 保存主题偏好
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}
