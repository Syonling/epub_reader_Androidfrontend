//API地址等常量

import 'env.dart';

class ApiConstants {
  static String get baseUrl => Env.backendUrl;  // 动态获取
  static const String analyzeEndpoint = '/api/analyze';
  static const Duration connectionTimeout = Duration(seconds: 30);
}