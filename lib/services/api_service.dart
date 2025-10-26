//所有API调用
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../models/analysis_result.dart';

class ApiService {
  // 发送文本到后端分析
  Future<AnalysisResult> analyzeText(String text) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.analyzeUrl),
        headers: ApiConstants.headers,
        body: jsonEncode({'text': text}),
      ).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return AnalysisResult.fromJson(data);
      } else {
        throw Exception('后端错误: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('连接失败: $e');
    }
  }

  // 未来可以添加其他API调用
  // Future<String> translateText(String text) async { ... }
  // Future<List<String>> getVocabulary(String text) async { ... }
}