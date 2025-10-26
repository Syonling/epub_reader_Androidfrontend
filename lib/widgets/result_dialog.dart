import 'package:flutter/material.dart';
import '../models/analysis_result.dart';

class ResultDialog extends StatelessWidget {
  final String selectedText;
  final AnalysisResult result;

  const ResultDialog({
    Key? key,
    required this.selectedText,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('✅ AI分析结果'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选中文本:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              selectedText,
              style: const TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '后端响应:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(result.message),
            if (result.analysis != null) ...[
              const SizedBox(height: 12),
              Text('词数: ${result.analysis!.wordCount}'),
              const SizedBox(height: 4),
              Text(result.analysis!.info),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}