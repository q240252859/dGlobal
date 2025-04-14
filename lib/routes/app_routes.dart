import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 导入页面
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/home_screen.dart';
import '../screens/trading_screen.dart';
import '../screens/position_screen.dart';
import '../screens/news_screen.dart';
import '../screens/profile_screen.dart';
import '../models/market_model.dart';

/// 应用路由配置
class AppRoutes {
  // 私有构造函数，防止实例化
  AppRoutes._();

  // 路由名称常量
  static const String splash = '/';
  static const String login = '/login';
  static const String main = '/main';
  static const String home = '/home';
  static const String trade = '/trade';
  static const String position = '/position';
  static const String news = '/news';
  static const String profile = '/profile';

  // 路由配置
  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,
    routes: [
      // 启动页
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // 登录页
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),

      // 主页（底部导航栏）
      GoRoute(
        path: main,
        builder: (context, state) => const MainScreen(),
      ),

      // 单独的页面路由
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: trade,
        builder: (context, state) {
          final extra = state.extra;
          return TradingScreen(market: extra is MarketModel ? extra : null);
        },
      ),

      GoRoute(
        path: position,
        builder: (context, state) => const PositionScreen(),
      ),

      GoRoute(
        path: news,
        builder: (context, state) => const NewsScreen(),
      ),

      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],

    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Text('No route defined for ${state.uri.toString()}'),
      ),
    ),
  );
}
