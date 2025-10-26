//API地址等常量

import 'env.dart';

class ApiConstants {
  // 后端API地址
  static String get baseUrl => Env.backendUrl;  // 动态获取
  static const String analyzeEndpoint = '/api/analyze';
  
  // 完整URL
  static String get analyzeUrl => '$baseUrl$analyzeEndpoint';
  
  // 超时设置
  static const Duration timeout = Duration(seconds: 10);
  
  // 请求头
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
}