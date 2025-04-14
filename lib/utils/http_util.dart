import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HttpUtil {
  static HttpUtil? _instance;
  late Dio _dio;
  final String _baseUrl = 'https://www.global-rlspo.top/api';
  final Duration _connectTimeout = const Duration(seconds: 15);
  final Duration _receiveTimeout = const Duration(seconds: 15);

  // 工厂构造函数
  factory HttpUtil() => _instance ?? HttpUtil._internal();

  // 命名构造函数
  HttpUtil._internal() {
    BaseOptions options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      headers: {},
      contentType: 'application/json; charset=utf-8',
      responseType: ResponseType.json,
    );
    _dio = Dio(options);

    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 添加必要的参数
        final token = await _getToken();
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

        // 拼接URL参数
        final uri = Uri.parse(options.path);
        final queryParams = Map<String, dynamic>.from(uri.queryParameters);

        // 添加必需的参数access-token和_
        queryParams['access-token'] = token ?? 'null';
        queryParams['_'] = timestamp;

        options.path = '${uri.path}?${_mapToQueryString(queryParams)}';

        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 处理响应数据
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        // 错误处理
        return handler.next(e);
      },
    ));
  }

  // 获取token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // 将Map转换为查询字符串
  String _mapToQueryString(Map<String, dynamic> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  // GET请求
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // POST请求
  Future<dynamic> post(String path,
      {Map<String, dynamic>? params, dynamic data}) async {
    try {
      final response =
          await _dio.post(path, queryParameters: params, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // POST表单请求 (包含文件上传)
  Future<dynamic> postForm(String path,
      {Map<String, dynamic>? params, required FormData formData}) async {
    try {
      final response = await _dio.post(
        path,
        queryParameters: params,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 处理响应
  dynamic _handleResponse(Response response) {
    final data = response.data;
    if (data is Map && data.containsKey('code')) {
      if (data['code'] == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Request failed');
      }
    }
    return data;
  }

  // 处理错误
  dynamic _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        throw Exception('Connection timeout');
      case DioExceptionType.sendTimeout:
        throw Exception('Send timeout');
      case DioExceptionType.receiveTimeout:
        throw Exception('Receive timeout');
      case DioExceptionType.badResponse:
        if (e.response != null) {
          final data = e.response!.data;
          if (data is Map && data.containsKey('message')) {
            throw Exception(data['message']);
          }
        }
        throw Exception('Server error: ${e.response?.statusCode}');
      case DioExceptionType.cancel:
        throw Exception('Request cancelled');
      default:
        throw Exception('Network error: ${e.message}');
    }
  }

  // 创建FormData用于文件上传
  Future<FormData> createFormData(
      Map<String, dynamic> fields, List<MapEntry<String, File>>? files) async {
    final formData = FormData();

    // 添加字段
    fields.forEach((key, value) {
      formData.fields.add(MapEntry(key, value.toString()));
    });

    // 添加文件
    if (files != null) {
      for (var file in files) {
        formData.files.add(
          MapEntry(
            file.key,
            await MultipartFile.fromFile(file.value.path),
          ),
        );
      }
    }

    return formData;
  }

  // 登录请求的特殊处理
  Future<dynamic> login(String username, String password) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final path = '/v1/site/login-name';

      // 创建表单数据
      final formData = FormData.fromMap({
        'username': username,
        'password': password,
        'group': 'app',
      });

      final response = await _dio.post(
        '$path?access-token=null&_=$timestamp',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
}
