//字体选择对话框
import 'package:flutter/material.dart';
import '../models/reader_settings.dart';

class FontSizeSelector extends StatelessWidget {
  final FontSize currentFontSize;
  final Function(FontSize) onFontSizeChanged;

  const FontSizeSelector({
    super.key,
    required this.currentFontSize,
    required this.onFontSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择字体大小'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: FontSize.values.map((fontSize) {
          return RadioListTile<FontSize>(
            title: Text(fontSize.label),
            subtitle: Text(
              '示例文字',
              style: TextStyle(fontSize: fontSize.size),
            ),
            value: fontSize,
            groupValue: currentFontSize,
            onChanged: (value) {
              if (value != null) {
                onFontSizeChanged(value);
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}