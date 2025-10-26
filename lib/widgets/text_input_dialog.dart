import 'package:flutter/material.dart';

class TextInputDialog extends StatelessWidget {
  final Function(String) onSubmit;

  const TextInputDialog({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return AlertDialog(
      title: const Text('输入要分析的句子'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '例如: This is a beautiful day.',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) {
              Navigator.pop(context);
              onSubmit(text);
            }
          },
          child: const Text('发送到AI'),
        ),
      ],
    );
  }
}