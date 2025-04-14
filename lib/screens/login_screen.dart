import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/common_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _authService = AuthService();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40.h),

              // Language switcher icon
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: () {
                    // Open language selector
                  },
                ),
              ),

              SizedBox(height: 20.h),

              // Title with highlighted part
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Login',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'Decode Global',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8.h),

              // Subtitle
              Text(
                'Decode Global Exchange | Flash Transaction for Institutional Accounts',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12.sp,
                ),
              ),

              SizedBox(height: 40.h),

              // Username field
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Password field
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: '******',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                  ),
                ),
              ),

              // 错误信息显示
              if (_errorMessage != null) ...[
                SizedBox(height: 16.h),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14.sp,
                  ),
                ),
              ],

              SizedBox(height: 32.h),

              // Login button
              PrimaryButton(
                text: 'Login',
                onPressed: _handleLogin,
                loading: _isLoading,
                height: 50.h,
              ),

              SizedBox(height: 16.h),

              // Demo button
              SecondaryButton(
                text: 'Directly to demo',
                onPressed: _handleDemo,
                height: 50.h,
              ),

              SizedBox(height: 32.h),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account yet? ",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14.sp,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to register screen
                    },
                    child: Text(
                      'Register now',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // 隐藏键盘
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // 表单验证
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = '用户名和密码不能为空';
      });
      return;
    }

    // 设置加载状态
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 调用登录API
      await _authService.login(username, password);

      // 登录成功，导航到主页
      if (!mounted) return;
      GoRouter.of(context).go(AppRoutes.main);
    } catch (e) {
      // 登录失败，显示错误信息
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      // 无论如何都结束加载状态
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleDemo() {
    // 直接进入演示模式
    GoRouter.of(context).go(AppRoutes.main);
  }
}
