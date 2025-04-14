import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // Import for input formatters
import '../providers/position_provider.dart';
import '../providers/theme_provider.dart';
import '../models/position_model.dart';
import '../utils/pull_to_refresh.dart';
import '../services/trade_service.dart'; // Import TradeService

class PositionScreen extends StatefulWidget {
  const PositionScreen({Key? key}) : super(key: key);

  @override
  _PositionScreenState createState() => _PositionScreenState();
}

class _PositionScreenState extends State<PositionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Position', 'History'];
  final ScrollController _currentPositionsScrollController = ScrollController();
  final ScrollController _historyScrollController = ScrollController();
  bool _historyLoadingMore = false;
  int _historyPage = 1;
  int _historyPageSize = 20;

  final TradeService _tradeService =
      TradeService(); // Add TradeService instance

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Load position data from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    // Add scroll listener for history pagination
    _historyScrollController.addListener(_onHistoryScroll);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _currentPositionsScrollController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  // Handle tab change
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;
    setState(() {});
  }

  // Initial data loading
  Future<void> _loadData() async {
    final positionProvider =
        Provider.of<PositionProvider>(context, listen: false);
    await positionProvider.loadAllData();
  }

  // Refresh data
  Future<bool> _refreshData() async {
    final positionProvider =
        Provider.of<PositionProvider>(context, listen: false);
    await positionProvider.refreshData();
    setState(() {
      _historyPage = 1;
      _historyLoadingMore = false;
    });
    return true;
  }

  // Load more history data
  Future<void> _loadMoreHistory() async {
    if (_historyLoadingMore) return;

    setState(() {
      _historyLoadingMore = true;
      _historyPage++;
    });

    final positionProvider =
        Provider.of<PositionProvider>(context, listen: false);
    await positionProvider.loadHistoryPositions(
      page: _historyPage,
      pageSize: _historyPageSize,
      reset: false,
    );

    setState(() {
      _historyLoadingMore = false;
    });
  }

  // Handle history scroll for pagination
  void _onHistoryScroll() {
    if (_historyScrollController.position.pixels >=
            _historyScrollController.position.maxScrollExtent - 200 &&
        !_historyLoadingMore) {
      _loadMoreHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Position',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs
              .map((tab) => Tab(
                    text: tab,
                    height: 40.h,
                  ))
              .toList(),
          labelColor: isDarkMode ? Colors.black : Colors.white,
          unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey,
          indicator: BoxDecoration(
            color: isDarkMode ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(30.r),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        ),
      ),
      body: Consumer<PositionProvider>(
        builder: (context, positionProvider, child) {
          return PullToRefreshHelper.wrapWithPullToRefresh(
            onRefresh: _refreshData,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCurrentPositionsTab(positionProvider, isDarkMode),
                _buildHistoryPositionsTab(positionProvider, isDarkMode),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentPositionsTab(PositionProvider provider, bool isDarkMode) {
    final positions = provider.currentPositions;
    final memberInfo = provider.memberInfo;
    final isLoading = provider.isLoadingPositions || provider.isLoadingInfo;
    final error = provider.error;

    return CustomScrollView(
      controller: _currentPositionsScrollController,
      slivers: [
        PullToRefreshHelper.buildPullToRefreshIndicator(),
        // Risk ratio card
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Risk Ratio:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '${memberInfo?.riskRatio.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Error message
        if (error != null)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'Error: $error',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),

        // Loading indicator
        if (isLoading && positions.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: CircularProgressIndicator(),
              ),
            ),
          ),

        // Position list
        if (!isLoading || positions.isNotEmpty)
          positions.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 32.h),
                      child: Text(
                        'No positions',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final position = positions[index];
                      final isProfit = position.profitLoss >= 0;

                      return InkWell(
                        onTap: () =>
                            _showPositionDetailsDialog(context, position),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                position.symbolCn,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Text(
                                    '${position.entryPrice.toStringAsFixed(2)} → ${position.currentPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.black87,
                                    ),
                                  ),
                                  Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: position.isBuy
                                          ? Colors.red
                                          : Colors.blue,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      '${position.isBuy ? 'Buy' : 'Sell'} ${position.volume} Volume',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Order No.: ${position.orderNumber}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: isDarkMode
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                ),
                              ),
                              Text(
                                ' ${position.openTime}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: isDarkMode
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  (isProfit ? '+' : '') +
                                      position.profitLoss.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isProfit ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                              Divider(
                                height: 24.h,
                                color: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[300],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: positions.length,
                  ),
                ),
      ],
    );
  }

  // Function to show the position details dialog
  void _showPositionDetailsDialog(
      BuildContext context, PositionModel position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          // Padding to avoid keyboard overlap
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _PositionDetailsDialog(
            position: position,
            tradeService: _tradeService,
          ),
        );
      },
    ).then((_) {
      // Refresh data after dialog is dismissed (optional, depends on API behavior)
      Provider.of<PositionProvider>(context, listen: false).refreshData();
    });
  }

  Widget _buildHistoryPositionsTab(PositionProvider provider, bool isDarkMode) {
    final positions = provider.historyPositions;
    final memberInfo = provider.memberInfo;
    final isLoading = provider.isLoadingHistory || provider.isLoadingInfo;
    final error = provider.error;

    return CustomScrollView(
      controller: _historyScrollController,
      slivers: [
        PullToRefreshHelper.buildPullToRefreshIndicator(),
        // Summary card
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total income',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      memberInfo != null
                          ? memberInfo.totalProfit.toStringAsFixed(2)
                          : '0.00',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Handling fee',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      memberInfo != null
                          ? memberInfo.totalFee.toStringAsFixed(2)
                          : '0.00',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Account balance',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      memberInfo != null
                          ? memberInfo.balance.toStringAsFixed(2)
                          : '0.00',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Error message
        if (error != null)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'Error: $error',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),

        // Loading indicator
        if (isLoading && positions.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: CircularProgressIndicator(),
              ),
            ),
          ),

        // History list
        if (!isLoading || positions.isNotEmpty)
          positions.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 32.h),
                      child: Text(
                        'No history',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= positions.length) {
                        return Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: _historyLoadingMore
                                ? CircularProgressIndicator()
                                : SizedBox(),
                          ),
                        );
                      }

                      final position = positions[index];
                      final isProfit = position.profitLoss >= 0;

                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              position.symbolCn,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Text(
                                  '${position.entryPrice.toStringAsFixed(2)} → ${position.exitPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.black87,
                                  ),
                                ),
                                Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: position.isBuy
                                        ? Colors.red
                                        : Colors.blue,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    '${position.isBuy ? 'Buy' : 'Sell'} ${position.volume} Volume',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Order No.: ${position.orderNumber}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              ' ${position.openTime}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                (isProfit ? '+' : '') +
                                    position.profitLoss.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isProfit ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                            Divider(
                              height: 24.h,
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount:
                        positions.length + 1, // +1 for the loading indicator
                  ),
                ),
      ],
    );
  }
}

