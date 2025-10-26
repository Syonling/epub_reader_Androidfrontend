// 首页
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onPickFile;
  final VoidCallback onInputText;
  final VoidCallback? onLoadAsset;

  const HomeScreen({
    Key? key,
    required this.onPickFile,
    required this.onInputText,
    this.onLoadAsset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.book, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            '欢迎使用AI阅读助手',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('选择EPUB文件'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (onLoadAsset != null)
            ElevatedButton.icon(
              onPressed: onLoadAsset,
              icon: const Icon(Icons.book),
              label: const Text('打开示例EPUB'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onInputText,
            icon: const Icon(Icons.text_fields),
            label: const Text('或直接输入文本测试'),
          ),
        ],
      ),
    );
  }
}