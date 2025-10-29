//阅读器设置模型
enum FontSize {
  small(16.0, '小'),
  medium(20.0, '中'),
  large(24.0, '大');

  final double size;
  final String label;
  
  const FontSize(this.size, this.label);
}

class ReaderSettings {
  final FontSize fontSize;
  final bool showAppBar;
  
  ReaderSettings({
    this.fontSize = FontSize.medium,
    this.showAppBar = true,
  });
  
  ReaderSettings copyWith({
    FontSize? fontSize,
    bool? showAppBar,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      showAppBar: showAppBar ?? this.showAppBar,
    );
  }
}