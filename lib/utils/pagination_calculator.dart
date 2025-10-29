import 'package:flutter/material.dart';

class PaginationCalculator {
  // 计算可用的页面高度
  static double calculateAvailableHeight(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    
    // 可用高度：减去各种UI元素
    final availableHeight = size.height 
        - padding.top  // 状态栏
        - (kToolbarHeight)  // AppBar
        - 80  // 顶部padding
        - 180; // 底部padding + 翻页按钮
    
    return availableHeight;
  }
  
  // 基于实际渲染高度来分页（支持段落内断行）
  static List<String> paginateByHeight(
    String text, 
    double availableHeight,
    TextStyle textStyle,
    double pageWidth,
  ) {
    if (text.isEmpty) return [''];
    
    final paragraphs = text.split('\n');
    List<String> pages = [];
    List<String> currentPageLines = [];
    double currentPageHeight = 0;
    
    for (var paragraph in paragraphs) {
      if (paragraph.isEmpty) {
        // 空行处理
        const emptyLineHeight = 16.0;
        if (currentPageHeight + emptyLineHeight > availableHeight && currentPageLines.isNotEmpty) {
          pages.add(currentPageLines.join('\n'));
          currentPageLines = [];
          currentPageHeight = 0;
        }
        currentPageLines.add('');
        currentPageHeight += emptyLineHeight;
        continue;
      }
      
      // 计算整段落的高度
      final fullParagraphHeight = _calculateTextHeight(paragraph, textStyle, pageWidth);
      
      // 如果整段落能放进当前页，直接添加
      if (currentPageHeight + fullParagraphHeight <= availableHeight) {
        currentPageLines.add(paragraph);
        currentPageHeight += fullParagraphHeight;
      } else {
        // 段落太长，需要智能拆分
        final splitResult = _splitParagraphIntelligently(
          paragraph,
          availableHeight - currentPageHeight,
          availableHeight,
          textStyle,
          pageWidth,
        );
        
        for (int i = 0; i < splitResult.length; i++) {
          final part = splitResult[i];
          if (part.isEmpty) continue;
          
          final partHeight = _calculateTextHeight(part, textStyle, pageWidth);
          
          // 如果当前页已经有内容且放不下这部分，开始新页
          if (currentPageLines.isNotEmpty && currentPageHeight + partHeight > availableHeight) {
            pages.add(currentPageLines.join('\n'));
            currentPageLines = [];
            currentPageHeight = 0;
          }
          
          currentPageLines.add(part);
          currentPageHeight += partHeight;
        }
      }
    }
    
    // 添加最后一页
    if (currentPageLines.isNotEmpty) {
      pages.add(currentPageLines.join('\n'));
    }
    
    print('=== 分页结果 ===');
    print('总段落数: ${paragraphs.length}');
    print('总页数: ${pages.length}');
    print('可用高度: ${availableHeight.toStringAsFixed(0)}');
    print('===============\n');
    
    return pages.isEmpty ? [''] : pages;
  }
  
  // 智能拆分段落，避免孤字和孤标点
  static List<String> _splitParagraphIntelligently(
    String paragraph,
    double remainingHeight,
    double pageHeight,
    TextStyle textStyle,
    double pageWidth,
  ) {
    List<String> parts = [];
    String remaining = paragraph;
    double availableHeight = remainingHeight;
    
    while (remaining.isNotEmpty) {
      // 如果剩余高度太小，直接换页
      if (availableHeight < pageHeight * 0.15) {
        availableHeight = pageHeight;
      }
      
      // 二分查找最佳断点
      int left = 1;
      int right = remaining.length;
      int bestSplit = 0;
      
      while (left <= right) {
        int mid = (left + right) ~/ 2;
        String testText = remaining.substring(0, mid);
        double testHeight = _calculateTextHeight(testText, textStyle, pageWidth);
        
        if (testHeight <= availableHeight) {
          bestSplit = mid;
          left = mid + 1;
        } else {
          right = mid - 1;
        }
      }
      
      // 如果找不到合适的断点，至少拆分一个字符
      if (bestSplit == 0) {
        bestSplit = 1;
      }
      
      // 调整断点，避免孤字和孤标点
      bestSplit = _adjustSplitPoint(remaining, bestSplit);
      
      // 拆分文本
      String currentPart = remaining.substring(0, bestSplit).trim();
      remaining = remaining.substring(bestSplit).trim();
      
      if (currentPart.isNotEmpty) {
        parts.add(currentPart);
      }
      
      // 下一页有完整高度
      availableHeight = pageHeight;
    }
    
    return parts;
  }
  
  // 调整拆分点，避免孤字和孤标点
  static int _adjustSplitPoint(String text, int initialSplit) {
    if (initialSplit >= text.length) {
      return text.length;
    }
    
    // 避免在最后只留下1-2个字符
    if (text.length - initialSplit <= 2) {
      // 向前调整，至少保留3个字符到下一页
      int newSplit = text.length - 3;
      if (newSplit > 0 && newSplit < initialSplit) {
        return newSplit;
      }
    }
    
    // 避免在断点处只切下1-2个字符
    if (initialSplit <= 2) {
      // 如果前面只有1-2个字符，尝试多拿一些
      int newSplit = 3.clamp(0, text.length);
      if (newSplit > initialSplit) {
        return newSplit;
      }
    }
    
    // 尝试在标点符号处断开（更自然）
    final punctuations = ['。', '！', '？', '；', '…', ')', '）', '"', '"', '」'];
    
    // 在附近查找标点（前后10个字符范围内）
    int searchStart = (initialSplit - 10).clamp(0, text.length);
    int searchEnd = (initialSplit + 10).clamp(0, text.length);
    
    for (int i = initialSplit; i < searchEnd; i++) {
      if (punctuations.contains(text[i])) {
        // 确保断点后还有足够的内容
        if (text.length - (i + 1) >= 3) {
          return i + 1;
        }
      }
    }
    
    for (int i = initialSplit - 1; i >= searchStart; i--) {
      if (punctuations.contains(text[i])) {
        // 确保断点后还有足够的内容
        if (text.length - (i + 1) >= 3) {
          return i + 1;
        }
      }
    }
    
    return initialSplit;
  }
  
  // 计算文本实际渲染高度
  static double _calculateTextHeight(
    String text,
    TextStyle style,
    double maxWidth,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    
    textPainter.layout(maxWidth: maxWidth);
    
    // 段落之间的间距
    const paragraphSpacing = 16.0;
    
    return textPainter.height + paragraphSpacing;
  }
}