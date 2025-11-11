import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 书籍缓存数据（包含所有分页结果和阅读进度）
class BookCache {
  final String bookId;
  final List<List<String>> allChapterPages; // 所有章节的分页
  final int currentChapter;
  final int currentPage;
  final double fontSize;
  final DateTime cachedAt;

  BookCache({
    required this.bookId,
    required this.allChapterPages,
    required this.currentChapter,
    required this.currentPage,
    required this.fontSize,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'allChapterPages': allChapterPages,
        'currentChapter': currentChapter,
        'currentPage': currentPage,
        'fontSize': fontSize,
        'cachedAt': cachedAt.toIso8601String(),
      };

  factory BookCache.fromJson(Map<String, dynamic> json) {
    return BookCache(
      bookId: json['bookId'] as String,
      allChapterPages: (json['allChapterPages'] as List)
          .map((chapter) => List<String>.from(chapter as List))
          .toList(),
      currentChapter: json['currentChapter'] as int,
      currentPage: json['currentPage'] as int,
      fontSize: (json['fontSize'] as num).toDouble(),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }
}

/// 书籍缓存服务 - 参考 flutter_read 的设计
class BookCacheService {
  static const String _prefix = 'book_cache_';

  /// 保存完整的书籍缓存（一次性保存所有分页）
  static Future<void> saveCache(BookCache cache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix${cache.bookId}';
      final json = jsonEncode(cache.toJson());
      
      await prefs.setString(key, json);
      
      print('✓ 缓存已保存');
      print('  书籍ID: ${cache.bookId}');
      print('  总章节: ${cache.allChapterPages.length}');
      print('  总页数: ${cache.allChapterPages.fold(0, (sum, pages) => sum + pages.length)}');
      print('  字体大小: ${cache.fontSize}');
    } catch (e) {
      print('❌ 保存缓存失败: $e');
    }
  }

  /// 加载书籍缓存
  static Future<BookCache?> loadCache(String bookId, double fontSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix$bookId';
      final json = prefs.getString(key);

      if (json == null) {
        print('⚠ 无缓存数据');
        return null;
      }

      final data = jsonDecode(json) as Map<String, dynamic>;
      final cache = BookCache.fromJson(data);

      // 检查字体大小是否匹配
      if ((cache.fontSize - fontSize).abs() > 0.1) {
        print('⚠ 字体大小已变更，缓存失效');
        return null;
      }

      print('✓ 缓存加载成功');
      print('  总章节: ${cache.allChapterPages.length}');
      print('  当前位置: 章节${cache.currentChapter} 页${cache.currentPage}');
      
      return cache;
    } catch (e) {
      print('❌ 加载缓存失败: $e');
      return null;
    }
  }

  /// 更新阅读进度（不重新保存分页，只更新进度）
  static Future<void> updateProgress(
    String bookId,
    int chapter,
    int page,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix$bookId';
      final json = prefs.getString(key);

      if (json == null) return;

      final data = jsonDecode(json) as Map<String, dynamic>;
      
      // 只更新进度字段
      data['currentChapter'] = chapter;
      data['currentPage'] = page;
      data['cachedAt'] = DateTime.now().toIso8601String();

      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      print('❌ 更新进度失败: $e');
    }
  }

  /// 清除指定书籍的缓存
  static Future<void> clearCache(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix$bookId';
      await prefs.remove(key);
      print('✓ 缓存已清除: $bookId');
    } catch (e) {
      print('❌ 清除缓存失败: $e');
    }
  }

  /// 获取所有缓存的书籍ID
  static Future<List<String>> getAllCachedBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      return keys
          .where((key) => key.startsWith(_prefix))
          .map((key) => key.substring(_prefix.length))
          .toList();
    } catch (e) {
      print('❌ 获取缓存列表失败: $e');
      return [];
    }
  }

  /// 清除所有缓存
  static Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_prefix)) {
          await prefs.remove(key);
        }
      }
      
      print('✓ 所有缓存已清除');
    } catch (e) {
      print('❌ 清除所有缓存失败: $e');
    }
  }
}