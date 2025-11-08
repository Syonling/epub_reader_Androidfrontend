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
        - 100; // 底部padding + 翻页按钮
    
    return availableHeight;
  }
  
  // 改进的分页算法：使用二分查找优化性能
  static List<String> paginateByHeight(
    String text, 
    double availableHeight,
    TextStyle textStyle,
    double pageWidth,
  ) {
    if (text.isEmpty) return [''];
    
    List<String> pages = [];
    int startIndex = 0;
    
    while (startIndex < text.length) {
      // 使用二分查找找到最大可容纳的字符数
      int endIndex = _findMaxFitIndex(
        text,
        startIndex,
        availableHeight,
        textStyle,
        pageWidth,
      );
      
      // 如果没有进展，至少要添加一个字符（防止死循环）
      if (endIndex <= startIndex) {
        endIndex = startIndex + 1;
      }
      
      // 尝试在合适的位置断开（避免在单词/句子中间）
      endIndex = _adjustBreakPoint(text, startIndex, endIndex);
      
      pages.add(text.substring(startIndex, endIndex));
      startIndex = endIndex;
    }
    
    print('=== 改进的分页结果 ===');
    print('总字符数: ${text.length}');
    print('总页数: ${pages.length}');
    print('可用高度: ${availableHeight.toStringAsFixed(0)}');
    print('平均每页字符数: ${text.length ~/ pages.length}');
    print('==================\n');
    
    return pages;
  }
  
  // 使用二分查找找到最大可容纳的字符索引
  static int _findMaxFitIndex(
    String text,
    int startIndex,
    double maxHeight,
    TextStyle textStyle,
    double maxWidth,
  ) {
    int left = startIndex + 1;  // 至少包含一个字符
    int right = text.length;
    int result = startIndex + 1;
    
    // 二分查找最大可容纳的字符数
    while (left <= right) {
      int mid = (left + right) ~/ 2;
      final substring = text.substring(startIndex, mid);
      final height = _calculateTextHeight(substring, textStyle, maxWidth);
      
      if (height <= maxHeight) {
        result = mid;
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }
    
    return result;
  }
  
  // 调整断点位置，优先在段落、句子、词语边界断开
  static int _adjustBreakPoint(String text, int start, int end) {
    if (end >= text.length) return end;
    if (end <= start + 1) return end;
    
    final searchRange = 50; // 向前搜索的字符数
    final searchStart = (end - searchRange).clamp(start, end);
    
    // 优先级1: 段落边界（换行符）
    for (int i = end - 1; i >= searchStart; i--) {
      if (text[i] == '\n') {
        return i + 1;
      }
    }
    
    // 优先级2: 句子结束标点
    const sentenceEnds = ['。', '！', '？', '．', '.', '!', '?'];
    for (int i = end - 1; i >= searchStart; i--) {
      if (sentenceEnds.contains(text[i])) {
        // 确保标点后面不是引号或括号
        if (i + 1 < text.length) {
          final nextChar = text[i + 1];
          if (nextChar == '"' || nextChar == '」' || nextChar == '』' || 
              nextChar == ')' || nextChar == '）') {
            return i + 2;
          }
        }
        return i + 1;
      }
    }
    
    // 优先级3: 逗号、顿号等次要标点
    const punctuations = ['、', '，', ',', '；', ';', '：', ':'];
    for (int i = end - 1; i >= (end - 30).clamp(start, end); i--) {
      if (punctuations.contains(text[i])) {
        return i + 1;
      }
    }
    
    // 优先级4: 空格（主要用于英文）
    for (int i = end - 1; i >= (end - 20).clamp(start, end); i--) {
      if (text[i] == ' ') {
        return i + 1;
      }
    }
    
    // 如果都没有找到合适的断点，就在原位置断开
    return end;
  }
  
  // 计算文本实际渲染高度
  static double _calculateTextHeight(
    String text,
    TextStyle style,
    double maxWidth,
  ) {
    if (text.isEmpty) return 0;
    
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    
    textPainter.layout(maxWidth: maxWidth);
    
    return textPainter.height;
  }
}