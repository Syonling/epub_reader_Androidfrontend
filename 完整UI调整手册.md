# 📐 EPUB阅读器 - 完整UI调整参数手册

## 📁 文件位置
**主文件**: `lib/screens/reader_screen_with_toc.dart`

---

## 📖 一、正文阅读区域

### 1.1 正文文字
**位置**: 第 724、742、753 行（`_buildPageContent` 方法）

```dart
SelectableText(
  currentPage,
  style: TextStyle(
    fontSize: _settings.fontSize.size,  // ← 字体大小（由用户调整）
    height: 1.8,  // ← 行高（1.8倍行距）
  ),
)
```

**可调参数**:
- `fontSize`: 用户可通过字体调整按钮控制（小、中、大、特大）
- `height`: 行高倍数，推荐 1.5 - 2.0

---

### 1.2 正文边距
**位置**: 第 518 行

```dart
Container(
  color: Colors.white,
  padding: const EdgeInsets.symmetric(
    horizontal: 24,  // ← 左右边距
    vertical: 40,    // ← 上下边距
  ),
)
```

**可调参数**:
- `horizontal`: 左右留白，推荐 16-32
- `vertical`: 上下留白，推荐 30-50

---

### 1.3 正文底部留白（防止被按钮遮挡）
**位置**: 第 523 行

```dart
Expanded(
  child: Padding(
    padding: const EdgeInsets.only(bottom: 80),  // ← 底部留白
    child: SingleChildScrollView(
```

**可调参数**:
- `bottom`: 底部留白高度，推荐 60-120
- **作用**: 确保最后一行文字不被底部按钮栏遮挡

---

## 🖼️ 二、图片显示

### 2.1 图片最大高度
**位置**: 第 690 行（`_buildPageContentWithInlineImages` 方法）

```dart
Container(
  margin: const EdgeInsets.symmetric(vertical: 8),  // ← 图片上下间距
  constraints: BoxConstraints(
    maxHeight: 200,  // ← 图片最大高度（重要！）
  ),
  child: imageWidget,
),
```

**可调参数**:
- `maxHeight`: 图片最大显示高度，推荐 200-500
  - 200: 小图（节省空间）
  - 400: 中等（推荐）
  - 500+: 大图（可能遮挡文字）
- `vertical`: 图片上下间距，推荐 8-16

---

### 2.2 图片占位符高度（用于分页计算）
**位置**: `lib/utils/pagination_calculator.dart` 第 4-5 行

```dart
class PaginationCalculator {
  static const double imageHeight = 250.0;  // ← 图片占位高度
  static const double imageMargin = 24.0;   // ← 图片上下边距
```

**可调参数**:
- `imageHeight`: 分页时预留的图片空间
- `imageMargin`: 图片的上下边距总和
- ⚠️ **注意**: 应该与 2.1 的 `maxHeight` 保持接近

---

## 🎮 三、底部按钮栏

### 3.1 按钮栏整体边距
**位置**: 第 534 行

```dart
Padding(
  padding: const EdgeInsets.only(
    top: 16,     // ← 按钮栏距离内容的距离
    bottom: 0,   // ← 按钮栏距离屏幕底部的距离
  ),
  child: Row(
```

**可调参数**:
- `top`: 与正文的间距，推荐 12-24
- `bottom`: 与屏幕底部的间距，推荐 0-16

---

### 3.2 "上一页"按钮
**位置**: 第 539 行

```dart
TextButton.icon(
  onPressed: ...,
  icon: const Icon(
    Icons.arrow_back,
    size: 24,  // ← 图标大小（默认未设置）
  ),
  label: const Text(
    '上一页',
    style: TextStyle(fontSize: 14),  // ← 文字大小（默认未设置）
  ),
),
```

**可调参数**:
- `size`: 图标大小，推荐 18-24
- `fontSize`: 文字大小，推荐 12-16

---

### 3.3 页码显示
**位置**: 第 546 行

```dart
Text(
  '${_currentPageIndex + 1} / ${_chapterPages[_currentChapterIndex].length}',
  style: TextStyle(
    color: Colors.grey[600],
    fontSize: 14,  // ← 页码文字大小
  ),
),
```

**可调参数**:
- `fontSize`: 页码文字大小，推荐 12-16
- `color`: 文字颜色

---

### 3.4 "下一页"按钮
**位置**: 第 553 行

```dart
TextButton.icon(
  onPressed: ...,
  icon: const Icon(
    Icons.arrow_forward,
    size: 24,  // ← 图标大小（默认未设置）
  ),
  label: const Text(
    '下一页',
    style: TextStyle(fontSize: 14),  // ← 文字大小（默认未设置）
  ),
),
```

**可调参数**:
- `size`: 图标大小，推荐 18-24
- `fontSize`: 文字大小，推荐 12-16

