import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:epubx/epubx.dart' as epubx;
import '../models/book.dart';

class EpubService {
  static Future<List<Book>> loadBooksFromAssets() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      
      // 使用 Set 去重
      final Set<String> epubPathsSet = {};
      
      // 提取所有 epub 文件路径
      final regex = RegExp(r'"(assets/books/[^"]*\.epub)"');
      final matches = regex.allMatches(manifestContent);
      
      for (var match in matches) {
        final path = match.group(1);
        if (path != null && path.endsWith('.epub')) {
          epubPathsSet.add(path);
        }
      }
      
      List<String> epubPaths = epubPathsSet.toList();
      epubPaths.sort(); // 排序
      
      print('找到 ${epubPaths.length} 本书: $epubPaths');

      List<Book> books = [];
      for (int i = 0; i < epubPaths.length; i++) {
        final path = epubPaths[i];
        final fileName = path.split('/').last.replaceAll('.epub', '');
        
        String title = fileName;
        String author = 'Unknown';
        
        try {
          final bytes = await rootBundle.load(path);
          final book = await epubx.EpubReader.readBook(bytes.buffer.asUint8List());
          title = book.Title ?? fileName;
          author = book.Author ?? 'Unknown';
        } catch (e) {
          print('解析书籍元数据失败: $path, 错误: $e');
        }

        books.add(Book(
          id: 'book_$i',
          title: title,
          author: author,
          filePath: path,
        ));
      }

      return books;
    } catch (e) {
      print('加载书籍失败: $e');
      return [];
    }
  }

  static Future<epubx.EpubBook> loadEpubFromAsset(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    return await epubx.EpubReader.readBook(bytes.buffer.asUint8List());
  }

  // *** 修复：正确处理 CoverImage 类型 ***
  static Future<Uint8List?> getBookCover(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final book = await epubx.EpubReader.readBook(bytes.buffer.asUint8List());
      
      // 方法1：尝试从 Content.Images 中查找封面
      if (book.Content?.Images != null) {
        // 常见封面文件名
        final coverNames = [
          'cover.jpg', 'cover.jpeg', 'cover.png', 'cover.gif',
          'Cover.jpg', 'Cover.jpeg', 'Cover.png', 'Cover.gif',
          'cover-image.jpg', 'cover-image.jpeg', 'cover-image.png',
        ];
        
        // 先精确匹配
        for (var coverName in coverNames) {
          for (var entry in book.Content!.Images!.entries) {
            if (entry.key.toLowerCase().contains(coverName.toLowerCase())) {
              if (entry.value.Content != null) {
                return Uint8List.fromList(entry.value.Content!);
              }
            }
          }
        }
        
        // 如果没找到，尝试第一张图片
        if (book.Content!.Images!.isNotEmpty) {
          final firstImage = book.Content!.Images!.values.first;
          if (firstImage.Content != null) {
            return Uint8List.fromList(firstImage.Content!);
          }
        }
      }
      
      return null;
    } catch (e) {
      print('获取封面失败: $assetPath, 错误: $e');
      return null;
    }
  }

  static Future<String> copyAssetToTemp(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${tempDir.path}/$fileName');
    
    await file.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );
    
    return file.path;
  }
}