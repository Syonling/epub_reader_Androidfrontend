//分析结果数据
class AnalysisResult {
  final String status;
  final String message;
  final String receivedText;
  final AnalysisData? analysis;

  AnalysisResult({
    required this.status,
    required this.message,
    required this.receivedText,
    this.analysis,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      receivedText: json['received_text'] ?? '',
      analysis: json['analysis'] != null 
          ? AnalysisData.fromJson(json['analysis']) 
          : null,
    );
  }
}

class AnalysisData {
  final String info;
  final int wordCount;

  AnalysisData({
    required this.info,
    required this.wordCount,
  });

  factory AnalysisData.fromJson(Map<String, dynamic> json) {
    return AnalysisData(
      info: json['info'] ?? '',
      wordCount: json['word_count'] ?? 0,
    );
  }
}