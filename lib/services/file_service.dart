//文件操作
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../models/book.dart';

class FileService {
  // 从文件选择器选择EPUB
  Future<Book?> pickEpubFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        final bytes = file.bytes ?? await File(file.path!).readAsBytes();
        
        return Book(
          fileName: file.name,
          filePath: file.path,
          bytes: bytes,
        );
      }
      return null;
    } catch (e) {
      throw Exception('打开文件失败: $e');
    }
  }

  // 从assets加载EPUB
  Future<Book> loadAssetEpub(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      
      return Book(
        fileName: assetPath.split('/').last,
        bytes: bytes,
      );
    } catch (e) {
      throw Exception('加载资源文件失败: $e');
    }
  }

  // 未来可以添加其他文件操作
  // Future<void> saveToLocal(String content, String filename) async { ... }
}