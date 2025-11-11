import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/book.dart';
import '../models/reader_settings.dart';
import '../services/epub_service.dart';
import '../services/book_preprocess_service.dart';
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> _books = [];
  bool _isLoading = true;
  // *** 问题1修复：保存每本书的封面 ***
  Map<String, Uint8List?> _bookCovers = {};
  
  // 预处理状态
  bool _isPreprocessing = false;
  int _preprocessedCount = 0;
  int _preprocessTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await EpubService.loadBooksFromAssets();
      
      // *** 加载每本书的封面 ***
      final covers = <String, Uint8List?>{};
      for (var book in books) {
        final cover = await EpubService.getBookCover(book.filePath);
        covers[book.filePath] = cover;
      }
      
      setState(() {
        _books = books;
        _bookCovers = covers;
        _isLoading = false;
      });
      
      // 书架加载完成后，在后台启动预处理
      _startBackgroundPreprocessing();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 在后台预处理所有书籍
  Future<void> _startBackgroundPreprocessing() async {
    // 等待UI渲染完成
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    setState(() {
      _isPreprocessing = true;
    });
    
    // 获取默认字体大小
    final fontSize = ReaderSettings().fontSize.size;
    
    // 开始预处理
    await BookPreprocessService.preprocessAllBooks(
      _books,
      context,
      fontSize,
      onProgress: (processed, total) {
        if (mounted) {
          setState(() {
            _preprocessedCount = processed;
            _preprocessTotal = total;
          });
        }
      },
    );
    
    if (mounted) {
      setState(() {
        _isPreprocessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的书架'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _books.isEmpty
                  ? const Center(
                      child: Text(
                        '没有找到书籍\n请将epub文件放入assets/books/目录',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        return _buildBookCard(_books[index]);
                      },
                    ),
          
          // 预处理进度提示（浮动在底部）
          if (_isPreprocessing)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '正在优化书籍... $_preprocessedCount/$_preprocessTotal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        _preprocessTotal > 0
                            ? '${(_preprocessedCount / _preprocessTotal * 100).toInt()}%'
                            : '0%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    final cover = _bookCovers[book.filePath];
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReaderScreen(book: book),
          ),
        );
      },
      child: Card(
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[300],
                child: cover != null
                    ? Image.memory(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.book, size: 64);
                        },
                      )
                    : const Icon(Icons.book, size: 64),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}