// Stateful Dialog for Position Details and Actions
class _PositionDetailsDialog extends StatefulWidget {
  final PositionModel position;
  final TradeService tradeService;

  const _PositionDetailsDialog({
    required this.position,
    required this.tradeService,
  });

  @override
  _PositionDetailsDialogState createState() => _PositionDetailsDialogState();
}

class _PositionDetailsDialogState extends State<_PositionDetailsDialog> {
  late TextEditingController _takeProfitController;
  late TextEditingController _stopLossController;
  bool _isClosing = false;
  bool _isModifying = false;

  @override
  void initState() {
    super.initState();
    _takeProfitController = TextEditingController(
      text: widget.position.takeProfit?.toString() ?? '',
    );
    _stopLossController = TextEditingController(
      text: widget.position.stopLoss?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _takeProfitController.dispose();
    _stopLossController.dispose();
    super.dispose();
  }

  Future<void> _handleClosePosition() async {
    setState(() {
      _isClosing = true;
    });

    try {
      final result = await widget.tradeService.closeOrder(
        orderId: widget.position.orderNumber,
        volume: widget.position.volume, // Close full volume
      );
      Navigator.pop(context); // Close dialog on success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Position closed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to close position: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClosing = false;
        });
      }
    }
  }

  Future<void> _handleSetTpSl() async {
    setState(() {
      _isModifying = true;
    });

    final double? tp = double.tryParse(_takeProfitController.text);
    final double? sl = double.tryParse(_stopLossController.text);

    try {
      final result = await widget.tradeService.modifyOrder(
        orderId: widget.position.orderNumber,
        stopProfit: tp,
        stopLoss: sl,
      );
      Navigator.pop(context); // Close dialog on success (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'TP/SL updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update TP/SL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isModifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final position = widget.position;
    final isProfit = position.profitLoss >= 0;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close,
                    color: isDarkMode ? Colors.white : Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Symbol and Price
          Text(
            position.symbolCn,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${position.entryPrice.toStringAsFixed(2)} → ${position.currentPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: position.isBuy ? Colors.red : Colors.blue,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '${position.isBuy ? 'Buy' : 'Sell'} ${position.volume} Volume',
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Order Details
          _buildDetailRow('Order No.:', position.orderNumber, isDarkMode),
          _buildDetailRow('Take Profit:',
              position.takeProfit?.toStringAsFixed(2) ?? '0.00', isDarkMode),
          _buildDetailRow('Stop Loss:',
              position.stopLoss?.toStringAsFixed(2) ?? '0.00', isDarkMode),
          _buildDetailRow('Handling fee:',
              position.handlingFee?.toStringAsFixed(2) ?? '0.00', isDarkMode),
          _buildDetailRow('Opening Time:', position.openTime, isDarkMode),

          SizedBox(height: 16.h),

          // Profit/Loss Display
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(isProfit ? '+' : '')}${position.profitLoss.toStringAsFixed(2)}%', // Assuming percentage P/L
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isProfit ? Colors.green : Colors.red,
              ),
            ),
          ),
          Divider(
              height: 24.h,
              color: isDarkMode ? Colors.grey[800] : Colors.grey[300]),

          // Take Profit Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _takeProfitController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^[0-9]*\.?[0-9]*'))
                  ],
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14.sp),
                  decoration: InputDecoration(
                      labelText: 'Take profit',
                      labelStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14.sp),
                      hintText: 'Please enter take profit',
                      hintStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          fontSize: 12.sp),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero),
                ),
              ),
              SizedBox(width: 10.w),
              ElevatedButton(
                onPressed: _isModifying ? null : _handleSetTpSl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.grey[700] : Colors.black,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                child: _isModifying
                    ? SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Set Take Profit',
                        style: TextStyle(fontSize: 12.sp, color: Colors.white)),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Stop Loss Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stopLossController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^[0-9]*\.?[0-9]*'))
                  ],
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14.sp),
                  decoration: InputDecoration(
                      labelText: 'Stop loss',
                      labelStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14.sp),
                      hintText: 'Please enter stop loss',
                      hintStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          fontSize: 12.sp),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero),
                ),
              ),
              SizedBox(width: 10.w),
              // Keep the button area consistent, even if button isn't shown for SL
              Container(width: 120.w) // Placeholder to align with TP button
            ],
          ),

          SizedBox(height: 20.h),

          // Close Position Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isClosing ? null : _handleClosePosition,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.grey[700] : Colors.black,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: _isClosing
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      'Close Position',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
