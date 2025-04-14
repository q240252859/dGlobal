import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class TradeService {
  static const String _baseUrl = 'https://www.global-rlspo.top/api';
  final AuthService _authService = AuthService();

  // Helper method for making authenticated POST requests (similar to MarketService)
  Future<Map<String, dynamic>> _postRequest(
      String endpoint, Map<String, dynamic> formData) async {
    try {
      final token = await _authService.getToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Ensure URL conforms to prd.mp specification
      final uri = Uri.parse(
          '$_baseUrl/$endpoint?access-token=${token ?? ''}&_=$timestamp');

      // Create MultipartRequest as per prd.mp examples
      final request = http.MultipartRequest('POST', uri);

      // Add form data fields
      formData.forEach((key, value) {
        // Ensure all values are strings
        request.fields[key] = value.toString();
      });

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200) {
          return data; // Return the full response data on success
        } else {
          throw Exception(data['message'] ?? 'API error code: ${data['code']}');
        }
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _postRequest ($endpoint): $e');
      throw Exception('Failed to execute request ($endpoint): $e');
    }
  }

  // Place a new trade order
  Future<Map<String, dynamic>> createOrder({
    required String symbolCode,
    required double volume,
    required String riseFall, // 'RISE' for buy, 'FALL' for sell
    double? stopProfit, // Optional Take Profit price
    double? stopLoss, // Optional Stop Loss price
  }) async {
    final Map<String, dynamic> formData = {
      'code': symbolCode,
      'volume': volume,
      'rise_fall': riseFall,
    };

    // Add optional parameters if provided
    if (stopProfit != null) {
      formData['stop_profit'] = stopProfit;
    }
    if (stopLoss != null) {
      formData['stop_loss'] = stopLoss;
    }

    // Call the API endpoint to open the position
    return await _postRequest(
        'addons/tf-futures/order/open-with-price', formData);
  }

  // Close an existing position
  Future<Map<String, dynamic>> closeOrder({
    required String orderId,
    required double
        volume, // The volume to close (usually full volume for one-click close)
  }) async {
    final Map<String, dynamic> formData = {
      'orderid': orderId,
      'volume': volume,
    };

    // Call the API endpoint to close the position
    return await _postRequest('addons/tf-futures/order/close-order', formData);
  }

  // Modify Take Profit / Stop Loss for an existing order (Placeholder)
  Future<Map<String, dynamic>> modifyOrder({
    required String orderId,
    double? stopProfit,
    double? stopLoss,
  }) async {
    final Map<String, dynamic> formData = {
      'orderid': orderId,
    };

    // Include TP/SL only if they are provided (null means don't change or remove)
    if (stopProfit != null) {
      formData['stop_profit'] = stopProfit;
    } else {
      // Assuming sending an empty string or 0 might remove the TP/SL
      // Adjust this based on actual API behavior
      formData['stop_profit'] = 0;
    }

    if (stopLoss != null) {
      formData['stop_loss'] = stopLoss;
    } else {
      formData['stop_loss'] = 0;
    }

    // !!! Placeholder: Replace with the actual endpoint for modifying orders !!!
    print("Calling placeholder modifyOrder endpoint. Update required.");
    return await _postRequest('addons/tf-futures/order/modify-tp-sl', formData);
    // Example: return await _postRequest('addons/tf-futures/order/set-tp-sl', formData);
  }
}
