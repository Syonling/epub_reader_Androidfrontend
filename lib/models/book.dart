//书籍数据模型
import 'dart:typed_data';

class Book {
  final String? fileName;
  final String? filePath;
  final Uint8List bytes;

  Book({
    this.fileName,
    this.filePath,
    required this.bytes,
  });
}