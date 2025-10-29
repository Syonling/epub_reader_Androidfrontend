import 'package:flutter/material.dart';

class VerticalTextWidget extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final Function(String)? onTextSelected;
  
  const VerticalTextWidget({
    super.key,
    required this.text,
    required this.textStyle,
    this.onTextSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: VerticalTextPainter(
            text: text,
            textStyle: textStyle,
          ),
        );
      },
    );
  }
}

class VerticalTextPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;
  
  VerticalTextPainter({
    required this.text,
    required this.textStyle,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paragraphs = text.split('\n');
    
    // 从右向左绘制（竖排文本习惯）
    double currentX = size.width - 20;
    const paragraphSpacing = 24.0;
    
    // 计算单个字符的尺寸
    final charMetrics = _measureChar('測');
    final charWidth = charMetrics.width + 4.0;
    final charHeight = charMetrics.height;
    const lineSpacing = 4.0;
    
    for (var paragraph in paragraphs) {
      if (paragraph.isEmpty) {
        // 空段落占位
        currentX -= 16.0;
        continue;
      }
      
      // 计算这个段落需要多少列
      final maxCharsPerColumn = ((size.height - 80) / (charHeight + lineSpacing)).floor();
      final columnsNeeded = (paragraph.length / maxCharsPerColumn).ceil();
      
      // 从右向左绘制每列
      for (int col = columnsNeeded - 1; col >= 0; col--) {
        final startIdx = col * maxCharsPerColumn;
        final endIdx = ((col + 1) * maxCharsPerColumn).clamp(0, paragraph.length);
        final columnText = paragraph.substring(startIdx, endIdx);
        
        currentX -= charWidth;
        
        // 从上到下绘制每个字符
        double currentY = 20.0;
        for (int i = 0; i < columnText.length; i++) {
          final char = columnText[i];
          
          // 绘制单个字符
          final textPainter = TextPainter(
            text: TextSpan(text: char, style: textStyle),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          
          // 居中对齐字符
          final offsetX = currentX + (charWidth - textPainter.width) / 2;
          textPainter.paint(canvas, Offset(offsetX, currentY));
          
          currentY += charHeight + lineSpacing;
        }
      }
      
      // 段落间距
      currentX -= paragraphSpacing;
    }
  }
  
  Size _measureChar(String char) {
    final textPainter = TextPainter(
      text: TextSpan(text: char, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return Size(textPainter.width, textPainter.height);
  }
  
  @override
  bool shouldRepaint(VerticalTextPainter oldDelegate) {
    return text != oldDelegate.text || textStyle != oldDelegate.textStyle;
  }
}