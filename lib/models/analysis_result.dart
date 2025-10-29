class AnalysisResult {
  final String originalText;
  final Map<String, dynamic> analysis;
  final DateTime timestamp;

  AnalysisResult({
    required this.originalText,
    required this.analysis,
    required this.timestamp,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      originalText: json['original_text'] ?? '',
      analysis: json['analysis'] ?? {},
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}