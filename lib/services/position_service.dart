import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/position_model.dart';
import 'auth_service.dart';

class PositionService {
  static const String _baseUrl = 'https://www.global-rlspo.top/api';
  final AuthService _authService = AuthService();
  final Dio _dio = Dio();

  // 获取当前持仓
  Future<PositionResponse> getCurrentPositions() async {
    try {
      final token = await _authService.getToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // 遵循prd.mp规范，使用GET请求
      final response = await _dio.get(
        '$_baseUrl/addons/tf-futures/order/list',
        queryParameters: {
          "state": "hold",
          "access-token": token ?? '',
          "_": timestamp
        },
      );

      if (response.statusCode == 200) {
        // Correctly handle Dio response data - no need to decode again
        final data = response.data;

        if (data['code'] == 200) {
          return PositionResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to load positions');
        }
      } else {
        throw Exception('Failed to load positions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load positions: $e');
    }
  }

  // 获取账户信息
  Future<MemberInfoModel> getMemberInfo() async {
    try {
      final token = await _authService.getToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // 遵循prd.mp规范，使用GET请求
      final response = await _dio.get(
        '$_baseUrl/addons/tf-futures/member/my-info',
        queryParameters: {"access-token": token ?? '', "_": timestamp},
      );

      if (response.statusCode == 200) {
        // Correctly handle Dio response data
        final data = response.data;

        if (data['code'] == 200) {
          return MemberInfoModel.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to load member info');
        }
      } else {
        throw Exception('Failed to load member info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load member info: $e');
    }
  }

  // 获取历史订单统计 - 使用与getHistoryPositions相同的接口
  Future<HistoryCountsResponse> getHistoryCounts() async {
    try {
      final token = await _authService.getToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      print('Fetching history counts...');

      // 使用同一个接口获取历史订单数据，只是不分页
      final response = await _dio.get(
        '$_baseUrl/addons/tf-futures/order/counts',
        queryParameters: {
          "type": "1",
          "access-token": token ?? '',
          "_": timestamp
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 200) {
          // 封装HistoryCountsResponse传递给模型处理
          return HistoryCountsResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to load history counts');
        }
      } else {
        throw Exception(
            'Failed to load history counts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting history counts: $e');
      throw Exception('Failed to load history counts: $e');
    }
  }

  // 获取历史订单数据 - 从完整历史记录中分页获取
  Future<List<HistoryPositionModel>> getHistoryPositions(
      {int page = 1, int pageSize = 20}) async {
    try {
      final token = await _authService.getToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      print('Fetching history positions: page=$page, pageSize=$pageSize');

      // 从完整的历史订单列表中获取数据
      final response = await _dio.get(
        '$_baseUrl/addons/tf-futures/order/counts',
        queryParameters: {
          "type": "1",
          "access-token": token ?? '',
          "_": timestamp
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        print('History API response: ${response.statusCode}');
        final data = response.data;

        if (data['code'] == 200) {
          try {
            final List<dynamic> allHistory = data['data'] ?? [];
            print('Total history records: ${allHistory.length}');

            // 手动分页
            final int startIndex = (page - 1) * pageSize;
            final int endIndex = startIndex + pageSize;

            // 确保索引不超出范围
            final int validStartIndex =
                startIndex < allHistory.length ? startIndex : allHistory.length;
            final int validEndIndex =
                endIndex < allHistory.length ? endIndex : allHistory.length;

            // 提取当前页的数据
            final List<dynamic> pageItems = validStartIndex < validEndIndex
                ? allHistory.sublist(validStartIndex, validEndIndex)
                : [];

            print(
                'Showing history records ${validStartIndex + 1}-${validEndIndex} of ${allHistory.length}');

            return pageItems
                .map((item) => HistoryPositionModel.fromJson(item))
                .toList();
          } catch (parseError) {
            print('Data parsing error: $parseError');
            print('Response data structure: ${data['data'].runtimeType}');
            if (data['data'] != null) {
              print(
                  'First item sample: ${data['data'] is List && data['data'].isNotEmpty ? data['data'][0] : 'Empty or not a list'}');
            }
            rethrow;
          }
        } else {
          print('History API error: ${data['code']} - ${data['message']}');
          throw Exception(
              data['message'] ?? 'Failed to load history positions');
        }
      } else {
        throw Exception(
            'Failed to load history positions: ${response.statusCode}');
      }
    } catch (e) {
      print('History positions error: $e');
      throw Exception('Failed to load history positions: $e');
    }
  }
}
