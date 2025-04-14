import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  static const String _localeKey = 'locale';
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('zh'), // Chinese
  ];

  Locale get locale => _locale;
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isChinese => _locale.languageCode == 'zh';

  // 获取当前语言对应的名称
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'zh':
        return '中文';
      case 'en':
      default:
        return 'English';
    }
  }

  LocaleProvider() {
    _loadLocalePreference();
  }

  // 加载语言偏好
  Future<void> _loadLocalePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localeKey);
      if (languageCode != null) {
        _locale = Locale(languageCode);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading locale preference: $e');
    }
  }

  // 设置语言
  Future<void> setLocale(String languageCode) async {
    if (_locale.languageCode != languageCode) {
      _locale = Locale(languageCode);
      _saveLocalePreference();
      notifyListeners();
    }
  }

  // 切换语言（在英文和中文之间）
  Future<void> toggleLocale() async {
    final newLanguageCode = _locale.languageCode == 'en' ? 'zh' : 'en';
    await setLocale(newLanguageCode);
  }

  // 保存语言偏好
  Future<void> _saveLocalePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, _locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale preference: $e');
    }
  }

  // 设置为英文
  Future<void> setEnglish() async {
    await setLocale('en');
  }

  // 设置为中文
  Future<void> setChinese() async {
    await setLocale('zh');
  }
}
