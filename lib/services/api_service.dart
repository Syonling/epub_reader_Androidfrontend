import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/analysis_result.dart';

class ApiService {
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
      return null;
    }
  }
}