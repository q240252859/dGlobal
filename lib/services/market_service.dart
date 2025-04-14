import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_model.dart';
import '../models/kline_bean.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarketService {
  static const String _baseUrl = 'https://www.global-rlspo.top/api';
  final AuthService _authService = AuthService();

  // 获取所有市场数据
  Future<List<MarketModel>> getMarkets() async {
    try {
      final response = await getMarketResponse();
      final List<MarketModel> allMarkets = [];

      // 从所有分类中提取市场数据
      for (final category in response.categories) {
        allMarkets.addAll(category.symbols);
      }

      return allMarkets;
    } catch (e) {
      throw Exception('Failed to load markets: $e');
    }
  }

  // 获取市场分类和数据
  Future<MarketResponse> getMarketResponse() async {
    try {
      final token = await _authService.getToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // 遵循prd.mp中指定的URL格式，确保包含access-token和_参数
      final uri = Uri.parse(
          '$_baseUrl/addons/tf-futures/symbol/cate-list?access-token=${token ?? ''}&_=$timestamp');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200) {
          return MarketResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to load market data');
        }
      } else {
        throw Exception('Failed to load market data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load market data: $e');
    }
  }

  // 获取K线数据
  Future<List<KlineBean>> getKlineData({
    required String code,
    required int klineType,
  }) async {
    try {
      final token = await _authService.getToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      print('Fetching K-line data for $code with type $klineType');

      // 遵循prd.mp规范，使用GET请求
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/kline/history?access-token=${token ?? ''}&code=$code&kline_type=$klineType&_=$timestamp'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('K-line data fetched successfully for $code');

        final responseData = data['data'];

        // 处理API返回List类型的情况
        if (responseData is List) {
          return responseData
              .map((item) => item is Map
                  ? KlineBean.fromJson(Map<String, dynamic>.from(item))
                  : null)
              .where((item) => item != null)
              .cast<KlineBean>()
              .toList();
        }
        // 处理API返回Map类型的情况
        else if (responseData is Map) {
          final mapData = Map<String, dynamic>.from(responseData);
          // 如果是Map，可能需要转换成List，取决于具体接口
          return [KlineBean.fromJson(mapData)];
        }

        // 返回空列表作为默认值
        return [];
      } else {
        throw Exception('Failed to load K-line data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching K-line data: $e');
      throw Exception('Failed to load K-line data: $e');
    }
  }

  // POST请求示例方法，可用于其他需要POST的API
  Future<Map<String, dynamic>> postRequest(
      String endpoint, Map<String, dynamic> formData) async {
    try {
      final token = await _authService.getToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // 确保URL符合prd.mp规范
      final uri = Uri.parse(
          '$_baseUrl/$endpoint?access-token=${token ?? ''}&_=$timestamp');

      // 创建MultipartRequest，按照prd.mp样例
      final request = http.MultipartRequest('POST', uri);

      // 添加表单字段
      formData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Request failed');
        }
      } else {
        throw Exception('Request failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  // 保存首个交易商品信息到本地存储
  Future<void> saveFirstSymbol(MarketModel symbol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final symbolJson = jsonEncode(symbol.toJson());
      await prefs.setString('first_symbol', symbolJson);
      print('First symbol saved: ${symbol.code}');
    } catch (e) {
      print('Error saving first symbol: $e');
    }
  }

  // 获取保存的首个交易商品信息
  Future<MarketModel?> getFirstSymbol() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final symbolJson = prefs.getString('first_symbol');

      if (symbolJson != null) {
        final Map<String, dynamic> data = jsonDecode(symbolJson);
        final symbol = MarketModel.fromJson(data);
        print('First symbol loaded: ${symbol.code}');
        return symbol;
      }
      return null;
    } catch (e) {
      print('Error loading first symbol: $e');
      return null;
    }
  }
}
