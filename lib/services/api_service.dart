import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/analysis_result.dart';

class ApiService {
  /// 智能分析（自动判断单词/句子）
  static Future<AnalysisResult?> analyzeText(String text) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.analyzeEndpoint}');
      
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return AnalysisResult.fromJson(jsonResponse);
      }
      return null;
    } catch (e) {
      print('分析错误: $e');
      return null;
    }
  }

  /// 获取可用的AI提供商列表
  static Future<Map<String, dynamic>?> getProviders() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/providers');
      
      final response = await http
          .get(url)
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      print('获取提供商列表错误: $e');
      return null;
    }
  }

  /// 切换AI提供商
  static Future<bool> switchProvider(String providerId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/switch-provider');
      
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'provider': providerId}),
          )
          .timeout(ApiConstants.connectionTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('切换提供商错误: $e');
      return false;
    }
  }
}