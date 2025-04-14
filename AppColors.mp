enum AppThemeType {
  both,
  white,
  black,
}

class AppColors {
  static final AppColors _instance = AppColors();

  static AppColors get ins => _instance;

  bool get isNightMode => BackgroundEnum.black == GlobalProviders.themeProvider.backgroundEnum;

    /// 三级文本 -ok
  static Color thLevel3Color({int justTheme = 0}) {
    if (justTheme == 1) return Color(0xff505464).withOpacity(0.40);
    else if (justTheme == 2) return Color(0xffEBEBEB).withOpacity(0.60);
    switch (kThemeStyle) {
      case BackgroundEnum.black:
        return Color(0xffEBEBEB).withOpacity(0.60);
      case BackgroundEnum.white:
        return Color(0xff505464).withOpacity(0.40);
    }
  }

}