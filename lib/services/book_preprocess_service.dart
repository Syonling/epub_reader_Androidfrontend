import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../services/epub_service.dart';
import '../services/book_cache_service.dart';
import '../utils/html_parser.dart';
import '../utils/pagination_calculator.dart';

/// 书籍预处理服务 - 在后台预先计算所有书籍的分页
/// 参考 Kindle 的实现：应用启动时在后台静默处理
class BookPreprocessService {
  static bool _isProcessing = false;
  static int _processedCount = 0;
  static int _totalCount = 0;
  static Function(int processed, int total)? _onProgress;

  /// 检查书籍是否需要预处理
  static Future<bool> needsPreprocessing(
    String bookId,
    double fontSize,
  ) async {
    final cache = await BookCacheService.loadCache(bookId, fontSize);
    return cache == null;
  }

  /// 预处理所有书籍（在后台静默执行）
  /// 
  /// 使用场景：
  /// 1. 应用启动时调用
  /// 2. 添加新书籍后调用
  /// 3. 字体大小全局改变后调用
  static Future<void> preprocessAllBooks(
    List<Book> books,
    BuildContext context,
    double fontSize, {
    Function(int processed, int total)? onProgress,
  }) async {
    if (_isProcessing) {
      print('⚠ 预处理已在进行中');
      return;
    }

    _isProcessing = true;
    _processedCount = 0;
    _totalCount = 0;
    _onProgress = onProgress;

    print('\n========== 开始预处理书籍 ==========');
    print('总书籍数: ${books.length}');

    // 筛选需要处理的书籍
    List<Book> needsProcessing = [];
    for (var book in books) {
      if (await needsPreprocessing(book.id, fontSize)) {
        needsProcessing.add(book);
      }
    }

    _totalCount = needsProcessing.length;
    print('需要预处理: $_totalCount 本书');

    if (_totalCount == 0) {
      print('✓ 所有书籍已有缓存');
      print('==================================\n');
      _isProcessing = false;
      return;
    }

    // 获取屏幕尺寸（用于计算分页）
    final size = MediaQuery.of(context).size;
    final availableHeight = PaginationCalculator.calculateAvailableHeight(context);
    final availableWidth = size.width - 48;

    // 逐本处理
    for (int i = 0; i < needsProcessing.length; i++) {
      final book = needsProcessing[i];
      
      print('\n处理中 [${i + 1}/$_totalCount]: ${book.title}');
      
      try {
        await _preprocessSingleBook(
          book,
          fontSize,
          availableHeight,
          availableWidth,
        );
        
        _processedCount++;
        _onProgress?.call(_processedCount, _totalCount);
        
        print('✓ 完成: ${book.title}');
      } catch (e) {
        print('❌ 失败: ${book.title} - $e');
      }

      // 小延迟，避免阻塞UI（可选）
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('\n========== 预处理完成 ==========');
    print('成功: $_processedCount/$_totalCount');
    print('==================================\n');

    _isProcessing = false;
  }

  /// 预处理单本书籍
  static Future<void> _preprocessSingleBook(
    Book book,
    double fontSize,
    double availableHeight,
    double availableWidth,
  ) async {
    final startTime = DateTime.now();

    // 1. 加载 EPUB
    final epubBook = await EpubService.loadEpubFromAsset(book.filePath);

    // 2. 提取章节内容
    List<String> contents = [];

    if (epubBook.Content?.Html != null) {
      for (var entry in epubBook.Content!.Html!.entries) {
        try {
          final htmlContent = entry.value;
          final content = htmlContent.Content;

          if (content != null && HtmlParser.hasValidContent(content)) {
            contents.add(content);
          }
        } catch (e) {
          // 跳过错误的章节
        }
      }
    }

    if (contents.isEmpty && epubBook.Chapters != null) {
      _extractChapterContents(epubBook.Chapters!, contents);
    }

    if (contents.isEmpty) {
      throw Exception('无法提取章节内容');
    }

    // 3. 计算所有章节的分页
    final textStyle = TextStyle(
      fontSize: fontSize,
      height: 1.8,
    );

    List<List<String>> allPages = [];

    for (var content in contents) {
      final parsed = HtmlParser.extractContentWithLinks(content);

      final pages = PaginationCalculator.paginateByHeight(
        parsed.text,
        availableHeight,
        textStyle,
        availableWidth,
      );

      allPages.add(pages);
    }

    // 4. 保存缓存
    final cache = BookCache(
      bookId: book.id,
      allChapterPages: allPages,
      currentChapter: 0,
      currentPage: 0,
      fontSize: fontSize,
      cachedAt: DateTime.now(),
    );

    await BookCacheService.saveCache(cache);

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    print('  章节数: ${contents.length}');
    print('  总页数: ${allPages.fold(0, (sum, pages) => sum + pages.length)}');
    print('  耗时: ${duration}ms');
  }

  /// 提取章节内容（递归）
  static void _extractChapterContents(
    List<dynamic> chapters,
    List<String> contents,
  ) {
    for (var chapter in chapters) {
      if (chapter.HtmlContent != null && chapter.HtmlContent!.isNotEmpty) {
        if (HtmlParser.hasValidContent(chapter.HtmlContent!)) {
          contents.add(chapter.HtmlContent!);
        }
      }
      if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
        _extractChapterContents(chapter.SubChapters!, contents);
      }
    }
  }

  /// 预处理单本书籍（公共接口）
  /// 用于添加新书后立即预处理
  static Future<void> preprocessBook(
    Book book,
    BuildContext context,
    double fontSize,
  ) async {
    print('\n========== 预处理新书籍 ==========');
    print('书籍: ${book.title}');

    try {
      // 检查是否已有缓存
      if (!await needsPreprocessing(book.id, fontSize)) {
        print('✓ 已有缓存，跳过');
        return;
      }

      final size = MediaQuery.of(context).size;
      final availableHeight = PaginationCalculator.calculateAvailableHeight(context);
      final availableWidth = size.width - 48;

      await _preprocessSingleBook(
        book,
        fontSize,
        availableHeight,
        availableWidth,
      );

      print('✓ 预处理完成');
    } catch (e) {
      print('❌ 预处理失败: $e');
    }
    
    print('==================================\n');
  }

  /// 获取预处理进度
  static Map<String, int> getProgress() {
    return {
      'processed': _processedCount,
      'total': _totalCount,
    };
  }

  /// 是否正在预处理
  static bool get isProcessing => _isProcessing;

  /// 取消预处理（如果需要）
  static void cancel() {
    _isProcessing = false;
    print('⚠ 预处理已取消');
  }
}