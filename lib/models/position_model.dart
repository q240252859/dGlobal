import 'dart:convert';

class PositionModel {
  final String symbol;
  final String symbolCn;
  final double entryPrice;
  final double currentPrice;
  final String orderNumber;
  final String timestamp;
  final String openTime;
  final double profitLoss;
  final bool isBuy;
  final double volume;
  final double? takeProfit;
  final double? stopLoss;
  final double? handlingFee;

  PositionModel({
    required this.symbol,
    required this.symbolCn,
    required this.entryPrice,
    required this.currentPrice,
    required this.orderNumber,
    required this.timestamp,
    required this.openTime,
    required this.profitLoss,
    required this.isBuy,
    required this.volume,
    this.takeProfit,
    this.stopLoss,
    this.handlingFee,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    try {
      // Safely handle any data type conversion
      String getStringValue(dynamic value) => value?.toString() ?? '';
      double getDoubleValue(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString()) ?? 0.0;
      }

      // Optional double value (returns null if value is null or invalid)
      double? getOptionalDoubleValue(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString());
      }

      return PositionModel(
        symbol: getStringValue(json['code']),
        symbolCn: getStringValue(json['symbol_cn']),
        entryPrice: getDoubleValue(json['open_price']),
        currentPrice: getDoubleValue(json['close_price']),
        orderNumber: getStringValue(json['order_number']),
        timestamp: getStringValue(json['created_at']),
        openTime: getStringValue(json['open_time']),
        profitLoss: getDoubleValue(json['profit']),
        isBuy: json['rise_fall'] == 'RISE',
        volume: getDoubleValue(json['volume']),
        takeProfit: getOptionalDoubleValue(json[
            'stop_profit_price']), // Assuming API key is 'stop_profit_price'
        stopLoss: getOptionalDoubleValue(
            json['stop_loss_price']), // Assuming API key is 'stop_loss_price'
        handlingFee: getOptionalDoubleValue(
            json['handling_fee']), // Assuming API key is 'handling_fee'
      );
    } catch (e) {
      print('Error parsing PositionModel: $e');
      print('Json data: $json');
      rethrow;
    }
  }
}

class HistoryPositionModel {
  final String symbol;
  final String symbolCn;
  final double entryPrice;
  final double exitPrice;
  final String orderNumber;
  final String timestamp;
  final String openTime;
  final double profitLoss;
  final bool isBuy;
  final double volume;

  HistoryPositionModel({
    required this.symbol,
    required this.symbolCn,
    required this.entryPrice,
    required this.exitPrice,
    required this.orderNumber,
    required this.timestamp,
    required this.openTime,
    required this.profitLoss,
    required this.isBuy,
    required this.volume,
  });

  factory HistoryPositionModel.fromJson(Map<String, dynamic> json) {
    try {
      // Safely handle any data type conversion
      String getStringValue(dynamic value) => value?.toString() ?? '';
      double getDoubleValue(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString()) ?? 0.0;
      }

      return HistoryPositionModel(
        symbol: getStringValue(json['code']),
        symbolCn: getStringValue(json['symbol_cn']),
        entryPrice: getDoubleValue(json['open_price']),
        exitPrice: getDoubleValue(json['close_price']),
        orderNumber: getStringValue(json['order_number']),
        timestamp: getStringValue(json['created_at']),
        openTime: getStringValue(json['open_time']),
        profitLoss: getDoubleValue(json['profit']),
        isBuy: json['rise_fall'] == 'RISE',
        volume: getDoubleValue(json['volume']),
      );
    } catch (e) {
      print('Error parsing HistoryPositionModel: $e');
      print('Json data: $json');
      rethrow;
    }
  }
}

class HistoryStatsModel {
  final double totalIncome;
  final double handlingFee;
  final double accountBalance;

  HistoryStatsModel({
    required this.totalIncome,
    required this.handlingFee,
    required this.accountBalance,
  });

