import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../localization/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/market_service.dart';
import '../services/websocket_service.dart';
import '../models/market_model.dart';
import '../models/websocket_message.dart';
import '../utils/error_handler.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/market_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _marketService = MarketService();
  final _webSocketService = WebSocketService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  // 记录已订阅的市场代码
  final Set<String> _subscribedSymbols = {};
  List<Map<String, dynamic>> _newsItems = [];

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
      _initWebSocket();
      _loadMarkets();

      // 添加一个测试计时器，每5秒检查一次WebSocket连接状态
      Timer.periodic(const Duration(seconds: 5), (timer) {
        // debugPrint('WebSocket连接状态: ${_webSocketService.isConnected}');
        // debugPrint('已订阅市场数: ${_subscribedSymbols.length}');
      });
    });
  }

  @override
  void dispose() {
    // 取消所有订阅并关闭 WebSocket 连接
    _unsubscribeAllMarkets();
    _webSocketService.close();
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
    debugPrint('初始化WebSocket连接');

    // 先关闭可能存在的连接
    _webSocketService.close();

    // 尝试建立新连接
    await _webSocketService.connect();

    // 验证连接状态
    if (_webSocketService.isConnected) {
      debugPrint('WebSocket连接成功');
    } else {
      debugPrint('WebSocket连接失败');
      // 3秒后重试
      Future.delayed(const Duration(seconds: 3), _initWebSocket);
      return;
    }

    // 添加定期检查WebSocket连接状态的逻辑
    Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _checkWebSocketConnection();
    });

    // 添加一个测试机制，模拟价格更新 (仅用于调试)
    /*
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // 如果有市场数据，模拟一个价格更新
      final marketProvider =
          Provider.of<MarketProvider>(context, listen: false);
      if (marketProvider.allMarkets.isNotEmpty) {
        final testMarket = marketProvider.allMarkets.first;
        final testSymbol = testMarket.code;
        debugPrint('模拟价格更新: $testSymbol');

        // 创建随机价格
        final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000;
        final newPrice = testMarket.price * (1 + (random - 0.5) / 50);

        // 模拟MarketData更新
        final testData = MarketData(
          lastPrice: newPrice,
          high24h: testMarket.high24h ?? newPrice,
          low24h: testMarket.low24h ?? newPrice * 0.99,
          priceChange24h: newPrice - testMarket.price,
          volume24h: 100000,
        );

        marketProvider.updateMarketData(testSymbol, testData);
      }
    });
    */
  }

  // 检查WebSocket连接状态
  void _checkWebSocketConnection() async {
    if (!_webSocketService.isConnected) {
      debugPrint('检测到WebSocket连接已断开，尝试重新连接');
      await _webSocketService.connect();

      // 如果重新连接成功，重新订阅市场
      if (_webSocketService.isConnected) {
        debugPrint('WebSocket重新连接成功，重新订阅市场');
        _unsubscribeAllMarkets();
        _subscribeToMarketUpdates();
      }
    }
  }

  // 订阅市场数据更新
  void _subscribeToMarketUpdates() {
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    final allMarkets = marketProvider.allMarkets;

    if (allMarkets.isEmpty) {
      debugPrint('没有市场可订阅');
      return;
    }

    debugPrint('开始订阅市场数据，共 ${allMarkets.length} 个市场');

    // 先取消所有现有订阅
    _unsubscribeAllMarkets();

    // 每次批量订阅10个市场，避免一次性订阅过多
    const batchSize = 10;
    int subscribedCount = 0;

    void subscribeBatch() {
      final endIndex = (subscribedCount + batchSize > allMarkets.length)
          ? allMarkets.length
          : subscribedCount + batchSize;

      // debugPrint('订阅批次 $subscribedCount 到 $endIndex');

      for (int i = subscribedCount; i < endIndex; i++) {
        final market = allMarkets[i];
        final symbol = market.code;

        // 如果已经订阅过，跳过
        if (_subscribedSymbols.contains(symbol)) {
          // debugPrint('已订阅，跳过: $symbol');
          continue;
        }

        // debugPrint('订阅市场: $symbol');
        _webSocketService.subscribeToMarket(symbol, (data) {
          // debugPrint('收到市场数据: $symbol, 价格: ${data.lastPrice}');
          // 使用Provider更新数据
          final provider = Provider.of<MarketProvider>(context, listen: false);
          provider.updateMarketData(symbol, data);
        });

        _subscribedSymbols.add(symbol);
      }

      subscribedCount = endIndex;

      // 如果还有市场没订阅，延迟继续订阅下一批
      if (subscribedCount < allMarkets.length) {
        Future.delayed(const Duration(milliseconds: 500), subscribeBatch);
      } else {
        debugPrint('全部市场订阅完成，共 ${_subscribedSymbols.length} 个');
      }
    }

    // 开始订阅第一批
    subscribeBatch();
  }

  // 取消所有市场订阅
  void _unsubscribeAllMarkets() {
    for (final symbol in _subscribedSymbols) {
      _webSocketService.unsubscribe('market.$symbol');
    }
    _subscribedSymbols.clear();
  }

  Future<void> _loadMarkets() async {
    if (!mounted) return;

    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    marketProvider.setIsLoading(true);
    marketProvider.setError(null);

    try {
      final markets = await _marketService.getMarkets();
      final response = await _marketService.getMarketResponse();

      if (!mounted) return;

      // 过滤掉 symbols 为空的分类
      final categories = response.categories
          .where((category) => category.symbols.isNotEmpty)
          .toList();

      marketProvider.setCategories(categories);
      marketProvider.setMarkets(markets);

      // 确保保存首个交易商品用于交易页面
      if (categories.isNotEmpty && categories.first.symbols.isNotEmpty) {
        // 检查是否已有保存的首个交易商品
        final firstSymbol = await _marketService.getFirstSymbol();
        if (firstSymbol == null) {
          await _marketService.saveFirstSymbol(categories.first.symbols.first);
          debugPrint('保存首个交易商品: ${categories.first.symbols.first.code}');
        }
      }

      // 加载完市场数据后，订阅 WebSocket 更新
      _subscribeToMarketUpdates();
    } catch (e) {
      if (!mounted) return;
      marketProvider.setError(e.toString());
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;

    // 使用 pushReplacement 而不是 pushAndRemoveUntil，以保持本地化上下文
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _toggleTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }

  void _switchLanguage() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final newLocale = localeProvider.locale == 'en' ? 'zh' : 'en';
    localeProvider.setLocale(newLocale);
  }

  void _fetchNews() async {
    try {
      final marketProvider =
          Provider.of<MarketProvider>(context, listen: false);
      // 设置加载状态
      marketProvider.setIsLoading(true);
      marketProvider.setError(null);

      // 发送请求
      final response = await http.get(Uri.parse(
          'https://api.livecoinnews.com/news?limit=20&_=${DateTime.now().millisecondsSinceEpoch}'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('data')) {
          setState(() {
            _newsItems = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      // 设置错误状态
      final marketProvider =
          Provider.of<MarketProvider>(context, listen: false);
      marketProvider.setError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            themeProvider.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Text(
          'Decode Global',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: _toggleTheme,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.language,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: _switchLanguage,
          ),
        ],
      ),
      body: _buildHomeContent(),
    );
  }

  Widget _buildHomeContent() {
    // 使用Consumer读取市场数据，以便在数据变化时自动重建
    return Consumer<MarketProvider>(
      builder: (context, marketProvider, child) {
        if (marketProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${marketProvider.error}'),
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
            _buildCategoryTabs(marketProvider),
            Expanded(
              child: marketProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMarketList(marketProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryTabs(MarketProvider marketProvider) {
    final categories = marketProvider.categories;
    if (categories.isEmpty) {
      return SizedBox(
        height: 48.h,
        child: Center(
          child: SizedBox(
            width: 24.w,
            height: 24.h,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final sortedCategories = List.from(categories)
      ..sort((a, b) => b.sort.compareTo(a.sort));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: sortedCategories.map((category) {
            final isSelected =
                category.id.toString() == marketProvider.selectedCategory;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: InkWell(
                onTap: () {
                  marketProvider.setSelectedCategory(category.id.toString());
                },
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    getLocalizedTitle(category.title),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMarketList(MarketProvider marketProvider) {
    final filteredMarkets = marketProvider.filteredMarkets;
    if (filteredMarkets.isEmpty) {
      return const Center(
        child: Text('No markets available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMarkets,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: filteredMarkets.map((market) {
          return _buildMarketItem(market);
        }).toList(),
      ),
    );
  }

  Widget _buildMarketItem(MarketModel market) {
    final isUp = market.isUp;
    final changeColor = isUp ? Colors.green : Colors.red;

    // 添加调试日志查看价格
    // debugPrint(
    //     '构建市场项: ${market.code}, 价格: ${market.price}, 变化: ${market.changeValue}, 上涨: $isUp');

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.network(
            market.img,
            width: 40.w,
            height: 40.h,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 40.w,
                height: 40.h,
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4.w),
            if (isUp)
              Icon(Icons.arrow_upward, color: Colors.green, size: 16.w)
            else
              Icon(Icons.arrow_downward, color: Colors.red, size: 16.w),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '杠杆: ${market.lever}x',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12.sp,
              ),
            ),
            if (market.high24h != null && market.low24h != null)
              Text(
                '24h: ${market.low24h?.toStringAsFixed(market.digit)} - ${market.high24h?.toStringAsFixed(market.digit)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10.sp,
                ),
              ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PriceChangeAnimator(
              key: ValueKey(
                  'price-${market.code}-${market.price}'), // 添加key确保在价格变化时更新
              price: market.price,
              digits: market.digit,
              direction: isUp ? 1 : -1,
            ),
            Text(
              market.changePercentage,
              style: TextStyle(
                color: changeColor,
                fontSize: 12.sp,
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
  double _displayPrice = 0;

  @override
  void initState() {
    super.initState();
    _previousPrice = widget.price;
    _displayPrice = widget.price;
    // debugPrint('PriceAnimator初始化: 价格=${widget.price}, 方向=${widget.direction}');
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
      // debugPrint('价格变化: ${oldWidget.price} -> ${widget.price}');
      _previousPrice = oldWidget.price;
      _displayPrice = widget.price; // 更新显示价格
      _updateAnimation();
      _controller.forward(from: 0.0);
    }
  }

  void _updateAnimation() {
    final direction = widget.price > _previousPrice
        ? 1
        : (widget.price < _previousPrice ? -1 : 0);

    // debugPrint('更新动画: 旧价格=$_previousPrice, 新价格=${widget.price}, 方向=$direction');

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
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            _displayPrice.toStringAsFixed(widget.digits),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.direction > 0
                  ? Colors.green
                  : (widget.direction < 0 ? Colors.red : Colors.black),
            ),
          ),
        );
      },
    );
  }
}
