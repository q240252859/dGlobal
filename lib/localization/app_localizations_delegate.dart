import 'package:flutter/material.dart';
import 'app_localizations.dart';
import 'language_data.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizedStrings = LanguageData.getTranslations(locale.languageCode);
    return AppLocalizations(locale, localizedStrings);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
