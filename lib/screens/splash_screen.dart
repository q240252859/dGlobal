import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // 设置动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 设置淡入动画
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // 启动动画
    _animationController.forward();

    // 定时跳转
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 跳转到下一个页面
  Future<void> _navigateToNextScreen() async {
    // 延迟2秒，显示启动页
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // 检查是否已登录
      final isLoggedIn = await _authService.isLoggedIn();

      if (!mounted) return;

      // 根据登录状态决定跳转的页面
      if (isLoggedIn) {
        GoRouter.of(context).go(AppRoutes.main);
      } else {
        GoRouter.of(context).go(AppRoutes.login);
      }
    } catch (e) {
      // 发生错误时跳转到登录页
      if (!mounted) return;
      GoRouter.of(context).go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: Text(
                      'DG',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 48.sp,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // 应用名称
                Text(
                  'Decode Global',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),

                SizedBox(height: 50.h),

                // 加载指示器
                SizedBox(
                  width: 30.w,
                  height: 30.w,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                    strokeWidth: 3.w,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
