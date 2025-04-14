import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userInfoKey = 'user_info';
  static const String _baseUrl = 'https://www.global-rlspo.top/api';
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // 检查用户是否已登录
  Future<bool> isLoggedIn() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString(_tokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('检查登录状态失败: $e');
      return false;
    }
  }

  // 保存认证令牌
  Future<bool> saveToken(String token) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      debugPrint('保存令牌失败: $e');
      return false;
    }
  }

  // 获取认证令牌
  Future<String?> getToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('获取令牌失败: $e');
      return null;
    }
  }

  // 保存用户信息
  Future<bool> saveUserInfo(Map<String, dynamic> userInfo) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String userInfoJson = jsonEncode(userInfo);
      return await prefs.setString(_userInfoKey, userInfoJson);
    } catch (e) {
      debugPrint('保存用户信息失败: $e');
      return false;
    }
  }

  // 获取用户信息
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userInfoJson = prefs.getString(_userInfoKey);

      if (userInfoJson != null && userInfoJson.isNotEmpty) {
        return jsonDecode(userInfoJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
      return null;
    }
  }

  // 登出
  Future<bool> logout() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userInfoKey);
      return true;
    } catch (e) {
      debugPrint('登出失败: $e');
      return false;
    }
  }

  // 登录请求 - 调用实际API
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final uri = Uri.parse(
          '$_baseUrl/v1/site/login-name?access-token=null&_=$timestamp');

      // 创建 MultipartRequest
      final request = http.MultipartRequest('POST', uri);

      // 添加表单字段
      request.fields['username'] = username;
      request.fields['password'] = password;
      request.fields['group'] = 'app';

      // 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = json.decode(response.body);

      if (data['code'] == 200) {
        // 如果登录成功，保存令牌
        if (data['data'] != null && data['data']['access_token'] != null) {
          final token = data['data']['access_token'];
          await saveToken(token);

          // 如果有用户信息，也保存下来
          if (data['data']['user'] != null) {
            await saveUserInfo(data['data']['user']);
          }
        }
        return data;
      } else {
        throw Exception(data['message'] ?? '登录失败');
      }
    } catch (e) {
      debugPrint('登录失败: $e');
      throw Exception('登录失败: $e');
    }
  }
}