---

## 🎯 四、右下角浮动按钮

### 4.1 浮动按钮位置
**位置**: 第 481 行（`_buildFloatingButtons` 方法）

```dart
Positioned(
  right: 16,   // ← 距离右边距离
  bottom: 80,  // ← 距离底部距离
  child: Column(
```

**可调参数**:
- `right`: 距离右边缘，推荐 12-24
- `bottom`: 距离底部，推荐 60-100
  - 注意：要在底部按钮栏上方

---

### 4.2 分析按钮（圆形按钮）
**位置**: 第 488 行

```dart
FloatingActionButton(
  heroTag: 'analyze',
  onPressed: _sendToBackend,
  backgroundColor: Colors.blue,
  mini: false,  // ← 可设为 true 变成小按钮
  child: const Icon(
    Icons.analytics,
    size: 24,  // ← 图标大小（默认未设置）
  ),
),
```

**可调参数**:
- `mini`: true = 小按钮，false = 正常按钮
- `size`: 图标大小，推荐 20-28

---

### 4.3 章节信息按钮（长条按钮）
**位置**: 第 496 行

```dart
FloatingActionButton.extended(
  heroTag: 'page',
  onPressed: _showChapterList,
  label: Text(
    '第${_currentChapterIndex + 1}章 '
    '${_currentPageIndex + 1}/$totalPagesInChapter页',
    style: TextStyle(fontSize: 14),  // ← 文字大小（默认未设置）
  ),
  icon: const Icon(
    Icons.menu_book,
    size: 20,  // ← 图标大小（默认未设置）
  ),
),
```

**可调参数**:
- `fontSize`: 文字大小，推荐 12-16
- `size`: 图标大小，推荐 18-24

---

### 4.4 两个浮动按钮之间的间距
**位置**: 第 494 行

```dart
const SizedBox(height: 8),  // ← 按钮间距
```

**可调参数**:
- `height`: 按钮间距，推荐 6-12

---

## 📱 五、顶部标题栏

### 5.1 标题栏
**位置**: 第 502 行

```dart
appBar: _settings.showAppBar ? AppBar(
  title: Text(
    widget.book.title,
    style: TextStyle(fontSize: 20),  // ← 标题文字大小（默认未设置）
  ),
  actions: [
```

**可调参数**:
- `fontSize`: 标题大小，推荐 18-22
- `elevation`: 阴影高度（默认4），推荐 0-8

---

### 5.2 标题栏按钮（字体/目录）
**位置**: 第 507、512 行

```dart
IconButton(
  icon: const Icon(
    Icons.text_fields,
    size: 24,  // ← 图标大小（默认未设置）
  ),
  onPressed: _showFontSizeSelector,
  tooltip: '字体大小',
),
```

**可调参数**:
- `size`: 图标大小，推荐 20-28

---

## 📋 六、目录弹窗（ChapterListDialog）

**文件**: `lib/widgets/chapter_list_dialog.dart`

### 6.1 弹窗大小
```dart
Dialog(
  child: Container(
    width: MediaQuery.of(context).size.width * 0.8,  // ← 宽度占屏幕80%
    height: MediaQuery.of(context).size.height * 0.7, // ← 高度占屏幕70%
```

**可调参数**:
- 宽度倍数: 推荐 0.7 - 0.9
- 高度倍数: 推荐 0.6 - 0.8

---

### 6.2 章节条目文字
```dart
ListTile(
  title: Text(
    chapterTitle,
    style: TextStyle(
      fontSize: 16,        // ← 章节名大小
      fontWeight: ...,
    ),
  ),
  subtitle: Text(
    '$pageCount 页',
    style: TextStyle(
      fontSize: 12,        // ← 页数提示大小
    ),
  ),
)
```

**可调参数**:
- 标题 `fontSize`: 推荐 14-18
- 副标题 `fontSize`: 推荐 11-14

---

## 🔤 七、字体选择器（FontSizeSelector）

**文件**: `lib/widgets/font_size_selector.dart`

### 7.1 预设字体大小
**文件**: `lib/models/reader_settings.dart`

```dart
enum FontSize {
  small(16.0),     // ← 小号字体
  medium(18.0),    // ← 中号字体
  large(20.0),     // ← 大号字体
  extraLarge(24.0); // ← 特大字体
```

**可调参数**:
- 修改这4个数值可改变字体档位
- 推荐范围: 14-28

---

## 📊 八、分页计算参数

**文件**: `lib/utils/pagination_calculator.dart`

### 8.1 可用页面高度计算
**位置**: 第 9 行

```dart
static double calculateAvailableHeight(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final padding = MediaQuery.of(context).padding;
  
  final availableHeight = size.height 
      - padding.top          // 顶部安全区
      - (kToolbarHeight)     // 标题栏高度
      - 80                   // ← 顶部额外预留
      - 80;                  // ← 底部额外预留
  
  return availableHeight;
}
```

