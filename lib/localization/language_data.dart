class LanguageData {
  static Map<String, String> getTranslations(String languageCode) {
    switch (languageCode) {
      case 'zh':
        return _zhTranslations;
      case 'en':
      default:
        return _enTranslations;
    }
  }

  static final Map<String, String> _enTranslations = {
    'appName': 'Decode Global',
    'home': 'Home',
    'position': 'Position',
    'trade': 'Trade',
    'news': 'News',
    'my': 'My',
    'all': 'All',
    'futures': 'Futures',
    'forex': 'Forex',
    'crypto': 'Crypto',
    'noMarketsAvailable': 'No markets available',
    'retry': 'Retry',
    'error': 'Error',
    'login': 'Login',
    'username': 'Username',
    'password': 'Password',
    'forgotPassword': 'Forgot Password?',
    'register': 'Register',
    'logout': 'Logout',
    'settings': 'Settings',
    'language': 'Language',
    'theme': 'Theme',
    'darkMode': 'Dark Mode',
    'lightMode': 'Light Mode',
    'english': 'English',
    'chinese': 'Chinese',
    'selectLanguage': 'Select Language',
    'leverage': 'Leverage',
    'volume': 'Volume',
    'price': 'Price',
    'change': 'Change',
  };

  static final Map<String, String> _zhTranslations = {
    'appName': 'Decode Global',
    'home': '首页',
    'position': '持仓',
    'trade': '交易',
    'news': '资讯',
    'my': '我的',
    'all': '全部',
    'futures': '期货',
    'forex': '外汇',
    'crypto': '加密货币',
    'noMarketsAvailable': '没有可用市场',
    'retry': '重试',
    'error': '错误',
    'login': '登录',
    'username': '用户名',
    'password': '密码',
    'forgotPassword': '忘记密码？',
    'register': '注册',
    'logout': '退出登录',
    'settings': '设置',
    'language': '语言',
    'theme': '主题',
    'darkMode': '深色模式',
    'lightMode': '浅色模式',
    'english': '英文',
    'chinese': '中文',
    'selectLanguage': '选择语言',
    'leverage': '杠杆',
    'volume': '成交量',
    'price': '价格',
    'change': '涨跌幅',
  };
}
