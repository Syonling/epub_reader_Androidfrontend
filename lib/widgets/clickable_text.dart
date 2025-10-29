//可点击文本组件
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/html_parser.dart';

class ClickableText extends StatelessWidget {
  final String text;
  final List<LinkInfo> links;
  final TextStyle textStyle;
  final Function(String)? onLinkTap;
  final Function(String)? onTextSelected;

  const ClickableText({
    super.key,
    required this.text,
    required this.links,
    required this.textStyle,
    this.onLinkTap,
    this.onTextSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) {
      return SelectableText(
        text,
        style: textStyle,
        onSelectionChanged: (selection, cause) {
          if (selection.start != selection.end && onTextSelected != null) {
            onTextSelected!(text.substring(selection.start, selection.end));
          }
        },
      );
    }

    return SelectableText.rich(
      TextSpan(
        children: _buildTextSpans(),
      ),
      onSelectionChanged: (selection, cause) {
        if (selection.start != selection.end && onTextSelected != null) {
          onTextSelected!(text.substring(selection.start, selection.end));
        }
      },
    );
  }

  List<InlineSpan> _buildTextSpans() {
    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    // 按位置排序链接
    final sortedLinks = List<LinkInfo>.from(links)
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    for (var link in sortedLinks) {
      // 确保索引有效
      if (link.startIndex < 0 || link.endIndex > text.length) continue;
      
      // 添加链接前的普通文本
      if (link.startIndex > lastIndex) {
        final normalText = text.substring(lastIndex, link.startIndex);
        if (normalText.isNotEmpty) {
          spans.add(TextSpan(
            text: normalText,
            style: textStyle,
          ));
        }
      }

      // 添加链接文本
      spans.add(TextSpan(
        text: link.text,
        style: textStyle.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            onLinkTap?.call(link.url);
          },
      ));

      lastIndex = link.endIndex;
    }

    // 添加最后的普通文本
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: textStyle,
      ));
    }

    return spans;
  }
}