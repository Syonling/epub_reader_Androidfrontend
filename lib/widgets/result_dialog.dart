import 'package:flutter/material.dart';
import '../models/analysis_result.dart';

class ResultDialog extends StatelessWidget {
  final AnalysisResult result;

  const ResultDialog({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('分析结果'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '原文:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(result.originalText),
            const SizedBox(height: 16),
            const Text(
              '分析:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_formatAnalysis(result.analysis)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  String _formatAnalysis(Map<String, dynamic> analysis) {
    return analysis.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }
}