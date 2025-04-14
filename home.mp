import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/market_service.dart';
import '../services/websocket_service.dart';
import '../models/market_model.dart';
import '../models/websocket_message.dart';
import '../utils/error_handler.dart';
import 'trade_page.dart';
import 'position_page.dart';
import 'my_page.dart';
import 'news/news_list_page.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Import the ThemeProvider and LocaleProvider classes from main.dart
import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _authService = AuthService();
  final _marketService = MarketService();
  final _webSocketService = WebSocketService();
  bool _isLoading = true;
  bool _isLoadingMarkets = true;
  bool _isAuthenticated = false;
  String _selectedCategory = '1';
  List<MarketCategory> _categories = [];
  List<MarketModel> _allMarkets = [];
  List<MarketModel> _filteredMarkets = [];
  String? _error;
  // 记录已订阅的市场代码
  final Set<String> _subscribedSymbols = {};
  bool _isDarkMode = false;
  String _selectedLanguage = 'en'; // Default language

  final List<Widget> _pages = [
    const TradePage(),
    const PositionPage(),
    const NewsListPage(),
    const MyPage(),
  ];

  Map<String, String> localizedTitles = {
    '全部': 'All',
    '期货': 'Futures',
    '外汇': 'Forex',
    '加密货币': 'Crypto',
    // Add more translations if needed
  };

  @override
  void initState() {
    super.initState();
    // 延迟检查认证状态，确保本地化系统已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
      _loadMarkets();
      _initWebSocket();
    });
    _loadPreferences();
  }

  @override
  void dispose() {
    // 取消所有订阅并关闭 WebSocket 连接
    _unsubscribeAllMarkets();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!mounted) return;

      if (!isLoggedIn) {
        _navigateToLogin();
      } else {
        setState(() {
          _isLoading = false;
          _isAuthenticated = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _navigateToLogin();
    }
  }

  // 初始化 WebSocket 连接
  Future<void> _initWebSocket() async {
    await _webSocketService.connect();
  }

  // 订阅市场数据更新
  void _subscribeToMarketUpdates() {
    if (_allMarkets.isEmpty) return;

    // 不限制订阅数量，确保所有市场都能更新
    for (final market in _allMarkets) {
      // 如果已经订阅过，跳过
      if (_subscribedSymbols.contains(market.code)) continue;

      _webSocketService.subscribeToMarket(market.code, (data) {
        _updateMarketData(market.code, data);
      });

      _subscribedSymbols.add(market.code);
    }
  }

  // 取消所有市场订阅
  void _unsubscribeAllMarkets() {
    for (final symbol in _subscribedSymbols) {
      _webSocketService.unsubscribe('market.$symbol');
    }
    _subscribedSymbols.clear();
  }

  // 更新市场数据
  void _updateMarketData(String symbol, MarketData data) {
    if (!mounted) return;

    setState(() {
      // 更新全部市场数据列表中的相应市场
      final marketIndex =
          _allMarkets.indexWhere((m) => m.code == symbol || m.code2 == symbol);
      if (marketIndex >= 0) {
        final market = _allMarkets[marketIndex];
        // 只有当WebSocket推送的价格大于0时才更新价格
        if (data.lastPrice > 0) {
          _allMarkets[marketIndex] = MarketModel(
            id: market.id,
            code: market.code,
            code2: market.code2,
            name: market.name,
            nameCode: market.nameCode,
            type: market.type,
            img: market.img,
            digit: market.digit,
            lever: market.lever,
            change: data.priceChange24h.toString(),
            changeStatus: data.priceChange24h >= 0 ? 1 : 3,
            price: data.lastPrice,
            changeValue: data.priceChange24h,
            high24h: data.high24h,
            low24h: data.low24h,
          );
        }
      }

      // 更新已过滤的市场数据列表
      final filteredIndex = _filteredMarkets
          .indexWhere((m) => m.code == symbol || m.code2 == symbol);
      if (filteredIndex >= 0) {
        final market = _filteredMarkets[filteredIndex];
        // 只有当WebSocket推送的价格大于0时才更新价格
        if (data.lastPrice > 0) {
          _filteredMarkets[filteredIndex] = MarketModel(
            id: market.id,
            code: market.code,
            code2: market.code2,
            name: market.name,
            nameCode: market.nameCode,
            type: market.type,
            img: market.img,
            digit: market.digit,
            lever: market.lever,
            change: data.priceChange24h.toString(),
            changeStatus: data.priceChange24h >= 0 ? 1 : 3,
            price: data.lastPrice,
            changeValue: data.priceChange24h,
            high24h: data.high24h,
            low24h: data.low24h,
          );
        }
      }
    });
  }

  Future<void> _loadMarkets() async {
    if (!mounted) return;

    setState(() {
      _isLoadingMarkets = true;
      _error = null;
    });

    try {
      final markets = await _marketService.getMarkets();
      final response = await _marketService.getMarketResponse();

      if (!mounted) return;

      setState(() {
        // 过滤掉 symbols 为空的分类
        _categories = response.categories
            .where((category) => category.symbols.isNotEmpty)
            .toList();

        _allMarkets = markets;
        _filterMarkets();
        _isLoadingMarkets = false;
      });

      // 加载完市场数据后，订阅 WebSocket 更新
      _subscribeToMarketUpdates();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingMarkets = false;
      });
    }
  }

  void _filterMarkets() {
    if (_selectedCategory == '1' || _selectedCategory == 'all') {
      _filteredMarkets = List.from(_allMarkets);
    } else {
      // 查找选中类别的市场数据
      final selectedCategoryObj = _categories.firstWhere(
        (category) => category.id.toString() == _selectedCategory,
        orElse: () => MarketCategory(id: 0, title: '', sort: 0, symbols: []),
      );

      if (selectedCategoryObj.symbols.isNotEmpty) {
        _filteredMarkets = selectedCategoryObj.symbols;
      } else {
        // 根据类型过滤（备用方案）
        final Map<String, String> categoryToType = {
          '2': 'metal',
          '3': 'forex',
          '4': 'crypto',
        };

        final type = categoryToType[_selectedCategory];
        if (type != null) {
          _filteredMarkets =
              _allMarkets.where((market) => market.type == type).toList();
        } else {
          _filteredMarkets = [];
        }
      }
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;

    // 使用 pushReplacement 而不是 pushAndRemoveUntil，以保持本地化上下文
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
        settings: const RouteSettings(name: '/login'),
      ),
    );
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                onTap: () {
                  // Set language to English
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('中文'),
                onTap: () {
                  // Set language to Chinese
                  Navigator.of(context).pop();
                },
              ),
              // Add more languages here
            ],
          ),
        );
      },
    );
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'en';
    });
  }

  void _toggleTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme(!themeProvider.isDarkMode);
  }

  void _switchLanguage() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final newLocale = localeProvider.locale == 'en' ? 'zh' : 'en';
    localeProvider.setLocale(newLocale);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: _currentIndex != 0
          ? null
          : AppBar(
              leading: IconButton(
                icon: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
                onPressed: _toggleTheme,
              ),
              title: Text('Decode Global'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: _switchLanguage,
                ),
              ],
            ),
      body: _currentIndex == 0
          ? _buildHomeContent()
          : IndexedStack(
              index: _currentIndex - 1,
              children: _pages,
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_outlined),
            activeIcon: const Icon(Icons.account_balance),
            label: 'Position',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.swap_horiz, color: Colors.white),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.article_outlined),
            activeIcon: const Icon(Icons.article),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'My',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMarkets,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildCategoryTabs(),
        Expanded(
          child: _isLoadingMarkets
              ? const Center(child: CircularProgressIndicator())
              : _buildMarketList(),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    if (_categories.isEmpty) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final sortedCategories = List.from(_categories)
      ..sort((a, b) => b.sort.compareTo(a.sort));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: sortedCategories.map((category) {
            final isSelected = category.id.toString() == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = category.id.toString();
                    _filterMarkets();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? Colors.black : Colors.grey[200],
                  foregroundColor: isSelected ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Text(getLocalizedTitle(category.title)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMarketList() {
    if (_filteredMarkets.isEmpty) {
      return const Center(
        child: Text('No markets available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMarkets,
      child: ListView.builder(
        itemCount: _filteredMarkets.length,
        itemBuilder: (context, index) {
          final market = _filteredMarkets[index];
          return _buildMarketItem(market);
        },
      ),
    );
  }

  Widget _buildMarketItem(MarketModel market) {
    final isUp = market.isUp;
    final changeColor = isUp ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            market.img,
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 40,
                height: 40,
                color: Colors.grey[200],
                child: Icon(
                  Icons.currency_exchange,
                  color: Colors.grey[400],
                ),
              );
            },
          ),
        ),
        title: Row(
          children: [
            Text(
              market.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            if (isUp)
              Icon(Icons.arrow_upward, color: Colors.green, size: 16)
            else
              Icon(Icons.arrow_downward, color: Colors.red, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '杠杆: ${market.lever}x',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (market.high24h != null && market.low24h != null)
              Text(
                '24h: ${market.low24h?.toStringAsFixed(market.digit)} - ${market.high24h?.toStringAsFixed(market.digit)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PriceChangeAnimator(
              price: market.price,
              digits: market.digit,
              direction: isUp ? 1 : -1,
            ),
            Text(
              market.changePercentage,
              style: TextStyle(
                color: changeColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/trade',
            arguments: market,
          );
        },
      ),
    );
  }

  String getLocalizedTitle(String originalTitle) {
    return localizedTitles[originalTitle] ?? originalTitle;
  }
}

// 价格变化动画组件
class PriceChangeAnimator extends StatefulWidget {
  final double price;
  final int digits;
  final int direction; // 1: 上涨, -1: 下跌, 0: 不变

  const PriceChangeAnimator({
    Key? key,
    required this.price,
    required this.digits,
    required this.direction,
  }) : super(key: key);

  @override
  State<PriceChangeAnimator> createState() => _PriceChangeAnimatorState();
}

class _PriceChangeAnimatorState extends State<PriceChangeAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late double _previousPrice;

  @override
  void initState() {
    super.initState();
    _previousPrice = widget.price;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(PriceChangeAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.price != widget.price) {
      _previousPrice = oldWidget.price;
      _updateAnimation();
      _controller.forward(from: 0.0);
    }
  }

  void _updateAnimation() {
    final direction = widget.price > _previousPrice
        ? 1
        : (widget.price < _previousPrice ? -1 : 0);

    if (direction == 1) {
      _colorAnimation = ColorTween(
        begin: Colors.green.withOpacity(0.3),
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
    } else if (direction == -1) {
      _colorAnimation = ColorTween(
        begin: Colors.red.withOpacity(0.3),
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
    } else {
      _colorAnimation = ColorTween(
        begin: Colors.transparent,
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.price.toStringAsFixed(widget.digits),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
