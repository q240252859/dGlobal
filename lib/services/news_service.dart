import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';
import 'auth_service.dart';

class NewsService {
  static const String _baseUrl = 'https://www.global-rlspo.top/api';
  final AuthService _authService = AuthService();

  // Fetch news articles with pagination
  Future<NewsResponse> getNews({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final token = await _authService.getToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Construct URL with query parameters
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'access-token': token ?? '',
        '_': timestamp,
      };

      final uri = Uri.parse('$_baseUrl/addons/tf-futures/article/news')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200) {
          return NewsResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to load news');
        }
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news: $e');
      throw Exception('Failed to load news: $e');
    }
  }
}
