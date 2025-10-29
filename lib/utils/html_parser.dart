class HtmlParser {
  static ParsedContent extractContentWithLinks(String html) {
    String text = html;
    List<LinkInfo> links = [];
    List<EpubImageInfo> images = [];
    
    // 先移除head, style, script标签
    text = text.replaceAll(RegExp(r'<head>.*?</head>', dotAll: true), '');
    text = text.replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '');
    text = text.replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '');
    
  // *** 增强检测：判断是否为纯目录页面 ***
  final aTagCount = RegExp(r'<a\s+[^>]*href[^>]*>').allMatches(text).length;
  final textLength = text.replaceAll(RegExp(r'<[^>]*>'), '').trim().length;
  // 如果链接数量 > 5 且文本很少（链接占比高），才判定为目录
  final isTableOfContents = aTagCount > 5 && textLength < 500;
    
    // 手动提取<a>标签
    int pos = 0;
    while (pos < text.length) {
      final aTagStart = text.indexOf('<a ', pos);
      if (aTagStart == -1) break;
      
      final aTagEnd = text.indexOf('>', aTagStart);
      if (aTagEnd == -1) break;
      
      final closeTag = text.indexOf('</a>', aTagEnd);
      if (closeTag == -1) break;
      
      final tagContent = text.substring(aTagStart, aTagEnd + 1);
      final linkText = text.substring(aTagEnd + 1, closeTag);
      
      // 提取href
      final hrefPos = tagContent.indexOf('href');
      if (hrefPos != -1) {
        final quotePos1 = tagContent.indexOf('"', hrefPos);
        final quotePos2 = tagContent.indexOf("'", hrefPos);
        
        int quoteStart = -1;
        String quote = '"';
        
        if (quotePos1 != -1 && (quotePos2 == -1 || quotePos1 < quotePos2)) {
          quoteStart = quotePos1;
          quote = '"';
        } else if (quotePos2 != -1) {
          quoteStart = quotePos2;
          quote = "'";
        }
        
        if (quoteStart != -1) {
          final quoteEnd = tagContent.indexOf(quote, quoteStart + 1);
          if (quoteEnd != -1) {
            final url = tagContent.substring(quoteStart + 1, quoteEnd);
            if (url.isNotEmpty && linkText.trim().isNotEmpty) {
              links.add(LinkInfo(
                text: linkText,
                url: url,
                startIndex: 0,
                endIndex: 0,
              ));
            }
          }
        }
      }
      
      pos = closeTag + 4;
    }
    
    // 提取图片
    pos = 0;
    while (pos < text.length) {
      final imgStart = text.toLowerCase().indexOf('<img', pos);
      if (imgStart == -1) break;
      
      final imgEnd = text.indexOf('>', imgStart);
      if (imgEnd == -1) break;
      
      final imgTag = text.substring(imgStart, imgEnd + 1);
      
      final srcPos = imgTag.toLowerCase().indexOf('src');
      if (srcPos != -1) {
        final quotePos1 = imgTag.indexOf('"', srcPos);
        final quotePos2 = imgTag.indexOf("'", srcPos);
        
        int quoteStart = -1;
        String quote = '"';
        
        if (quotePos1 != -1 && (quotePos2 == -1 || quotePos1 < quotePos2)) {
          quoteStart = quotePos1;
          quote = '"';
        } else if (quotePos2 != -1) {
          quoteStart = quotePos2;
          quote = "'";
        }
        
        if (quoteStart != -1) {
          final quoteEnd = imgTag.indexOf(quote, quoteStart + 1);
          if (quoteEnd != -1) {
            final src = imgTag.substring(quoteStart + 1, quoteEnd);
            if (src.isNotEmpty) {
              images.add(EpubImageInfo(src: src, position: imgStart));
            }
          }
        }
      }
      
      pos = imgEnd + 1;
    }
    
    // 处理上标标签
    pos = 0;
    while (pos < text.length) {
      final supStart = text.toLowerCase().indexOf('<sup', pos);
      if (supStart == -1) break;
      
      final supEnd = text.indexOf('>', supStart);
      if (supEnd == -1) break;
      
      final closeSupStart = text.toLowerCase().indexOf('</sup>', supEnd);
      if (closeSupStart == -1) break;
      
      final content = text.substring(supEnd + 1, closeSupStart);
      final replacement = _toSuperscript(content);
      
      text = text.substring(0, supStart) + replacement + text.substring(closeSupStart + 6);
      pos = supStart + replacement.length;
    }
    
    // 处理下标标签
    pos = 0;
    while (pos < text.length) {
      final subStart = text.toLowerCase().indexOf('<sub', pos);
      if (subStart == -1) break;
      
      final subEnd = text.indexOf('>', subStart);
      if (subEnd == -1) break;
      
      final closeSubStart = text.toLowerCase().indexOf('</sub>', subEnd);
      if (closeSubStart == -1) break;
      
      final content = text.substring(subEnd + 1, closeSubStart);
      final replacement = _toSubscript(content);
      
      text = text.substring(0, subStart) + replacement + text.substring(closeSubStart + 6);
      pos = subStart + replacement.length;
    }
    
    // 替换图片标签
    text = text.replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '[图片]');
    
    // *** 问题2修复：只在目录页面时给</a>添加换行 ***
    if (isTableOfContents) {
      text = text.replaceAll(RegExp(r'</a>', caseSensitive: false), '</a>\n');
    }
    
    // 将块级元素替换为换行
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');
    
    // 移除所有HTML标签
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // 解码所有HTML实体
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&#x00A0;', ' ');
    text = text.replaceAll('&#160;', ' ');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&#x27;', "'");
    
    // 清理空白
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    
    // 调整链接位置
    final adjustedLinks = <LinkInfo>[];
    for (var link in links) {
      var cleanText = link.text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      final index = text.indexOf(cleanText);
      if (index != -1) {
        adjustedLinks.add(LinkInfo(
          text: cleanText,
          url: link.url,
          startIndex: index,
          endIndex: index + cleanText.length,
        ));
      }
    }
    
    return ParsedContent(
      text: text.trim(),
      links: adjustedLinks,
      images: images,
    );
  }
  
  static String _toSuperscript(String text) {
    const map = {
      '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
      '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
      '+': '⁺', '-': '⁻', '=': '⁼', '(': '⁽', ')': '⁾',
    };
    return text.split('').map((c) => map[c] ?? c).join();
  }
  
  static String _toSubscript(String text) {
    const map = {
      '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
      '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉',
      '+': '₊', '-': '₋', '=': '₌', '(': '₍', ')': '₎',
    };
    return text.split('').map((c) => map[c] ?? c).join();
  }
  
  static String extractTextFromHtml(String html) {
    return extractContentWithLinks(html).text;
  }
  
  static bool hasValidContent(String html) {
    final textOnly = extractTextFromHtml(html)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return textOnly.length > 10;
  }
}

class ParsedContent {
  final String text;
  final List<LinkInfo> links;
  final List<EpubImageInfo> images;
  
  ParsedContent({
    required this.text,
    required this.links,
    this.images = const [],
  });
}

class LinkInfo {
  final String text;
  final String url;
  final int startIndex;
  final int endIndex;

  LinkInfo({
    required this.text,
    required this.url,
    required this.startIndex,
    required this.endIndex,
  });
}

class EpubImageInfo {
  final String src;
  final int position;
  
  EpubImageInfo({
    required this.src,
    required this.position,
  });
}