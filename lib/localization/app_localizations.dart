import 'package:flutter/material.dart';
import 'app_localizations_delegate.dart';

class AppLocalizations {
  final Locale locale;
  final Map<String, String> _localizedStrings;

  AppLocalizations(this.locale, this._localizedStrings);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  // 支持的语言列表
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('zh'), // Chinese
  ];

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  String get appName => translate('appName');
  String get home => translate('home');
  String get position => translate('position');
  String get trade => translate('trade');
  String get news => translate('news');
  String get my => translate('my');
  String get all => translate('all');
  String get futures => translate('futures');
  String get forex => translate('forex');
  String get crypto => translate('crypto');
  String get noMarketsAvailable => translate('noMarketsAvailable');
  String get retry => translate('retry');
  String get error => translate('error');
  String get login => translate('login');
  String get username => translate('username');
  String get password => translate('password');
  String get forgotPassword => translate('forgotPassword');
  String get register => translate('register');
  String get logout => translate('logout');
  String get settings => translate('settings');
  String get language => translate('language');
  String get theme => translate('theme');
  String get darkMode => translate('darkMode');
  String get lightMode => translate('lightMode');
  String get english => translate('english');
  String get chinese => translate('chinese');
  String get selectLanguage => translate('selectLanguage');
  String get leverage => translate('leverage');
  String get volume => translate('volume');
  String get price => translate('price');
  String get change => translate('change');
}
