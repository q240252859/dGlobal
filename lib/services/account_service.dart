import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AccountService {
  static const String baseUrl = 'https://www.global-rlspo.top/api';
  final AuthService _authService = AuthService();

  // 获取账户信息
  Future<AccountInfoModel> getAccountInfo() async {
    try {
      final token = await _authService.getToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // 构建URL，遵循prd.mp规范
      final uri = Uri.parse(
          '$baseUrl/addons/tf-futures/member/my-info?access-token=${token ?? ''}&_=$timestamp');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200) {
          return AccountInfoModel.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to load account info');
        }
      } else {
        throw Exception('Failed to load account info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load account info: $e');
    }
  }
}

// 账户信息模型
class AccountInfoModel {
  final double balance;
  final double riskRatio;
  final double availableBalance;
  final double yesterdayBalance;
  final String username;
  final int userId;

  AccountInfoModel({
    required this.balance,
    required this.riskRatio,
    required this.availableBalance,
    required this.yesterdayBalance,
    required this.username,
    required this.userId,
  });

  factory AccountInfoModel.fromJson(Map<String, dynamic> json) {
    try {
      final data = json['data'] ?? {};

      // Helper function for safe conversion
      double getDoubleValue(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString()) ?? 0.0;
      }

      int getIntValue(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        return int.tryParse(value.toString()) ?? 0;
      }

      return AccountInfoModel(
        // money_zong is the total account balance
        balance: getDoubleValue(data['money_zong']),
        // risk_rate is the risk ratio in percentage
        riskRatio: getDoubleValue(data['risk_rate']),
        // deposit is the available balance for trading
        availableBalance: getDoubleValue(data['deposit']),
        // money_yes is yesterday's balance
        yesterdayBalance: getDoubleValue(data['money_yes']),
        // Username if available
        username: data['username']?.toString() ?? '',
        // User ID if available
        userId: getIntValue(data['id']),
      );
    } catch (e) {
      print('Error parsing AccountInfoModel: $e');
      print('Json data: $json');
      rethrow;
    }
  }
}
