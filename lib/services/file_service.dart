import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';

class FileService {
  // 获取assets中的所有epub书籍
  static Future<List<Book>> loadBooksFromAssets() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = 
        Map<String, dynamic>.from(
            (await rootBundle.loadStructuredData('AssetManifest.json', 
                (jsonStr) async => Map<String, dynamic>.from(
                    Map<String, dynamic>.from(
                        Uri.dataFromString(manifestContent).data!.contentAsString() as Map
                    )
                )
            ))
        );

    final epubPaths = manifestMap.keys
        .where((String key) => key.contains('assets/books/') && key.endsWith('.epub'))
        .toList();

    List<Book> books = [];
    for (int i = 0; i < epubPaths.length; i++) {
      final path = epubPaths[i];
      final fileName = path.split('/').last.replaceAll('.epub', '');
      
      books.add(Book(
        id: 'book_$i',
        title: fileName,
        author: 'Unknown',
        filePath: path,
      ));
    }

    return books;
  }

  // 将asset文件复制到临时目录以供epub_view使用
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