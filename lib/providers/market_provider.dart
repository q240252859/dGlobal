import 'package:flutter/foundation.dart';
import '../models/market_model.dart';
import '../models/websocket_message.dart';
import '../services/market_service.dart';

class MarketProvider with ChangeNotifier {
  final MarketService _marketService = MarketService();

  List<MarketModel> _allMarkets = [];
  List<MarketModel> _filteredMarkets = [];
  List<MarketCategory> _categories = [];
  String _selectedCategory = '1';
  bool _isLoading = true;
  String? _error;

  // Getters
  List<MarketModel> get allMarkets => _allMarkets;
  List<MarketModel> get filteredMarkets => _filteredMarkets;
  List<MarketCategory> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 设置所有市场数据
  void setMarkets(List<MarketModel> markets) {
    _allMarkets = markets;
    _filterMarkets();
    _isLoading = false;
    notifyListeners();
  }

  // 设置分类数据
  void setCategories(List<MarketCategory> categories) {
    _categories = categories;
    notifyListeners();
  }

  // 设置选中的分类
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    _filterMarkets();
    notifyListeners();
  }

  // 设置加载状态
  void setIsLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  // 设置错误信息
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // 过滤市场数据
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

  // 通过WebSocket更新市场数据
  void updateMarketData(String symbol, MarketData data) {
    // 确保价格大于0才更新
    if (data.lastPrice <= 0) {
      return;
    }

    // 判断是否需要更新
    bool needsUpdate = false;

    // 更新全部市场数据列表中的相应市场
    final marketIndex = _allMarkets.indexWhere((m) =>
        m.code.toLowerCase() == symbol.toLowerCase() ||
        (m.code2 != null && m.code2!.toLowerCase() == symbol.toLowerCase()));

    if (marketIndex >= 0) {
      final market = _allMarkets[marketIndex];

      // 创建更新后的市场模型
      final updatedMarket = MarketModel(
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

      // 更新数据
      _allMarkets[marketIndex] = updatedMarket;
      needsUpdate = true;

      // 更新已过滤的市场数据列表
      final filteredIndex = _filteredMarkets.indexWhere((m) =>
          m.code.toLowerCase() == symbol.toLowerCase() ||
          (m.code2 != null && m.code2!.toLowerCase() == symbol.toLowerCase()));

      if (filteredIndex >= 0) {
        _filteredMarkets[filteredIndex] = updatedMarket;
      }
    }

    // 只有在实际更新了数据时才通知监听器
    if (needsUpdate) {
      notifyListeners();
    }
  }

  // 清空所有数据（例如在注销时）
  void clear() {
    _allMarkets = [];
    _filteredMarkets = [];
    _categories = [];
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  // 加载市场分类数据
  Future<void> loadMarketCategories() async {
    setIsLoading(true);
    setError(null);

    try {
      final response = await _marketService.getMarketResponse();
      _categories = response.categories;

      // 同时设置所有市场数据
      List<MarketModel> allMarkets = [];
      for (var category in _categories) {
        allMarkets.addAll(category.symbols);
      }
      setMarkets(allMarkets);

      // 保存首个交易商品（如果有）
      if (_categories.isNotEmpty && _categories.first.symbols.isNotEmpty) {
        await _marketService.saveFirstSymbol(_categories.first.symbols.first);
      }

      setIsLoading(false);
    } catch (e) {
      setError(e.toString());
      setIsLoading(false);
    }
  }

  // 获取首个交易商品（用于交易页面）
  Future<MarketModel?> getFirstSymbol() async {
    try {
      // 尝试从本地获取
      MarketModel? firstSymbol = await _marketService.getFirstSymbol();

      // 如果本地没有，尝试从当前内存中获取
      if (firstSymbol == null &&
          _categories.isNotEmpty &&
          _categories.first.symbols.isNotEmpty) {
        firstSymbol = _categories.first.symbols.first;
      }

      return firstSymbol;
    } catch (e) {
      print('Error getting first symbol: $e');
      return null;
    }
  }

  // 初始化市场数据
  Future<void> initialize() async {
    try {
      await loadMarketCategories();

      // 确保首个交易商品已保存
      final firstSymbol = await getFirstSymbol();
      if (firstSymbol == null &&
          _categories.isNotEmpty &&
          _categories.first.symbols.isNotEmpty) {
        await _marketService.saveFirstSymbol(_categories.first.symbols.first);
        print('初始化时保存首个交易商品: ${_categories.first.symbols.first.code}');
      } else if (firstSymbol != null) {
        print('已有保存的交易商品: ${firstSymbol.code}');
      }
    } catch (e) {
      setError(e.toString());
      print('初始化市场数据失败: $e');
    }
  }
}
