import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/position_model.dart';
import '../services/position_service.dart';

class PositionProvider with ChangeNotifier {
  final PositionService _positionService = PositionService();
  Timer? _dataPollingTimer;

  bool _isLoadingPositions = false;
  bool _isLoadingHistory = false;
  bool _isLoadingInfo = false;
  String? _error;

  List<PositionModel> _currentPositions = [];
  List<HistoryPositionModel> _historyPositions = [];
  MemberInfoModel? _memberInfo;
  HistoryCountsResponse? _historyCounts;

  // Getters
  bool get isLoadingPositions => _isLoadingPositions;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingInfo => _isLoadingInfo;
  String? get error => _error;
  List<PositionModel> get currentPositions => _currentPositions;
  List<HistoryPositionModel> get historyPositions => _historyPositions;
  MemberInfoModel? get memberInfo => _memberInfo;
  HistoryCountsResponse? get historyCounts => _historyCounts;

  // Constructor - Start data polling
  PositionProvider() {
    startDataPolling();
  }

  // Start polling timer
  void startDataPolling() {
    stopDataPolling(); // Ensure no duplicate timers

    print('Starting position data polling...');
    _dataPollingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pollPositionData();
    });
  }

  // Stop polling timer
  void stopDataPolling() {
    if (_dataPollingTimer != null) {
      _dataPollingTimer!.cancel();
      _dataPollingTimer = null;
      print('Stopped position data polling');
    }
  }

  // Poll position and account data
  Future<void> _pollPositionData() async {
    try {
      // Don't show loading indicators during polling to avoid UI flicker
      await _loadCurrentPositionsQuietly();
      await _loadMemberInfoQuietly();

      // 只有在Position页面是当前活动页面时才更新历史数据
      // 在实际应用中可以通过检查当前页面来决定是否更新
      if (_historyPositions.isNotEmpty) {
        await _loadHistoryPositionsQuietly();
      }
    } catch (e) {
      print('Error during position data polling: $e');
      // Don't set error during polling to avoid UI disruption
    }
  }

  // Loading state setters
  void setLoadingPositions(bool loading) {
    _isLoadingPositions = loading;
    notifyListeners();
  }

  void setLoadingHistory(bool loading) {
    _isLoadingHistory = loading;
    notifyListeners();
  }

  void setLoadingInfo(bool loading) {
    _isLoadingInfo = loading;
    notifyListeners();
  }

  // Error setter
  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  // Quietly load positions without UI indicators
  Future<void> _loadCurrentPositionsQuietly() async {
    try {
      final response = await _positionService.getCurrentPositions();
      if (!listEquals(_currentPositions, response.positions)) {
        _currentPositions = response.positions;
        notifyListeners();
        print('Position data updated: ${_currentPositions.length} positions');
      }
    } catch (e) {
      print('Silent polling error (positions): $e');
    }
  }

  // Quietly load member info without UI indicators
  Future<void> _loadMemberInfoQuietly() async {
    try {
      final info = await _positionService.getMemberInfo();
      if (_memberInfo == null ||
          _memberInfo!.balance != info.balance ||
          _memberInfo!.riskRatio != info.riskRatio) {
        _memberInfo = info;
        notifyListeners();
        print(
            'Account data updated: Balance: ${_memberInfo?.balance}, Risk: ${_memberInfo?.riskRatio}');
      }
    } catch (e) {
      print('Silent polling error (member info): $e');
    }
  }

  // Quietly load history without UI indicators
  Future<void> _loadHistoryPositionsQuietly() async {
    try {
      // 只获取第一页历史数据以保持更新
      final positions =
          await _positionService.getHistoryPositions(page: 1, pageSize: 20);

      // 检查历史数据是否有变化
      bool hasChanged = positions.length != _historyPositions.length;

      if (!hasChanged && positions.isNotEmpty) {
        // 检查第一个记录是否有变化
        hasChanged =
            positions[0].orderNumber != _historyPositions[0].orderNumber;
      }

      if (hasChanged) {
        _historyPositions = positions;
        notifyListeners();
        print('History data updated: ${_historyPositions.length} records');
      }

      // 同时更新历史计数统计
      final counts = await _positionService.getHistoryCounts();
      if (_historyCounts == null ||
          _historyCounts!.totalCount != counts.totalCount ||
          _historyCounts!.profitCount != counts.profitCount) {
        _historyCounts = counts;
        notifyListeners();
        print(
            'History counts updated: Total: ${counts.totalCount}, Profit: ${counts.profitCount}, Loss: ${counts.lossCount}');
      }
    } catch (e) {
      print('Silent polling error (history positions): $e');
    }
  }

  // Load current positions
  Future<void> loadCurrentPositions() async {
    setLoadingPositions(true);
    setError(null);

    try {
      final response = await _positionService.getCurrentPositions();
      _currentPositions = response.positions;
      setLoadingPositions(false);
    } catch (e) {
      setError(e.toString());
      setLoadingPositions(false);
    }
  }

  // Load member info
  Future<void> loadMemberInfo() async {
    setLoadingInfo(true);
    setError(null);

    try {
      final info = await _positionService.getMemberInfo();
      _memberInfo = info;
      setLoadingInfo(false);
    } catch (e) {
      setError(e.toString());
      setLoadingInfo(false);
    }
  }

  // Load history counts
  Future<void> loadHistoryCounts() async {
    setLoadingHistory(true);
    setError(null);

    try {
      final counts = await _positionService.getHistoryCounts();
      _historyCounts = counts;
      setLoadingHistory(false);
    } catch (e) {
      setError(e.toString());
      setLoadingHistory(false);
    }
  }

  // 使用优化后的分页加载历史数据
  Future<void> loadHistoryPositions(
      {int page = 1, int pageSize = 20, bool reset = false}) async {
    setLoadingHistory(true);
    setError(null);

    try {
      final positions = await _positionService.getHistoryPositions(
          page: page, pageSize: pageSize);

      if (reset) {
        _historyPositions = positions;
      } else {
        // 检查是否有重复数据
        final existingOrderNumbers =
            _historyPositions.map((p) => p.orderNumber).toSet();
        final newPositions = positions
            .where((p) => !existingOrderNumbers.contains(p.orderNumber))
            .toList();

        if (newPositions.isNotEmpty) {
          _historyPositions.addAll(newPositions);
          print('Added ${newPositions.length} new history positions');
        } else {
          print('No new history positions to add');
        }
      }

      setLoadingHistory(false);
    } catch (e) {
      setError(e.toString());
      setLoadingHistory(false);
    }
  }

  // Load all data
  Future<void> loadAllData() async {
    await loadCurrentPositions();
    await loadMemberInfo();
    await loadHistoryCounts();
    await loadHistoryPositions(reset: true);
  }

  // Refresh all data
  Future<void> refreshData() async {
    setError(null);
    await loadAllData();
  }

  // Clear all data
  void clear() {
    stopDataPolling();
    _currentPositions = [];
    _historyPositions = [];
    _memberInfo = null;
    _historyCounts = null;
    _error = null;
    _isLoadingPositions = false;
    _isLoadingHistory = false;
    _isLoadingInfo = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopDataPolling();
    super.dispose();
  }
}
