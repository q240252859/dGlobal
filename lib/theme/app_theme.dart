import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color _primaryColorLight = Colors.black;
  static const Color _primaryColorDark = Colors.white;

  static const Color _accentColorLight = Color(0xFF5D5FEF);
  static const Color _accentColorDark = Color(0xFF7B7DFF);

  static const Color _backgroundColorLight = Colors.white;
  static const Color _backgroundColorDark = Color(0xFF121212);

  static const Color _scaffoldBackgroundColorLight = Colors.white;
  static const Color _scaffoldBackgroundColorDark = Color(0xFF121212);

  static const Color _cardColorLight = Colors.white;
  static const Color _cardColorDark = Color(0xFF1E1E1E);

  static const Color _dividerColorLight = Color(0xFFE0E0E0);
  static const Color _dividerColorDark = Color(0xFF333333);

  static const Color _textColorLight = Color(0xFF333333);
  static const Color _textColorDark = Color(0xFFF0F0F0);

  static const Color _secondaryTextColorLight = Color(0xFF666666);
  static const Color _secondaryTextColorDark = Color(0xFFBBBBBB);

  static const Color _hintTextColorLight = Color(0xFF999999);
  static const Color _hintTextColorDark = Color(0xFF888888);

  static const Color _errorColorLight = Color(0xFFFF3B30);
  static const Color _errorColorDark = Color(0xFFFF453A);

  static const Color _successColorLight = Color(0xFF34C759);
  static const Color _successColorDark = Color(0xFF30D158);

  static const Color _warningColorLight = Color(0xFFFF9500);
  static const Color _warningColorDark = Color(0xFFFF9F0A);

  static const Color _infoColorLight = Color(0xFF007AFF);
  static const Color _infoColorDark = Color(0xFF0A84FF);

  static const Color _priceUpColorLight = Color(0xFF34C759);
  static const Color _priceUpColorDark = Color(0xFF30D158);

  static const Color _priceDownColorLight = Color(0xFFFF3B30);
  static const Color _priceDownColorDark = Color(0xFFFF453A);

  // 获取浅色主题
  static ThemeData getLightTheme() {
    return ThemeData.light().copyWith(
      primaryColor: _primaryColorLight,
      scaffoldBackgroundColor: _scaffoldBackgroundColorLight,
      cardColor: _cardColorLight,
      dividerColor: _dividerColorLight,
      colorScheme: const ColorScheme.light(
        primary: _primaryColorLight,
        secondary: _accentColorLight,
        background: _backgroundColorLight,
        error: _errorColorLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: _textColorLight,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _scaffoldBackgroundColorLight,
        foregroundColor: _primaryColorLight,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: _primaryColorLight),
        titleTextStyle: TextStyle(
          color: _primaryColorLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _scaffoldBackgroundColorLight,
        selectedItemColor: _primaryColorLight,
        unselectedItemColor: _secondaryTextColorLight,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: _textColorLight),
        displayMedium: TextStyle(color: _textColorLight),
        displaySmall: TextStyle(color: _textColorLight),
        headlineLarge: TextStyle(color: _textColorLight),
        headlineMedium: TextStyle(color: _textColorLight),
        headlineSmall: TextStyle(color: _textColorLight),
        titleLarge: TextStyle(color: _textColorLight),
        titleMedium: TextStyle(color: _textColorLight),
        titleSmall: TextStyle(color: _textColorLight),
        bodyLarge: TextStyle(color: _textColorLight),
        bodyMedium: TextStyle(color: _textColorLight),
        bodySmall: TextStyle(color: _textColorLight),
        labelLarge: TextStyle(color: _textColorLight),
        labelMedium: TextStyle(color: _textColorLight),
        labelSmall: TextStyle(color: _textColorLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[100],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: _hintTextColorLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColorLight,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColorLight,
          side: const BorderSide(color: _primaryColorLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColorLight,
        ),
      ),
      cardTheme: CardTheme(
        color: _cardColorLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: _cardColorLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _textColorLight,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColorLight;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColorLight.withOpacity(0.5);
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColorLight;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColorLight;
          }
          return null;
        }),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: _primaryColorLight,
        unselectedLabelColor: _secondaryTextColorLight,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _primaryColorLight, width: 2),
          ),
        ),
      ),
    );
  }

  // 获取深色主题
  static ThemeData getDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: _primaryColorDark,
      scaffoldBackgroundColor: _scaffoldBackgroundColorDark,
      cardColor: _cardColorDark,
      dividerColor: _dividerColorDark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryColorDark,
        secondary: _accentColorDark,
        background: _backgroundColorDark,
        error: _errorColorDark,
        onPrimary: _backgroundColorDark,
        onSecondary: _backgroundColorDark,
        onBackground: _textColorDark,
        onError: _backgroundColorDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _scaffoldBackgroundColorDark,
        foregroundColor: _primaryColorDark,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: _primaryColorDark),
        titleTextStyle: TextStyle(
          color: _primaryColorDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _scaffoldBackgroundColorDark,
        selectedItemColor: _primaryColorDark,
        unselectedItemColor: _secondaryTextColorDark,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: _textColorDark),
        displayMedium: TextStyle(color: _textColorDark),
        displaySmall: TextStyle(color: _textColorDark),
        headlineLarge: TextStyle(color: _textColorDark),
        headlineMedium: TextStyle(color: _textColorDark),
        headlineSmall: TextStyle(color: _textColorDark),
        titleLarge: TextStyle(color: _textColorDark),
        titleMedium: TextStyle(color: _textColorDark),
        titleSmall: TextStyle(color: _textColorDark),
        bodyLarge: TextStyle(color: _textColorDark),
        bodyMedium: TextStyle(color: _textColorDark),
        bodySmall: TextStyle(color: _textColorDark),
        labelLarge: TextStyle(color: _textColorDark),
        labelMedium: TextStyle(color: _textColorDark),
        labelSmall: TextStyle(color: _textColorDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: const Color(0xFF2A2A2A),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: _hintTextColorDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColorDark,
          foregroundColor: _backgroundColorDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColorDark,
          side: const BorderSide(color: _primaryColorDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColorDark,
        ),
      ),
      cardTheme: CardTheme(
        color: _cardColorDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: _cardColorDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _textColorDark,
        contentTextStyle: const TextStyle(color: _backgroundColorDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColorDark;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColorDark.withOpacity(0.5);
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColorDark;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColorDark;
          }
          return null;
        }),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: _primaryColorDark,
        unselectedLabelColor: _secondaryTextColorDark,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _primaryColorDark, width: 2),
          ),
        ),
      ),
    );
  }

  // 颜色工具类 - 根据当前主题模式获取颜色
  static Color getColor(
      BuildContext context, Color lightColor, Color darkColor) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightColor : darkColor;
  }

  // 获取价格上涨颜色
  static Color getPriceUpColor(BuildContext context) {
    return getColor(context, _priceUpColorLight, _priceUpColorDark);
  }

  // 获取价格下跌颜色
  static Color getPriceDownColor(BuildContext context) {
    return getColor(context, _priceDownColorLight, _priceDownColorDark);
  }

  // 获取成功颜色
  static Color getSuccessColor(BuildContext context) {
    return getColor(context, _successColorLight, _successColorDark);
  }

  // 获取警告颜色
  static Color getWarningColor(BuildContext context) {
    return getColor(context, _warningColorLight, _warningColorDark);
  }

  // 获取错误颜色
  static Color getErrorColor(BuildContext context) {
    return getColor(context, _errorColorLight, _errorColorDark);
  }

  // 获取信息颜色
  static Color getInfoColor(BuildContext context) {
    return getColor(context, _infoColorLight, _infoColorDark);
  }
}
