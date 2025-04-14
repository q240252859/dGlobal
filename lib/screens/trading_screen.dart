import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/market_model.dart';
import '../models/kline_bean.dart';
import '../providers/market_provider.dart';
import '../providers/theme_provider.dart';
import '../services/market_service.dart';
import '../services/account_service.dart';
import '../services/trade_service.dart';

// Define constant colors for better readability and potential central management
const Color _upColor = Colors.green;
const Color _downColor = Colors.red;

class TradingScreen extends StatefulWidget {
  final MarketModel? market;

  const TradingScreen({super.key, this.market});

  @override
  _TradingScreenState createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  final MarketService _marketService = MarketService();
  final AccountService _accountService = AccountService();
  final TradeService _tradeService = TradeService();

  MarketModel? _currentSymbol;
  List<KlineBean> _klineData = [];
  bool _isLoading = true;
  String? _error;

  // K线类型 (默认为日线)
  int _klineType = 8;

  // Account info
  double _balance = 0;
  AccountInfoModel? _accountInfo;

  // Trading Form State
  final TextEditingController _quantityController =
      TextEditingController(text: "0.1");
  final TextEditingController _takeProfitController = TextEditingController();
  final TextEditingController _stopLossController = TextEditingController();
  bool _useTakeProfit = false;
  bool _useStopLoss = false;
  double _quantity = 0.1;
  double? _takeProfitPrice;
  double? _stopLossPrice;
  bool _isPlacingOrder = false;

  // Estimated values (will need calculation logic)
  double _estimatedVolumeValue = 0.0;
  double _estimatedMargin = 0.0;
  double _maxVolume = 0.0; // This might need to come from API or config

  // Refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Initialize form values
    _quantityController.addListener(_onQuantityChanged);
    _takeProfitController.addListener(_onTakeProfitChanged);
    _stopLossController.addListener(_onStopLossChanged);

    // Use market from widget if available
    if (widget.market != null) {
      _currentSymbol = widget.market;
      _loadTradingDataWithSymbol();
    } else {
      _loadTradingData();
    }

