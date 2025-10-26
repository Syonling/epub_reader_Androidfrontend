//阅读页
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';

class ReaderScreen extends StatelessWidget {
  final EpubController controller;
  final VoidCallback onSelectText;
  final bool isLoading;

  const ReaderScreen({
    Key? key,
    required this.controller,
    required this.onSelectText,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        EpubView(
          controller: controller,
          builders: EpubViewBuilders<DefaultBuilderOptions>(
            options: const DefaultBuilderOptions(),
            chapterDividerBuilder: (_) => const Divider(),
          ),
        ),
        
        // 悬浮按钮
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: onSelectText,
            icon: const Icon(Icons.text_fields),
            label: const Text('选择文本'),
            backgroundColor: Colors.blue,
          ),
        ),
        
        // 加载指示器
        if (isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'AI分析中...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}