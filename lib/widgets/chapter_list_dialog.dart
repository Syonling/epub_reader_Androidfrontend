//目录对话框组件
import 'package:flutter/material.dart';

class ChapterListDialog extends StatelessWidget {
  final List<String> chapterTitles;
  final List<int> chapterPageCounts;
  final int currentChapterIndex;
  final Function(int) onChapterSelected;

  const ChapterListDialog({
    super.key,
    required this.chapterTitles,
    required this.chapterPageCounts,
    required this.currentChapterIndex,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('目录'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: chapterTitles.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Text('${index + 1}'),
              title: Text(
                chapterTitles[index],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${chapterPageCounts[index]} 页'),
              selected: index == currentChapterIndex,
              selectedTileColor: Colors.blue.withValues(alpha: 0.1),
              onTap: () {
                onChapterSelected(index);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}