  factory HistoryStatsModel.fromJson(Map<String, dynamic> json) {
    return HistoryStatsModel(
      totalIncome:
          double.tryParse(json['total_income']?.toString() ?? '0') ?? 0.0,
      handlingFee:
          double.tryParse(json['handling_fee']?.toString() ?? '0') ?? 0.0,
      accountBalance:
          double.tryParse(json['account_balance']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class MemberInfoModel {
  final double riskRatio;
  final double balance;
  final double totalProfit;
  final double totalFee;
  final String username;

  MemberInfoModel({
    required this.riskRatio,
    required this.balance,
    required this.totalProfit,
    required this.totalFee,
    required this.username,
  });

  factory MemberInfoModel.fromJson(Map<String, dynamic> json) {
    try {
      final data = json['data'] ?? {};

      // Helper function for safe conversion
      double getDoubleValue(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString()) ?? 0.0;
      }

      return MemberInfoModel(
        // risk_rate is the risk ratio in the API
        riskRatio: getDoubleValue(data['risk_rate']),
        // money_zong is the total balance
        balance: getDoubleValue(data['money_zong']),
        // money_yes is the profit (yesterday's balance)
        totalProfit: getDoubleValue(data['money_yes']),
        // deposit is used as fee (available deposit)
        totalFee: getDoubleValue(data['deposit']),
        // Get username if available
        username: data['username']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing MemberInfoModel: $e');
      print('Json data: $json');
      rethrow;
    }
  }
}

class PositionResponse {
  final List<PositionModel> positions;

  PositionResponse({required this.positions});

  factory PositionResponse.fromJson(Map<String, dynamic> json) {
    try {
      final List<dynamic> positionsList = json['data'] ?? [];
      final positions =
          positionsList.map((item) => PositionModel.fromJson(item)).toList();
      return PositionResponse(positions: positions);
    } catch (e) {
      print('Error parsing PositionResponse: $e');
      print('Json data: ${json['data']}');
      rethrow;
    }
  }
}

class HistoryCountsResponse {
  final int totalCount;
  final int profitCount;
  final int lossCount;

  HistoryCountsResponse({
    required this.totalCount,
    required this.profitCount,
    required this.lossCount,
  });

  factory HistoryCountsResponse.fromJson(Map<String, dynamic> json) {
    try {
      // The data field can be either an array or an object with count statistics
      final data = json['data'];

      if (data is List) {
        // If it's a list of trade records, count them
        print('HistoryCounts: data is a List with ${data.length} items');
        int profitCount = 0;
        int lossCount = 0;

        for (var item in data) {
          double profit = 0.0;
          if (item['profit'] != null) {
            profit = double.tryParse(item['profit'].toString()) ?? 0.0;
          }

          if (profit >= 0) {
            profitCount++;
          } else {
            lossCount++;
          }
        }

        return HistoryCountsResponse(
          totalCount: data.length,
          profitCount: profitCount,
          lossCount: lossCount,
        );
      } else if (data is Map) {
        // Helper function for safe conversion
        int getIntValue(dynamic value) {
          if (value == null) return 0;
          if (value is int) return value;
          if (value is double) return value.toInt();
          return int.tryParse(value.toString()) ?? 0;
        }

        return HistoryCountsResponse(
          totalCount: getIntValue(data['total']),
          profitCount: getIntValue(data['profit']),
          lossCount: getIntValue(data['loss']),
        );
      } else {
        // Fallback if data is neither list nor map
        print('HistoryCounts: unexpected data type: ${data?.runtimeType}');
        return HistoryCountsResponse(
          totalCount: 0,
          profitCount: 0,
          lossCount: 0,
        );
      }
    } catch (e) {
      print('Error parsing HistoryCountsResponse: $e');
      print('Json data: $json');
      return HistoryCountsResponse(
        totalCount: 0,
        profitCount: 0,
        lossCount: 0,
      );
    }
  }
}
