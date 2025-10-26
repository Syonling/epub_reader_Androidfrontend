import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'screens/home_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/settings_screen.dart';
import 'services/api_service.dart';
import 'services/file_service.dart';
import 'widgets/text_input_dialog.dart';
import 'widgets/result_dialog.dart';
import 'models/analysis_result.dart';
import 'dart:typed_data';


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
  // Services
  final ApiService _apiService = ApiService();
  final FileService _fileService = FileService();

  // State
  EpubController? _epubController;
  String? _selectedText;
  bool _isLoading = false;

  // 选择EPUB文件
  Future<void> _pickEpubFile() async {
    try {
      final book = await _fileService.pickEpubFile();
      if (book != null) {
        _loadBook(book.bytes);
      }
    } catch (e) {
      _showMessage('打开文件失败: $e');
    }
  }

  // 加载assets中的EPUB
  Future<void> _loadAssetEpub() async {
    try {
      final book = await _fileService.loadAssetEpub('assets/宝石商.epub');
      _loadBook(book.bytes);
    } catch (e) {
      _showMessage('加载资源失败: $e');
    }
  }

  // 加载书籍
  void _loadBook(List<int> bytes) {
    _epubController?.dispose();
    setState(() {
      _epubController = EpubController(
        document: EpubDocument.openData(Uint8List.fromList(bytes)),
      );
    });
  }

  // 发送文本到后端分析
  Future<void> _sendToBackend(String text) async {
    setState(() {
      _isLoading = true;
      _selectedText = text;
    });

    try {
      final result = await _apiService.analyzeText(text);
      setState(() => _isLoading = false);
      _showResultDialog(result);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('$e\n\n请检查：\n1. 后端是否运行\n2. IP地址是否正确');
    }
  }

  // 显示结果对话框
  void _showResultDialog(AnalysisResult result) {
    showDialog(
      context: context,
      builder: (context) => ResultDialog(
        selectedText: _selectedText!,
        result: result,
      ),
    );
  }

  // 显示文本输入对话框
  void _showTextInputDialog() {
    showDialog(
      context: context,
      builder: (context) => TextInputDialog(
        onSubmit: (text) => _handleTextSelection(text),
      ),
    );
  }

  // 处理文本选择
  void _handleTextSelection(String text) {
    if (text.trim().isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📤 发送到AI分析？'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendToBackend(text);
            },
            child: const Text('发送'),
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

  // 打开设置页面
  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: '设置',
          ),
        ],
      ),
      body: _epubController == null
          ? HomeScreen(
              onPickFile: _pickEpubFile,
              onInputText: _showTextInputDialog,
              onLoadAsset: _loadAssetEpub,
            )
          : ReaderScreen(
              controller: _epubController!,
              onSelectText: _showTextInputDialog,
              isLoading: _isLoading,
            ),
    );
  }

  @override
  void dispose() {
    _epubController?.dispose();
    super.dispose();
  }
}