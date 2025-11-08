import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:path/path.dart' as p;
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
          
          // 尝试读取EPUB文件
          epubx.EpubBook? book;
          try {
            book = await epubx.EpubReader.readBook(bytes.buffer.asUint8List());
          } catch (readError) {
            print('读取EPUB文件失败: $path, 错误: $readError');
            // 即使读取失败，也添加书籍（使用文件名）
            books.add(Book(
              id: 'book_$i',
              title: fileName,
              author: 'Unknown',
              filePath: path,
            ));
            continue;
          }
          
          if (book != null) {
            // 安全地获取标题
            try {
              final bookTitle = book.Title;
              if (bookTitle != null && bookTitle.isNotEmpty) {
                title = bookTitle;
              }
            } catch (e) {
              print('获取标题失败: $path, $e');
            }
            
            // 安全地获取作者
            try {
              final bookAuthor = book.Author;
              if (bookAuthor != null && bookAuthor.isNotEmpty) {
                author = bookAuthor;
              }
            } catch (e) {
              print('获取作者失败: $path, $e');
            }
          }
        } catch (e) {
          print('加载书籍资源失败: $path, 错误: $e');
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
    
    try {
      return await epubx.EpubReader.readBook(bytes.buffer.asUint8List());
    } catch (e) {
      print('标准方式读取失败，尝试宽松模式: $assetPath, 错误: $e');
      
      // 尝试强制读取，忽略某些验证错误
      try {
        // 直接使用字节数组，不做额外验证
        final book = await epubx.EpubReader.readBook(
          bytes.buffer.asUint8List(),
        );
        return book;
      } catch (e2) {
        print('宽松模式也失败: $e2');
        rethrow;
      }
    }
  }

  // 安全获取封面（修复RangeError）
  static Future<Uint8List?> getBookCover(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final book = await epubx.EpubReader.readBook(bytes.buffer.asUint8List());
      
      return safeCoverImage(book);
    } catch (e) {
      print('获取封面失败: $assetPath, 错误: $e');
      return null;
    }
  }

  // 安全获取封面图片（容错处理）
  static Uint8List? safeCoverImage(epubx.EpubBook book) {
    try {
      final images = book.Content?.Images;
      if (images != null && images.isNotEmpty) {
        // 优先查找包含cover的图片
        final candidates = images.entries.toList();
        
        // 方法1: 通过key查找cover
        for (final entry in candidates) {
          final key = entry.key.toLowerCase();
          if (key.contains('cover')) {
            if (entry.value.Content != null && entry.value.Content!.isNotEmpty) {
              return Uint8List.fromList(entry.value.Content!);
            }
          }
        }
        
        // 方法2: 通过FileName查找cover
        for (final entry in candidates) {
          final fileName = entry.value.FileName?.toLowerCase() ?? '';
          if (fileName.contains('cover')) {
            if (entry.value.Content != null && entry.value.Content!.isNotEmpty) {
              return Uint8List.fromList(entry.value.Content!);
            }
          }
        }
        
        // 方法3: 取第一个非空图片
        for (final entry in candidates) {
          if (entry.value.Content != null && entry.value.Content!.isNotEmpty) {
            return Uint8List.fromList(entry.value.Content!);
          }
        }
      }
    } catch (e) {
      print('获取封面时出错: $e');
    }
    
    return null;
  }

  // 判定该页是否为竖排
  static bool isVerticalHtml(String html) {
    final lower = html.toLowerCase();
    // 常见竖排声明
    const keys = [
      'writing-mode: vertical-rl',
      'writing-mode:vertical-rl',
      '-epub-writing-mode: vertical-rl',
      '-epub-writing-mode:vertical-rl',
      'writing-mode: tb-rl',
      'writing-mode:tb-rl',
    ];
    for (final k in keys) {
      if (lower.contains(k)) return true;
    }
    // 检查meta标签
    if (lower.contains('rendition:writing-mode') && 
        lower.contains('vertical-rl')) {
      return true;
    }
    return false;
  }

  // 把<img src="相对路径">改成file://绝对路径（暂不使用，保留给未来）
  static String fixImageSrcs(String html, String pageDirAbs) {
    return html.replaceAllMapped(
      RegExp(r'<img([^>]*?)\s+src=["' + "'" + r']([^"' + "'" + r']+)["' + "'" + r']([^>]*)>', 
             caseSensitive: false),
      (m) {
        final pre = m[1] ?? '';
        final src = (m[2] ?? '').trim();
        final post = m[3] ?? '';
        if (src.startsWith('http://') || 
            src.startsWith('https://') || 
            src.startsWith('file://')) {
          return '<img$pre src="$src"$post>';
        }
        final abs = p.normalize(p.join(pageDirAbs, src));
        return '<img$pre src="file://$abs"$post>';
      },
    );
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