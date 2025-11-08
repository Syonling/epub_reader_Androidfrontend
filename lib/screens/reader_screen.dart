import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:webview_flutter/webview_flutter.dart';
import '../models/book.dart';
import '../models/reader_settings.dart';
import '../services/epub_service.dart';
import '../services/api_service.dart';
import '../utils/html_parser.dart';
import '../utils/pagination_calculator.dart';
import '../widgets/result_dialog.dart';
import '../widgets/chapter_list_dialog.dart';
import '../widgets/font_size_selector.dart';
import '../widgets/clickable_text.dart';
import 'dart:typed_data';

class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  epubx.EpubBook? _epubBook;
  bool _isLoading = true;
  int _currentChapterIndex = 0;
  int _currentPageIndex = 0;
  List<String> _chapterContents = [];
  List<String> _chapterTitles = [];
  List<String> _chapterFileNames = [];
  List<List<String>> _chapterPages = [];
  List<List<LinkInfo>> _chapterLinks = [];
  List<List<EpubImageInfo>> _chapterImages = [];
  String _selectedText = '';
  ReaderSettings _settings = ReaderSettings();
  bool _isVerticalText = false; // 当前章节是否为竖排
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final book = await EpubService.loadEpubFromAsset(widget.book.filePath);
      
      List<String> contents = [];
      List<String> titles = [];
      List<String> fileNames = [];
      
      if (book.Content?.Html != null) {
        for (var entry in book.Content!.Html!.entries) {
          try {
            final htmlContent = entry.value;
            final content = htmlContent.Content;
            
            if (content != null && HtmlParser.hasValidContent(content)) {
              contents.add(content);
              fileNames.add(entry.key);
              titles.add(_extractTitleFromHtml(content, entry.key));
            }
          } catch (e) {
            print('跳过文件: ${entry.key}');
          }
        }
      }
      
      if (contents.isEmpty && book.Chapters != null) {
        _extractChapterContents(book.Chapters!, contents, titles, fileNames);
      }
      
      print('========== 章节加载信息 ==========');
      print('总章节数: ${contents.length}');
      for (int i = 0; i < titles.length && i < 5; i++) {
        print('章节 $i: ${titles[i]} (${fileNames[i]})');
      }
      print('==================================\n');
      
      // 检测第一章是否为竖排文本
      bool isVertical = false;
      if (contents.isNotEmpty) {
        isVertical = EpubService.isVerticalHtml(contents[0]);
      }
      
      setState(() {
        _epubBook = book;
        _chapterContents = contents;
        _chapterTitles = titles;
        _chapterFileNames = fileNames;
        _isVerticalText = isVertical;
        _isLoading = false;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recalculatePages();
      });
    } catch (e) {
      print('加载书籍失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _extractTitleFromHtml(String html, String fileName) {
    // 先尝试提取 h1-h4 标签
    for (var tag in ['h1', 'h2', 'h3', 'h4']) {
      final headerMatch = RegExp('<$tag[^>]*>(.*?)</$tag>', caseSensitive: false, dotAll: true).firstMatch(html);
      if (headerMatch != null) {
        String title = headerMatch.group(1)!
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll('&#x00A0;', ' ')
            .trim();
        
        // 过滤掉书名
        if (title.isNotEmpty && !title.contains(widget.book.title)) {
          return title;
        }
      }
    }
    
    // 备用：尝试 <title> 标签
    final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true).firstMatch(html);
    if (titleMatch != null) {
      String title = titleMatch.group(1)!
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&#x00A0;', ' ')
          .trim();
      
      if (title.isNotEmpty && !title.contains(widget.book.title)) {
        return title;
      }
    }
    
    return _cleanFileName(fileName);
  }

  String _cleanFileName(String filename) {
    String cleaned = filename
        .split('/')
        .last
        .replaceAll('.html', '')
        .replaceAll('.xhtml', '')
        .replaceAll('.htm', '');
    
    if (RegExp(r'^(Part|Section|index_split|chapter)\d+$', caseSensitive: false).hasMatch(cleaned)) {
      return '章节 ${_chapterTitles.length + 1}';
    }
    
    return cleaned
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
  }

  void _extractChapterContents(List<epubx.EpubChapter> chapters, List<String> contents, List<String> titles, List<String> fileNames) {
    for (var chapter in chapters) {
      if (chapter.HtmlContent != null && chapter.HtmlContent!.isNotEmpty) {
        if (HtmlParser.hasValidContent(chapter.HtmlContent!)) {
          contents.add(chapter.HtmlContent!);
          titles.add(chapter.Title ?? '章节 ${contents.length}');
          fileNames.add(chapter.Anchor ?? '');
        }
      }
      if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
        _extractChapterContents(chapter.SubChapters!, contents, titles, fileNames);
      }
    }
  }

  void _recalculatePages() {
    if (!mounted || _chapterContents.isEmpty) return;
    
    final size = MediaQuery.of(context).size;
    final availableHeight = PaginationCalculator.calculateAvailableHeight(context);
    final availableWidth = size.width - 48;
    
    final textStyle = TextStyle(
      fontSize: _settings.fontSize.size,
      height: 1.8,
    );
    
    List<List<String>> allPages = [];
    List<List<LinkInfo>> allLinks = [];
    List<List<EpubImageInfo>> allImages = [];
    
    for (var content in _chapterContents) {
      final parsed = HtmlParser.extractContentWithLinks(content);
      
      final pages = PaginationCalculator.paginateByHeight(
        parsed.text,
        availableHeight,
        textStyle,
        availableWidth,
      );
      
      allPages.add(pages);
      allLinks.add(parsed.links);
      allImages.add(parsed.images);
    }
    
    setState(() {
      _chapterPages = allPages;
      _chapterLinks = allLinks;
      _chapterImages = allImages;
    });
  }

  void _changeFontSize(FontSize newFontSize) {
    setState(() {
      _settings = _settings.copyWith(fontSize: newFontSize);
    });
    _recalculatePages();
  }

  void _handleLinkTap(String url) {
    print('========= 点击链接 =========');
    print('URL: $url');
    print('当前章节: $_currentChapterIndex');
    
    if (url.startsWith('#')) {
      final anchor = url.substring(1);
      print('注脚跳转尝试: #$anchor');
      
      for (int i = 0; i < _chapterContents.length; i++) {
        if (_chapterContents[i].contains('id="$anchor"') || 
            _chapterContents[i].contains("id='$anchor'")) {
          print('找到注脚章节: $i');
          
          setState(() {
            _currentChapterIndex = i;
            _currentPageIndex = 0;
            _selectedText = '';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已跳转到注脚章节'),
              duration: const Duration(seconds: 2),
            ),
          );
          print('========================\n');
          return;
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('注脚 #$anchor (章节内定位暂不支持)'),
          duration: const Duration(seconds: 2),
        ),
      );
      print('========================\n');
      return;
    }
    
    if (url.contains('#')) {
      final parts = url.split('#');
      final fileName = parts[0];
      final anchor = parts.length > 1 ? parts[1] : '';
      
      print('文件名: $fileName, 锚点: $anchor');
      
      int? targetChapter;
      for (int i = 0; i < _chapterFileNames.length; i++) {
        final chapterFileName = _chapterFileNames[i].split('/').last;
        final searchFileName = fileName.split('/').last;
        
        if (chapterFileName == searchFileName ||
            chapterFileName.replaceAll('.xhtml', '').replaceAll('.html', '') == 
            searchFileName.replaceAll('.xhtml', '').replaceAll('.html', '')) {
          targetChapter = i;
          print('✓ 找到匹配章节: $i (${_chapterTitles[i]})');
          break;
        }
      }
      
      if (targetChapter != null) {
        setState(() {
          _currentChapterIndex = targetChapter!;
          _currentPageIndex = 0;
          _selectedText = '';
          // 更新竖排检测
          if (targetChapter < _chapterContents.length) {
            _isVerticalText = EpubService.isVerticalHtml(_chapterContents[targetChapter]);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已跳转到: ${_chapterTitles[targetChapter]}'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print('✗ 未找到章节');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('未找到章节: $fileName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      print('========================\n');
      return;
    }
    
    if (url.endsWith('.html') || url.endsWith('.xhtml')) {
      final fileName = url.split('/').last;
      print('普通章节链接: $fileName');
      
      int? targetChapter;
      for (int i = 0; i < _chapterFileNames.length; i++) {
        if (_chapterFileNames[i].contains(fileName)) {
          targetChapter = i;
          break;
        }
      }
      
      if (targetChapter != null && targetChapter != _currentChapterIndex) {
        setState(() {
          _currentChapterIndex = targetChapter!;
          _currentPageIndex = 0;
          _selectedText = '';
          // 更新竖排检测
          if (targetChapter < _chapterContents.length) {
            _isVerticalText = EpubService.isVerticalHtml(_chapterContents[targetChapter]);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已跳转到: ${_chapterTitles[targetChapter]}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
    
    print('========================\n');
  }

  Future<void> _sendToBackend() async {
    if (!mounted || _selectedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要分析的文本')),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await ApiService.analyzeText(_selectedText);
    
    if (!mounted) return;
    Navigator.pop(context);

    if (result != null) {
      showDialog(
        context: context,
        builder: (context) => ResultDialog(result: result),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('分析失败,请检查网络连接')),
      );
    }
  }

  void _toggleAppBar() {
    setState(() {
      _settings = _settings.copyWith(showAppBar: !_settings.showAppBar);
    });
  }

  void _nextPage() {
    if (_chapterPages.isEmpty) return;
    
    final currentChapterPages = _chapterPages[_currentChapterIndex];
    
    if (_currentPageIndex < currentChapterPages.length - 1) {
      setState(() {
        _currentPageIndex++;
      });
    } else if (_currentChapterIndex < _chapterPages.length - 1) {
      setState(() {
        _currentChapterIndex++;
        _currentPageIndex = 0;
        _selectedText = '';
        // 更新竖排检测
        if (_currentChapterIndex < _chapterContents.length) {
          _isVerticalText = EpubService.isVerticalHtml(_chapterContents[_currentChapterIndex]);
        }
      });
    }
  }

  void _previousPage() {
    if (_chapterPages.isEmpty) return;
    
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
      });
    } else if (_currentChapterIndex > 0) {
      setState(() {
        _currentChapterIndex--;
        _currentPageIndex = _chapterPages[_currentChapterIndex].length - 1;
        _selectedText = '';
        // 更新竖排检测
        if (_currentChapterIndex < _chapterContents.length) {
          _isVerticalText = EpubService.isVerticalHtml(_chapterContents[_currentChapterIndex]);
        }
      });
    }
  }

  void _showChapterList() {
    showDialog(
      context: context,
      builder: (context) => ChapterListDialog(
        chapterTitles: _chapterTitles,
        chapterPageCounts: _chapterPages.map((pages) => pages.length).toList(),
        currentChapterIndex: _currentChapterIndex,
        onChapterSelected: (index) {
          setState(() {
            _currentChapterIndex = index;
            _currentPageIndex = 0;
            _selectedText = '';
            // 更新竖排检测
            if (index < _chapterContents.length) {
              _isVerticalText = EpubService.isVerticalHtml(_chapterContents[index]);
            }
          });
        },
      ),
    );
  }

  void _showFontSizeSelector() {
    showDialog(
      context: context,
      builder: (context) => FontSizeSelector(
        currentFontSize: _settings.fontSize,
        onFontSizeChanged: _changeFontSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _settings.showAppBar ? AppBar(
        title: Text(widget.book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: _showFontSizeSelector,
            tooltip: '字体大小',
          ),
          if (_chapterContents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: _showChapterList,
              tooltip: '目录',
            ),
        ],
      ) : null,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _epubBook == null
                  ? const Center(child: Text('无法加载书籍'))
                  : _buildReader(),
          _buildFloatingButtons(),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    if (_chapterContents.isEmpty || _chapterPages.isEmpty) return const SizedBox.shrink();
    
    final currentChapterPages = _chapterPages[_currentChapterIndex];
    final totalPagesInChapter = currentChapterPages.length;
    
    return Positioned(
      right: 16,
      bottom: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_selectedText.isNotEmpty) ...[
            FloatingActionButton(
              heroTag: 'analyze',
              onPressed: _sendToBackend,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.analytics),
            ),
            const SizedBox(height: 8),
          ],
          // FloatingActionButton.extended(
          //   heroTag: 'page',
          //   onPressed: _showChapterList,
          //   label: Text(
          //     '第${_currentChapterIndex + 1}章 '
          //     '${_currentPageIndex + 1}/$totalPagesInChapter页'
          //   ),
          //   icon: const Icon(Icons.menu_book),
          // ),
        ],
      ),
    );
  }

  Widget _buildReader() {
    if (_chapterContents.isEmpty || _chapterPages.isEmpty) {
      return const Center(
        child: Text('没有可显示的章节'),
      );
    }

    final currentPage = _chapterPages[_currentChapterIndex][_currentPageIndex];
    final currentChapterLinks = _chapterLinks.isNotEmpty && _currentChapterIndex < _chapterLinks.length
        ? _chapterLinks[_currentChapterIndex]
        : <LinkInfo>[];
    final currentChapterImages = _chapterImages.isNotEmpty && _currentChapterIndex < _chapterImages.length
        ? _chapterImages[_currentChapterIndex]
        : <EpubImageInfo>[];

    return GestureDetector(
      onTap: _toggleAppBar,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _previousPage();
        } else if (details.primaryVelocity! < 0) {
          _nextPage();
        }
      },
      child: _isVerticalText 
          ? _buildVerticalWebView(currentPage)
          : _buildHorizontalContent(currentPage, currentChapterLinks, currentChapterImages),
    );
  }

  Widget _buildHorizontalContent(String currentPage, List<LinkInfo> links, List<EpubImageInfo> images) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 24, 
        vertical: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageContentWithInlineImages(currentPage, links, images),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _currentPageIndex > 0 || _currentChapterIndex > 0
                      ? _previousPage
                      : null,
                  icon: const Icon(Icons.arrow_back, size: 30),
                  label: const Text(
                    '上一页',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                Text(
                  '${_currentPageIndex + 1} / ${_chapterPages[_currentChapterIndex].length}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                TextButton.icon(
                  onPressed: _currentPageIndex < _chapterPages[_currentChapterIndex].length - 1 ||
                          _currentChapterIndex < _chapterPages.length - 1
                      ? _nextPage
                      : null,
                  icon: const Icon(Icons.arrow_forward, size: 30),
                  label: const Text(
                    '下一页',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalWebView(String currentPage) {
    // 为竖排文本构建完整的HTML，添加文本选择支持
    final injectedHtml = '''
<!doctype html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover"/>
<style>
  html, body { 
    margin: 0; 
    padding: 20px; 
    background: #fff;
    height: 100%;
    overflow: auto;
    user-select: text;
    -webkit-user-select: text;
  }
  body { 
    writing-mode: vertical-rl; 
    -webkit-writing-mode: vertical-rl;
    font-size: ${_settings.fontSize.size}px;
    line-height: 1.8;
  }
  img { 
    max-width: 100%; 
    height: auto; 
  }
  ruby rt { 
    font-size: 0.6em; 
  }
  p {
    margin: 0 1em;
  }
  ::selection {
    background: #b3d4fc;
  }
</style>
<script>
  // 监听文本选择
  document.addEventListener('selectionchange', function() {
    const selection = window.getSelection();
    const selectedText = selection.toString().trim();
    if (selectedText.length > 0) {
      // 通过JavaScriptChannel发送选中的文本到Flutter
      if (window.TextSelection) {
        window.TextSelection.postMessage(selectedText);
      }
    }
  });
</script>
</head>
<body>
$currentPage
</body>
</html>''';

    _webViewController ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'TextSelection',
        onMessageReceived: (JavaScriptMessage message) {
          // 接收WebView中选中的文本
          setState(() {
            _selectedText = message.message;
          });
          print('WebView选中文本: ${message.message}');
        },
      );

    _webViewController!.loadHtmlString(injectedHtml);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: WebViewWidget(controller: _webViewController!),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _currentPageIndex > 0 || _currentChapterIndex > 0
                      ? _previousPage
                      : null,
                  icon: const Icon(Icons.arrow_back, size: 30),
                  label: const Text(
                    '前頁',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                Text(
                  '${_currentPageIndex + 1} / ${_chapterPages[_currentChapterIndex].length}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                TextButton.icon(
                  onPressed: _currentPageIndex < _chapterPages[_currentChapterIndex].length - 1 ||
                          _currentChapterIndex < _chapterPages.length - 1
                      ? _nextPage
                      : null,
                  icon: const Icon(Icons.arrow_forward, size: 30),
                  label: const Text(
                    '次頁',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // *** 问题3修复：限制图片高度，避免遮挡文字 ***
  Widget _buildPageContentWithInlineImages(String text, List<LinkInfo> links, List<EpubImageInfo> images) {
    final widgets = <Widget>[];
    
    if (!text.contains('[图片]') || images.isEmpty) {
      widgets.add(_buildPageContent(text, links));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      );
    }
    
    int imageOffset = 0;
    for (int pageIdx = 0; pageIdx < _currentPageIndex; pageIdx++) {
      final prevPage = _chapterPages[_currentChapterIndex][pageIdx];
      imageOffset += '[图片]'.allMatches(prevPage).length;
    }
    
    final parts = text.split('[图片]');
    
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].trim().isNotEmpty) {
        widgets.add(_buildPageContent(parts[i], links));
      }
      
      if (i < parts.length - 1) {
        final actualImageIndex = imageOffset + i;
        
        if (actualImageIndex < images.length) {
          final imageWidget = _buildEpubImage(images[actualImageIndex].src);
          if (imageWidget != null) {
            widgets.add(
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                constraints: BoxConstraints(
                  maxHeight: 500, // 限制图片最大高度
                ),
                child: imageWidget,
              ),
            );
          }
        }
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildPageContent(String currentPage, List<LinkInfo> links) {
    if (links.isEmpty) {
      return SelectableText(
        currentPage,
        style: TextStyle(
          fontSize: _settings.fontSize.size,
          height: 1.8,
        ),
        onSelectionChanged: (selection, cause) {
          if (selection.start != selection.end) {
            setState(() {
              _selectedText = currentPage.substring(selection.start, selection.end);
            });
          }
        },
      );
    }
    
    final pageLinks = <LinkInfo>[];
    for (var link in links) {
      final index = currentPage.indexOf(link.text);
      if (index != -1) {
        pageLinks.add(LinkInfo(
          text: link.text,
          url: link.url,
          startIndex: index,
          endIndex: index + link.text.length,
        ));
      }
    }
    
    if (pageLinks.isEmpty) {
      return SelectableText(
        currentPage,
        style: TextStyle(
          fontSize: _settings.fontSize.size,
          height: 1.8,
        ),
        onSelectionChanged: (selection, cause) {
          if (selection.start != selection.end) {
            setState(() {
              _selectedText = currentPage.substring(selection.start, selection.end);
            });
          }
        },
      );
    }
    
    return ClickableText(
      text: currentPage,
      links: pageLinks,
      textStyle: TextStyle(
        fontSize: _settings.fontSize.size,
        height: 1.8,
      ),
      onLinkTap: _handleLinkTap,
      onTextSelected: (text) {
        setState(() {
          _selectedText = text;
        });
      },
    );
  }

  Widget? _buildEpubImage(String src) {
    try {
      final content = _epubBook?.Content;
      if (content == null || content.Images == null) return null;

      String? imageKey = src;
      
      if (content.Images![imageKey] == null) {
        imageKey = src.split('/').last;
      }
      
      if (content.Images![imageKey] == null) {
        for (var key in content.Images!.keys) {
          if (key.endsWith(src) || key.contains(src.split('/').last)) {
            imageKey = key;
            break;
          }
        }
      }
      
      final image = content.Images![imageKey];
      
      if (image != null && image.Content != null) {
        return Image.memory(
          Uint8List.fromList(image.Content!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Text('图片加载失败: $src'),
            );
          },
        );
      }
    } catch (e) {
      print('加载图片失败: $src, 错误: $e');
    }
    
    return null;
  }
}