**可调参数**:
- 第一个 `80`: 顶部预留空间
- 第二个 `80`: 底部预留空间
- ⚠️ **重要**: 影响每页显示的内容量

---

### 8.2 段落间距
**位置**: 第 86 行

```dart
const paragraphSpacing = 16.0;  // ← 段落间距
return textPainter.height + paragraphSpacing;
```

**可调参数**:
- `paragraphSpacing`: 段落间空白，推荐 12-20

---

## 🏠 九、书架页面（HomeScreen）

**文件**: `lib/screens/home_screen_with_covers.dart`

### 9.1 书架网格布局
**位置**: 第 55 行

```dart
GridView.builder(
  padding: const EdgeInsets.all(16),  // ← 整体边距
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,      // ← 每行显示3本书
    childAspectRatio: 0.7,  // ← 书籍卡片宽高比
    crossAxisSpacing: 16,   // ← 横向间距
    mainAxisSpacing: 16,    // ← 纵向间距
  ),
)
```

**可调参数**:
- `crossAxisCount`: 每行书籍数量，推荐 2-4
- `childAspectRatio`: 卡片宽高比，推荐 0.6-0.8
- `crossAxisSpacing`: 横向间距，推荐 12-20
- `mainAxisSpacing`: 纵向间距，推荐 12-20

---

### 9.2 书名和作者文字
**位置**: 第 110 行

```dart
Text(
  book.title,
  style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,  // ← 书名大小
  ),
  maxLines: 2,     // ← 最多显示2行
),
const SizedBox(height: 4),
Text(
  book.author,
  style: TextStyle(
    fontSize: 12,  // ← 作者名大小
    color: Colors.grey[600],
  ),
  maxLines: 1,     // ← 最多显示1行
),
```

**可调参数**:
- 书名 `fontSize`: 推荐 12-16
- 作者 `fontSize`: 推荐 10-14
- `maxLines`: 最大行数

---

## 🎨 十、颜色主题

### 10.1 正文背景色
**位置**: `reader_screen_with_toc.dart` 第 518 行

```dart
Container(
  color: Colors.white,  // ← 背景颜色
  padding: ...,
)
```

**可选颜色**:
- `Colors.white`: 白色（护眼）
- `Color(0xFFFFF8DC)`: 米黄色（纸张感）
- `Color(0xFFF5F5DC)`: 米色（柔和）

---

### 10.2 按钮颜色
**位置**: 第 488 行（分析按钮）

```dart
FloatingActionButton(
  backgroundColor: Colors.blue,  // ← 按钮背景色
  child: const Icon(Icons.analytics),
),
```

---

## 📋 快速调整清单

### 常见调整场景

#### 场景1: 文字太小，看不清
```dart
// reader_settings.dart
medium(20.0),  // 改成 20 或 22
```

#### 场景2: 图片太小
```dart
// reader_screen_with_toc.dart 第690行
maxHeight: 400,  // 改成 400-500
```

#### 场景3: 底部文字被按钮遮挡
```dart
// reader_screen_with_toc.dart 第523行
padding: const EdgeInsets.only(bottom: 100),  // 改大这个值
```

#### 场景4: 每页文字太少
```dart
// pagination_calculator.dart 第15-16行
- 80   // 减小这两个值（改成60或40）
- 80
```

#### 场景5: 按钮太小，不好点
```dart
// reader_screen_with_toc.dart
Icon(..., size: 28),           // 改大图标
Text(..., style: TextStyle(fontSize: 16)),  // 改大文字
```

---

## ⚠️ 重要提醒

1. **图片相关的两处要同步**:
   - `reader_screen_with_toc.dart` 第690行 (`maxHeight`)
   - `pagination_calculator.dart` 第4行 (`imageHeight`)
   
2. **底部留白要大于按钮栏高度**:
   - 正文底部留白 (`bottom: 80`) 应该 > 按钮栏实际高度

3. **修改后要重启App**:
   - 大部分UI参数需要重新编译才能生效

4. **建议先在一处测试**:
   - 先改一个参数看效果
   - 满意后再改其他地方

---

## 🔧 调试技巧

### 查看当前参数
在控制台打印：
```dart
print('可用高度: $availableHeight');
print('当前字体: ${_settings.fontSize.size}');
```

### 快速定位
使用 VS Code / Android Studio 的"查找"功能：
- `fontSize` - 查找所有字体大小
- `padding` - 查找所有边距
- `maxHeight` - 查找高度限制
- `Icon(` - 查找所有图标

---

## 📞 需要帮助？

如果不确定某个参数的位置，告诉我你想调整什么，我会给你精确的行号！
