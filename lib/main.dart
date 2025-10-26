import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI阅读助手',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const EpubReaderPage(),
    );
  }
}

class EpubReaderPage extends StatefulWidget {
  const EpubReaderPage({Key? key}) : super(key: key);

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  EpubController? _epubController;
  String? _selectedText;
  bool _isLoading = false;
  String? _aiResponse;

  // ⚠️ 重要：修改为你的Mac局域网IP
  // 查看IP命令: ifconfig | grep "inet " | grep -v 127.0.0.1
  final String backendUrl = 'http://192.168.11.126:5001/api/analyze';

  // 选择EPUB文件
  Future<void> _pickEpubFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        withData: true, // 确保同时拿到 bytes
      );

      if (result != null) {
        final bytes = result.files.single.bytes ??
            await File(result.files.single.path!).readAsBytes();

        _epubController?.dispose();

        setState(() {
          _epubController = EpubController(
            document: EpubDocument.openData(bytes),
          );
        });
      }
    } catch (e) {
      _showMessage('打开文件失败: $e');
    }
  }

  // 发送选中文本到后端
  Future<void> _sendToBackend(String text) async {
    setState(() {
      _isLoading = true;
      _aiResponse = null;
    });

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _aiResponse = data['message'] ?? '后端已收到';
        });
        _showResultDialog();
      } else {
        _showMessage('后端错误: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('连接失败: $e\n\n请检查：\n1. 后端是否运行\n2. IP地址是否正确');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 显示结果对话框
  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ AI分析结果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选中文本:', 
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_selectedText ?? '', 
                style: const TextStyle(color: Colors.blue)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('后端响应:', 
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_aiResponse ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 显示提示消息
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 处理文本选择
  void _handleTextSelection(String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _selectedText = text.trim();
    });

    // 显示确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📤 发送到AI分析？'),
        content: Text(_selectedText!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendToBackend(_selectedText!);
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  // 手动输入文本（模拟选择功能）
  void _showTextInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入要分析的句子'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '例如: This is a beautiful day.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context);
                _handleTextSelection(text);
              }
            },
            child: const Text('发送到AI'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI阅读助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _pickEpubFile,
            tooltip: '打开EPUB',
          ),
        ],
      ),
      body: _epubController == null
          ? Center(
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
                    onPressed: _pickEpubFile,
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
                  TextButton.icon(
                    onPressed: _showTextInputDialog,
                    icon: const Icon(Icons.text_fields),
                    label: const Text('或直接输入文本测试'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                EpubView(
                  controller: _epubController!,
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
                    onPressed: _showTextInputDialog,
                    icon: const Icon(Icons.text_fields),
                    label: const Text('选择文本'),
                    backgroundColor: Colors.blue,
                  ),
                ),
                
                // 加载指示器
                if (_isLoading)
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
            ),
    );
  }

  @override
  void dispose() {
    _epubController?.dispose();
    super.dispose();
  }
}