    // Setup refresh timer
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshAccountInfo(); // Refresh balance more frequently
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    _takeProfitController.removeListener(_onTakeProfitChanged);
    _takeProfitController.dispose();
    _stopLossController.removeListener(_onStopLossChanged);
    _stopLossController.dispose();
    super.dispose();
  }

  // Listeners for form changes
  void _onQuantityChanged() {
    setState(() {
      _quantity = double.tryParse(_quantityController.text) ?? 0.1;
      _updateEstimatedValues();
    });
  }

  void _onTakeProfitChanged() {
    setState(() {
      _takeProfitPrice = double.tryParse(_takeProfitController.text);
    });
  }

  void _onStopLossChanged() {
    setState(() {
      _stopLossPrice = double.tryParse(_stopLossController.text);
    });
  }

  // Placeholder for calculation logic
  void _updateEstimatedValues() {
    if (_currentSymbol == null) return;
    // TODO: Implement actual calculation based on symbol data, leverage, quantity, etc.
    // Example placeholder calculation:
    _estimatedVolumeValue =
        _quantity * _currentSymbol!.price * 10000; // Example contract size
    _estimatedMargin = _estimatedVolumeValue /
        (int.tryParse(_currentSymbol!.lever) ?? 1); // Example margin calc
    _maxVolume = (_accountInfo?.availableBalance ?? 0) *
        (int.tryParse(_currentSymbol!.lever) ?? 1) /
        _currentSymbol!.price /
        10000;
  }

  // 使用已知Symbol加载交易页面数据
  Future<void> _loadTradingDataWithSymbol() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 获取K线数据
      await _refreshKlineData();

      // 获取账户余额
      await _refreshAccountInfo();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // 加载交易页面数据
  Future<void> _loadTradingData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. 获取用于交易的商品
      final marketProvider =
          Provider.of<MarketProvider>(context, listen: false);
      final symbol = await marketProvider.getFirstSymbol();

      if (symbol == null) {
        throw Exception('No trading symbol available');
      }

      _currentSymbol = symbol;

      // 2. 获取K线数据
      await _refreshKlineData();

      // 3. 获取账户余额
      await _refreshAccountInfo();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // 刷新K线数据
  Future<void> _refreshKlineData() async {
    if (_currentSymbol == null) return;

    try {
      final data = await _marketService.getKlineData(
        code: _currentSymbol!.code,
        klineType: _klineType,
      );

      setState(() {
        _klineData = data;
      });
    } catch (e) {
      print('Error refreshing K-line data: $e');
      // 不设置错误状态，避免影响UI
    }
  }

  // 刷新账户信息
  Future<void> _refreshAccountInfo() async {
    try {
      final accountInfo = await _accountService.getAccountInfo();
      setState(() {
        _accountInfo = accountInfo;
        _balance = accountInfo.balance; // Also update the general balance
        _updateEstimatedValues(); // Recalculate estimations when balance updates
      });
      print(
          'Account info updated: Balance: ${_balance.toStringAsFixed(2)}, Available: ${_accountInfo?.availableBalance.toStringAsFixed(2)}');
    } catch (e) {
      print('Error refreshing account info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    // Get theme colors
    final ThemeData theme = Theme.of(context);
    final Color scaffoldBackgroundColor = theme.scaffoldBackgroundColor;
    final Color primaryTextColor = theme.textTheme.bodyLarge?.color ??
        (isDarkMode ? Colors.white : Colors.black);
    final Color secondaryTextColor = theme.textTheme.bodyMedium?.color ??
        (isDarkMode ? Colors.grey[400]! : Colors.grey[600]!);
    final Color cardBackgroundColor = theme.cardColor;
    final Color chartBackgroundColor =
        isDarkMode ? Colors.grey[900]! : Colors.grey[100]!;
    final Color dividerColor = theme.dividerColor;
    final Color inputFillColor =
        isDarkMode ? Colors.grey[900]! : Colors.grey[200]!;
    final Color buttonBackgroundColor =
        isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color buttonIconColor = primaryTextColor;
    final Color disabledButtonColor =
        isDarkMode ? Colors.grey[900]! : Colors.grey[400]!;
    final Color disabledIconColor =
        isDarkMode ? Colors.grey[600]! : Colors.grey[500]!;
    final Color checkboxColor = theme.colorScheme.primary;
    final Color gridColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color labelColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      // Use Theme color
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        // Use Theme color
        backgroundColor: cardBackgroundColor,
        elevation: 0,
        title: _currentSymbol != null
            ? Text(
                '${_currentSymbol!.name} (${_currentSymbol!.code})',
                style: TextStyle(
                  // Use Theme color
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Text(
                'Trading',
                style: TextStyle(
                  // Use Theme color
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
        iconTheme: IconThemeData(
            color: primaryTextColor), // Ensure back button uses theme color
        actions: [
          IconButton(
            icon: Icon(Icons.refresh,
                // Use Theme color
                color: primaryTextColor),
            onPressed: () {
              _refreshKlineData();
              _refreshAccountInfo();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      'Error: $_error',
                      // Use standard error color
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    // Ensure column background matches scaffold
                    // crossAxisAlignment: CrossAxisAlignment.stretch, // Make children take full width if needed
                    children: [
                      // Market info card
                      _buildMarketInfoCard(cardBackgroundColor,
                          primaryTextColor, secondaryTextColor),

                      // Chart container - Use SizedBox for fixed height relative to screen
                      SizedBox(
                        height: MediaQuery.of(context).size.height *
                            0.4, // Approx 40% screen height
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          // Use theme-based background
                          color: chartBackgroundColor,
                          child: _klineData.isEmpty
                              ? Center(
                                  child: Text(
                                    'No K-line data available',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      // Use Theme color
                                      color: primaryTextColor,
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'K-line Chart: ${_currentSymbol?.code ?? ""}',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            // Use Theme color
                                            color: primaryTextColor,
                                          ),
                                        ),
                                        Text(
                                          _getKlineTypeLabel(_klineType),
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            // Use Theme color
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),
                                    Expanded(
                                      // Pass theme colors to chart
                                      child: _buildKChart(
                                        gridColor,
                                        labelColor,
                                        _upColor, // Keep specific up/down colors
                                        _downColor,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // Trading controls
                      _buildTradingControls(
                          cardBackgroundColor,
                          primaryTextColor,
                          secondaryTextColor,
                          inputFillColor,
                          buttonBackgroundColor,
                          buttonIconColor,
                          disabledButtonColor,
                          disabledIconColor,
                          checkboxColor),
                    ],
                  ),
                ),
    );
  }

  // Pass colors as parameters
  Widget _buildMarketInfoCard(
      Color backgroundColor, Color primaryTextColor, Color secondaryTextColor) {
    if (_currentSymbol == null) return SizedBox();

    return Container(
      padding: EdgeInsets.all(16.w),
      color: backgroundColor, // Use passed color
      child: Row(
        children: [
          // Symbol info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentSymbol!.code,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: primaryTextColor, // Use passed color
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _currentSymbol!.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: secondaryTextColor, // Use passed color
                  ),
                ),
              ],
            ),
          ),

          // Price info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Price: ${_currentSymbol!.price.toStringAsFixed(_currentSymbol!.digit)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    // Keep specific up/down colors
                    color: _currentSymbol!.isUp ? _upColor : _downColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Change: ${_currentSymbol!.changePercentage}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    // Keep specific up/down colors
                    color: _currentSymbol!.isUp ? _upColor : _downColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pass colors as parameters
  Widget _buildTradingControls(
    Color backgroundColor,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color inputFillColor,
    Color buttonBackgroundColor,
    Color buttonIconColor,
    Color disabledButtonColor,
    Color disabledIconColor,
    Color checkboxColor,
  ) {
    // Ensure controllers reflect the state
    if (_quantityController.text != _quantity.toString()) {
      _quantityController.text = _quantity.toString();
    }
    if (_takeProfitController.text != (_takeProfitPrice?.toString() ?? '')) {
      _takeProfitController.text = _takeProfitPrice?.toString() ?? '';
    }
    if (_stopLossController.text != (_stopLossPrice?.toString() ?? '')) {
      _stopLossController.text = _stopLossPrice?.toString() ?? '';
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      color: backgroundColor, // Use passed color
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity section
          Text(
            'Quantity',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: primaryTextColor, // Use passed color
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildCircleButton(
                icon: Icons.remove,
                onTap: () {
                  setState(() {
                    _quantity = (_quantity - 0.1).clamp(0.1,
                        _maxVolume); // Ensure minimum 0.1 and not exceed max
                    _quantityController.text = _quantity.toStringAsFixed(1);
                    _updateEstimatedValues();
                  });
                },
                // Pass colors
                backgroundColor: buttonBackgroundColor,
                iconColor: buttonIconColor,
                disabledBackgroundColor: disabledButtonColor,
                disabledIconColor: disabledIconColor,
              ),
              Expanded(
                child: Container(
                  height: 40.h,
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  decoration: BoxDecoration(
                    color: inputFillColor, // Use passed color
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: TextField(
                    controller: _quantityController,
                    textAlign: TextAlign.center,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^[0-9]*\.?[0-9]*'))
                    ],
                    style: TextStyle(
                      color: primaryTextColor, // Use passed color
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                    ),
                  ),
                ),
              ),
              _buildCircleButton(
                icon: Icons.add,
                onTap: () {
                  setState(() {
                    _quantity = (_quantity + 0.1).clamp(0.1, _maxVolume);
                    _quantityController.text = _quantity.toStringAsFixed(1);
                    _updateEstimatedValues();
                  });
                },
                // Pass colors
                backgroundColor: buttonBackgroundColor,
                iconColor: buttonIconColor,
                disabledBackgroundColor: disabledButtonColor,
                disabledIconColor: disabledIconColor,
              ),
              SizedBox(width: 12.w),
              _buildMultiplyButton(
                  'X2', buttonBackgroundColor, primaryTextColor, () {
                setState(() {
                  _quantity = (_quantity * 2).clamp(0.1, _maxVolume);
                  _quantityController.text = _quantity.toStringAsFixed(1);
                  _updateEstimatedValues();
                });
              }),
              SizedBox(width: 8.w),
              _buildMultiplyButton(
                  'X5', buttonBackgroundColor, primaryTextColor, () {
                setState(() {
                  _quantity = (_quantity * 5).clamp(0.1, _maxVolume);
                  _quantityController.text = _quantity.toStringAsFixed(1);
                  _updateEstimatedValues();
                });
              }),
            ],
          ),

          SizedBox(height: 16.h),

          // Take Profit field
          Row(
            children: [
              Checkbox(
                value: _useTakeProfit,
                onChanged: (value) {
                  setState(() {
                    _useTakeProfit = value ?? false;
                    if (!_useTakeProfit) {
                      _takeProfitPrice = null;
                      _takeProfitController.clear();
                    }
                  });
                },
                activeColor: checkboxColor, // Use passed color
                checkColor: Colors
                    .white, // Check color often contrasts with activeColor
                // Consider themeing side border if needed
                side: BorderSide(color: secondaryTextColor),
              ),
              Text(
                'Take Profit',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: primaryTextColor, // Use passed color
                ),
              ),
            ],
          ),
          Container(
            height: 40.h,
            decoration: BoxDecoration(
              color: inputFillColor, // Use passed color
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Row(
              children: [
                _buildCircleButton(
                  icon: Icons.add,
                  onTap: _useTakeProfit
                      ? () {
                          setState(() {
                            _takeProfitPrice = (_takeProfitPrice ??
                                    _currentSymbol?.price ??
                                    0) +
                                1;
                            _takeProfitController.text = _takeProfitPrice!
                                .toStringAsFixed(_currentSymbol?.digit ?? 2);
                          });
                        }
                      : null,
                  // Pass colors
                  backgroundColor: buttonBackgroundColor,
                  iconColor: buttonIconColor,
                  disabledBackgroundColor: disabledButtonColor,
                  disabledIconColor: disabledIconColor,
                  small: true,
                ),
                Expanded(
                  child: TextField(
                    controller: _takeProfitController,
                    enabled: _useTakeProfit,
                    textAlign: TextAlign.center,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^[0-9]*\.?[0-9]*'))
                    ],
                    style: TextStyle(
                      color: primaryTextColor, // Use passed color
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter take profit price',
                      hintStyle: TextStyle(
                        color: secondaryTextColor, // Use passed color
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
                _buildCircleButton(
                  icon: Icons.remove,
                  onTap: _useTakeProfit
                      ? () {
                          setState(() {
                            _takeProfitPrice = ((_takeProfitPrice ??
                                        _currentSymbol?.price ??
                                        0) -
                                    1)
                                .clamp(0, double.infinity);
                            _takeProfitController.text = _takeProfitPrice!
                                .toStringAsFixed(_currentSymbol?.digit ?? 2);
                          });
                        }
                      : null,
                  // Pass colors
                  backgroundColor: buttonBackgroundColor,
                  iconColor: buttonIconColor,
                  disabledBackgroundColor: disabledButtonColor,
                  disabledIconColor: disabledIconColor,
                  small: true,
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Stop Loss field
          Row(
            children: [
              Checkbox(
                value: _useStopLoss,
                onChanged: (value) {
                  setState(() {
                    _useStopLoss = value ?? false;
                    if (!_useStopLoss) {
                      _stopLossPrice = null;
                      _stopLossController.clear();
                    }
                  });
                },
                activeColor: checkboxColor, // Use passed color
                checkColor: Colors.white,
                // Consider themeing side border if needed
                side: BorderSide(color: secondaryTextColor),
              ),
              Text(
                'Stop Loss',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: primaryTextColor, // Use passed color
                ),
              ),
            ],
          ),
          Container(
            height: 40.h,
            decoration: BoxDecoration(
              color: inputFillColor, // Use passed color
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Row(
              children: [
                _buildCircleButton(
                  icon: Icons.add,
                  onTap: _useStopLoss
                      ? () {
                          setState(() {
                            _stopLossPrice =
                                (_stopLossPrice ?? _currentSymbol?.price ?? 0) +
                                    1;
                            _stopLossController.text = _stopLossPrice!
                                .toStringAsFixed(_currentSymbol?.digit ?? 2);
                          });
                        }
                      : null,
                  // Pass colors
                  backgroundColor: buttonBackgroundColor,
                  iconColor: buttonIconColor,
                  disabledBackgroundColor: disabledButtonColor,
                  disabledIconColor: disabledIconColor,
                  small: true,
                ),
                Expanded(
                  child: TextField(
                    controller: _stopLossController,
                    enabled: _useStopLoss,
                    textAlign: TextAlign.center,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^[0-9]*\.?[0-9]*'))
                    ],
                    style: TextStyle(
                      color: primaryTextColor, // Use passed color
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter stop loss price',
                      hintStyle: TextStyle(
                        color: secondaryTextColor, // Use passed color
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
                _buildCircleButton(
                  icon: Icons.remove,
                  onTap: _useStopLoss
                      ? () {
                          setState(() {
                            _stopLossPrice = ((_stopLossPrice ??
                                        _currentSymbol?.price ??
                                        0) -
                                    1)
                                .clamp(0, double.infinity);
                            _stopLossController.text = _stopLossPrice!
                                .toStringAsFixed(_currentSymbol?.digit ?? 2);
                          });
                        }
                      : null,
                  // Pass colors
                  backgroundColor: buttonBackgroundColor,
                  iconColor: buttonIconColor,
                  disabledBackgroundColor: disabledButtonColor,
                  disabledIconColor: disabledIconColor,
                  small: true,
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Volume and margin info
          // Pass secondary text color to info row
          _buildInfoRow('Maximum:', '${_maxVolume.toStringAsFixed(2)} Volume',
              primaryTextColor, secondaryTextColor),
          _buildInfoRow(
              'Volume ≈',
              '${_estimatedVolumeValue.toStringAsFixed(2)} USD',
              primaryTextColor,
              secondaryTextColor),
          _buildInfoRow(
              'Estimated margin:',
              '${_estimatedMargin.toStringAsFixed(2)} USD',
              primaryTextColor,
              secondaryTextColor),
          _buildInfoRow(
              'Available Balance:',
              '${_accountInfo?.availableBalance.toStringAsFixed(2) ?? '0.00'} USD',
              primaryTextColor,
              secondaryTextColor),

          SizedBox(height: 16.h),

          // Trading buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _isPlacingOrder ? null : () => _placeOrder(isBuy: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _upColor, // Keep specific color
                    disabledBackgroundColor: _upColor.withOpacity(0.5),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  child: _isPlacingOrder
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Buy',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _isPlacingOrder ? null : () => _placeOrder(isBuy: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _downColor, // Keep specific color
                    disabledBackgroundColor: _downColor.withOpacity(0.5),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  child: _isPlacingOrder
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Sell',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Pass colors as parameters
  Widget _buildCircleButton({
    required IconData icon,
    required Function()? onTap,
    required Color backgroundColor,
    required Color iconColor,
    required Color disabledBackgroundColor,
    required Color disabledIconColor,
    bool small = false,
  }) {
    double size = small ? 28.w : 40.w;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Use passed colors based on enabled/disabled (onTap != null)
          color: onTap != null ? backgroundColor : disabledBackgroundColor,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          // Use passed colors based on enabled/disabled (onTap != null)
          color: onTap != null ? iconColor : disabledIconColor,
          size: small ? 16.sp : 24.sp,
        ),
      ),
    );
  }

  // Pass colors as parameters
  Widget _buildMultiplyButton(
      String text, Color backgroundColor, Color textColor, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: backgroundColor, // Use passed color
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor, // Use passed color
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  // Pass colors as parameters
  Widget _buildInfoRow(String label, String value, Color primaryTextColor,
      Color secondaryTextColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: secondaryTextColor, // Use passed color
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: primaryTextColor, // Use passed color
            ),
          ),
        ],
      ),
    );
  }

  // Function to place the order
  Future<void> _placeOrder({required bool isBuy}) async {
    if (_currentSymbol == null || _isPlacingOrder) return;

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final result = await _tradeService.createOrder(
        symbolCode: _currentSymbol!.code,
        volume: _quantity,
        riseFall: isBuy ? 'RISE' : 'FALL',
        stopProfit: _useTakeProfit ? _takeProfitPrice : null,
        stopLoss: _useStopLoss ? _stopLossPrice : null,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Optionally, refresh position data or navigate away
      // Provider.of<PositionProvider>(context, listen: false).refreshData();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPlacingOrder = false;
      });
    }
  }

  String _getKlineTypeLabel(int klineType) {
    switch (klineType) {
      case 1:
        return 'M1';
      case 5:
        return 'M5';
      case 7:
        return 'H1';
      case 8:
        return 'D1';
      case 9:
        return 'W1';
      default:
        throw Exception('Unknown kline type');
    }
  }

  // Pass colors as parameters to the chart builders
  Widget _buildKChart(
      Color gridColor, Color labelColor, Color upColor, Color downColor) {
    if (_klineData.isEmpty) return SizedBox();

    // Sort data by time in ascending order
    _klineData.sort((a, b) => a.time.compareTo(b.time));

    // Find min and max values for Y axis scaling
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (var item in _klineData) {
      final double low = item.low;
      final double high = item.high;

      if (low < minY) minY = low;
      if (high > maxY) maxY = high;
    }

    // Add padding to min/max for better visualization
    final double padding = (maxY - minY) * 0.1;
    minY = (minY - padding).clamp(0, double.infinity);
    maxY = maxY + padding;

    // Create custom candlestick painter
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: CandlestickChart(
              data: _klineData,
              minY: minY,
              maxY: maxY,
              digit: _currentSymbol?.digit ?? 2,
              // Pass colors
              gridColor: gridColor,
              labelColor: labelColor,
              upColor: upColor,
              downColor: downColor,
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            flex: 3,
            child: VolumeChart(
              data: _klineData,
              // Pass colors
              gridColor: gridColor,
              labelColor: labelColor,
              upColor: upColor,
              downColor: downColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Candlestick Chart Widget
// Add color parameters
class CandlestickChart extends StatelessWidget {
  final List<KlineBean> data;
  final double minY;
  final double maxY;
  final int digit;
  final Color gridColor;
  final Color labelColor;
  final Color upColor;
  final Color downColor;

  const CandlestickChart({
    super.key,
    required this.data,
    required this.minY,
    required this.maxY,
    required this.digit,
    required this.gridColor,
    required this.labelColor,
    required this.upColor,
    required this.downColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: CandlestickPainter(
        data: data,
        minY: minY,
        maxY: maxY,
        digit: digit,
        // Pass colors to painter
        gridColor: gridColor,
        labelColor: labelColor,
        upColor: upColor,
        downColor: downColor,
      ),
    );
  }
}

// Candlestick Painter
// Add color parameters
class CandlestickPainter extends CustomPainter {
  final List<KlineBean> data;
  final double minY;
  final double maxY;
  final int digit;
  final Color gridColor;
  final Color labelColor;
  final Color upColor;
  final Color downColor;

  CandlestickPainter({
    required this.data,
    required this.minY,
    required this.maxY,
    required this.digit,
    required this.gridColor,
    required this.labelColor,
    required this.upColor,
    required this.downColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double candleWidth = size.width / (data.length * 2);
    final double scale = size.height / (maxY - minY);

    // Draw grid lines - Use passed color
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    // Horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final double y = size.height - ((maxY - minY) / 5 * i) * scale;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      // Draw price labels - Use passed color
      final double price = minY + ((maxY - minY) / 5 * i);
      final TextSpan textSpan = TextSpan(
        text: price.toStringAsFixed(digit),
        style: TextStyle(
          color: labelColor,
          fontSize: 10,
        ),
      );

      final TextPainter textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    // Vertical grid lines
    for (int i = 0; i <= data.length; i += data.length ~/ 5) {
      if (i >= data.length) continue;
      final double x = i * (candleWidth * 2) + candleWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);

      // Draw date labels - Use passed color
      if (i < data.length) {
        final item = data[i];
        final DateTime date =
            DateTime.fromMillisecondsSinceEpoch(item.time * 1000);

        final TextSpan textSpan = TextSpan(
          text: '${date.month}/${date.day}',
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
          ),
        );

        final TextPainter textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
            canvas,
            Offset(x - textPainter.width / 2,
                size.height - textPainter.height - 2));
      }
    }

    // Draw candlesticks
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final double open = item.open;
      final double close = item.close;
      final double high = item.high;
      final double low = item.low;

      final bool isUp = close >= open;

      final double x = i * (candleWidth * 2) + candleWidth;
      final double openY = size.height - (open - minY) * scale;
      final double closeY = size.height - (close - minY) * scale;
      final double highY = size.height - (high - minY) * scale;
      final double lowY = size.height - (low - minY) * scale;

      // Draw candle body - Use passed up/down colors
      final Paint candlePaint = Paint()
        ..color = isUp ? upColor : downColor
        ..style = isUp ? PaintingStyle.stroke : PaintingStyle.fill;

      if (isUp) {
        candlePaint.strokeWidth = 1;
      }

      final Rect candleRect = Rect.fromPoints(
        Offset(x - candleWidth / 2, closeY),
        Offset(x + candleWidth / 2, openY),
      );

      canvas.drawRect(candleRect, candlePaint);

      // Draw candle wick (high/low lines) - Use passed up/down colors
      final Paint wickPaint = Paint()
        ..color = isUp ? upColor : downColor
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(x, highY),
        Offset(x, isUp ? closeY : openY),
        wickPaint,
      );

      canvas.drawLine(
        Offset(x, isUp ? openY : closeY),
        Offset(x, lowY),
        wickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Volume Chart Widget
// Add color parameters
class VolumeChart extends StatelessWidget {
  final List<KlineBean> data;
  final Color gridColor;
  final Color labelColor;
  final Color upColor;
  final Color downColor;

  const VolumeChart({
    super.key,
    required this.data,
    required this.gridColor,
    required this.labelColor,
    required this.upColor,
    required this.downColor,
  });

  @override
  Widget build(BuildContext context) {
    // Find max volume for scaling
    double maxVolume = 0;
    for (var item in data) {
      final double volume = item.volume;
      if (volume > maxVolume) maxVolume = volume;
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxVolume / 3,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              // Use passed color
              color: gridColor,
              strokeWidth: 0.5,
            );
          },
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();

                String volumeText = '';
                if (value >= 1000000) {
                  volumeText = '${(value / 1000000).toStringAsFixed(1)}M';
                } else if (value >= 1000) {
                  volumeText = '${(value / 1000).toStringAsFixed(1)}K';
                } else {
                  volumeText = value.toStringAsFixed(0);
                }

                return Text(
                  volumeText,
                  style: TextStyle(
                    // Use passed color
                    color: labelColor,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          data.length,
          (index) {
            final item = data[index];
            final double open = item.open;
            final double close = item.close;
            final double volume = item.volume;
            final bool isUp = close >= open;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: volume,
                  width: 5,
                  // Use passed up/down colors
                  color: isUp ? upColor : downColor,
                  borderRadius: BorderRadius.zero,
                ),
              ],
            );
          },
        ),
        maxY: maxVolume * 1.1,
        minY: 0,
      ),
    );
  }
}
