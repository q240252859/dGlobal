import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_tabbar.dart';

import 'home_screen.dart';
import 'position_screen.dart';
import 'trading_screen.dart';
import 'news_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;

  final List<String> _tabTitles = [
    'Home',
    'Position',
    'News',
    'My',
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const PositionScreen(),
    const NewsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);

    // Set initial index and add listener
    _tabController.index = _currentIndex;
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    // Only update when the tab actually changes (not during animation)
    if (_tabController.indexIsChanging == false) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Using MediaQuery to get safe area information
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      // Wrap main body in SafeArea with bottom false since we handle it in the tab bar
      body: SafeArea(
        bottom:
            false, // Don't apply bottom padding, as we handle it in the CustomTabBar
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      // Use extendBody to let the body render below the bottom navigation bar
      extendBody: true,
      bottomNavigationBar: CustomTabBar(
        tabs: _tabTitles,
        controller: _tabController,
        onTabChanged: (index) {
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
              _tabController.animateTo(index);
            });
          }
        },
        onMiddleButtonPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TradingScreen()),
          );
        },
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        indicatorColor: isDarkMode ? Colors.white : Colors.black,
        selectedTextColor: isDarkMode ? Colors.white : Colors.black,
        unselectedTextColor: isDarkMode ? Colors.grey[500]! : Colors.grey[600]!,
        middleButtonColor: isDarkMode ? Colors.white : Colors.black,
        middleButtonIcon: Icons.swap_horiz,
        middleButtonLabel: "Trade",
      ),
    );
  }
}
