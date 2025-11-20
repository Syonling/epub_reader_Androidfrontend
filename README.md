# AI阅读助手 (AI Reading Assistant)

選択したテキストの文法解析と語彙解析をサポートする、AI 搭載のインテリジェント EPUB リーダーです。

(日本語説明ドキュメント作成中)

**⬇️ 各分析機能の詳細については、バックエンドプロジェクトを参照してください。⬇️**

> 💻 Backend：[EPUB Reader （AI Analysis）](https://github.com/Syonling/epub_reader_backend)

![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-blue)
![Python](https://img.shields.io/badge/Python-3.11.0+-brightgreen)
![Flutter](https://img.shields.io/badge/Flutter-3.35.6-blue)
![Flask](https://img.shields.io/badge/Flask-3.1.2-orange)

## フロントエンド機能一覧
### 実装された機能
- [x] 本の表紙画像付きのホームページ本棚ディスプレイ
- [x] 本のページネーションのプリロード
- [x] EPUB書籍閲覧ディスプレイ
- [x] 目次と脚注（ハイパーリンク）
- [x] 長押しして単語/長文を選択
- [x] 機能的な UI (API 選択、インタラクティブボタン、フォントサイズの調整、目次など)

### 追加予定機能
- [ ] より適切なページネーションデザイン
- [ ] 縦書きの日本語書籍に対応
- [ ] 書籍を追加するためのボタン
- [ ] ……

## 🎬 デモンストレーション
 
### 単語分析 **Debug中**
![单词分析演示](assets/demos/word_analysis.gif)

### 長文解析 - AIによる構文解析
![句子分析演示](assets/demos/sentence_analysis.gif)

### スイッチAPI
![切换模型演示](assets/demos/switch_model.gif)

[日本語](#日本語) | [English](#english-documentation)

---

## <a name="chinese"></a>🇨🇳 中文文档

### ✨ 功能特性

- 📖 **EPUB阅读器** - 支持标准EPUB格式电子书
- 🤖 **AI文本分析** - 选中句子即可获得AI语法和词汇分析
- 📱 **跨平台支持** - Android、iOS（未来支持Web和桌面端）
- 🎨 **现代化UI** - Material Design 3设计风格
- 🔌 **模块化架构** - 清晰的代码结构，易于扩展

### 📸 预览

```
[此处可添加应用截图]
```

### 🏗️ 项目架构 - 前端

```
epub_reader/
├── lib/
│   ├── constants/          # 常量配置
│   │   └── api_constants.dart
│   ├── models/             # 数据模型
│   │   ├── analysis_result.dart
│   │   └── book.dart
│   ├── screens/            # 页面
│   │   ├── home_screen.dart
│   │   ├── reader_screen.dart
│   │   └── settings_screen.dart
│   ├── services/           # 业务逻辑
│   │   ├── api_service.dart
│   │   └── file_service.dart
│   ├── widgets/            # UI组件
│   │   ├── text_input_dialog.dart
│   │   └── result_dialog.dart
│   └── main.dart           # 应用入口
└── assets/                 # 资源文件

```

### 后端
[点击访问后端](https://github.com/Syonling/epub_reader_backend)


### 🚀 快速开始

#### 前置要求

- Flutter SDK 3.0+
- Android Studio / Xcode
- Python 3.9+（后端）
- Android设备或模拟器

#### 前端安装

```bash
# 克隆项目
git clone https://github.com/Syonling/epub_reader.git
cd epub_reader

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

#### 后端安装

```bash
# 进入后端目录
cd backend

# 使用Poetry安装依赖（推荐）
poetry install
poetry run python backend.py

# 或使用pip
pip install flask flask-cors
python backend.py
```

### ⚙️ 配置

修改 `lib/constants/api_constants.dart` 中的后端地址：

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:5001';
```

### 📦 核心依赖

#### 前端
- [epub_view](https://pub.dev/packages/epub_view) - EPUB阅读器
- [file_picker](https://pub.dev/packages/file_picker) - 文件选择
- [http](https://pub.dev/packages/http) - HTTP请求

#### 后端
- Flask - Web框架
- Flask-CORS - 跨域支持

### 🛣️ 开发路线图

- [x] 基础EPUB阅读功能
- [x] 文本选择与后端通信
- [x] 模块化代码重构
- [ ] 真实AI语法分析（集成GPT/Claude API）
- [ ] 内置词典功能
- [ ] 生词本和笔记功能
- [ ] 阅读进度云同步
- [ ] 夜间模式和主题定制
- [ ] 墨水屏设备支持

### 🤝 贡献指南

欢迎提交Issue和Pull Request！

1. Fork本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

### 📝 开发文档

详细的开发文档请参见 [Wiki](https://github.com/Syonling/epub_reader/wiki)

### 🐛 问题反馈

遇到问题？请在 [Issues](https://github.com/Syonling/epub_reader/issues) 中反馈。

### 📄 许可证

本项目采用 **CC BY-NC 4.0** 许可证。

这意味着：
- ✅ 可以自由分享和修改代码
- ✅ 必须注明原作者
- ❌ 不得用于商业用途
- ✅ 衍生作品需采用相同许可证

详见 [LICENSE](LICENSE) 文件。

### 👨‍💻 作者

[@Syonling](https://github.com/Syonling)

### 🙏 致谢

- [Flutter](https://flutter.dev/) - 优秀的跨平台框架
- [epub_view](https://pub.dev/packages/epub_view) - EPUB渲染库
- 所有贡献者和支持者

---

## <a name="english"></a>🇬🇧 English Documentation

### [To Backend](https://github.com/Syonling/epub_reader_backend)

### ✨ Features

- 📖 **EPUB Reader** - Support standard EPUB format ebooks
- 🤖 **AI Text Analysis** - Get grammar and vocabulary analysis by selecting text
- 📱 **Cross-platform** - Android, iOS (Web & Desktop coming soon)
- 🎨 **Modern UI** - Material Design 3 style
- 🔌 **Modular Architecture** - Clean code structure, easy to extend

### 🚀 Quick Start

#### Prerequisites

- Flutter SDK 3.0+
- Android Studio / Xcode
- Python 3.9+ (for backend)
- Android device or emulator

#### Frontend Installation

```bash
# Clone the repository
git clone https://github.com/Syonling/epub_reader.git
cd epub_reader

# Install dependencies
flutter pub get

# Run the app
flutter run
```

#### Backend Installation

```bash
# Navigate to backend directory
cd backend

# Using Poetry (recommended)
poetry install
poetry run python backend.py

# Or using pip
pip install flask flask-cors
python backend.py
```

### ⚙️ Configuration

Modify backend URL in `lib/constants/api_constants.dart`:

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:5001';
```

### 📦 Dependencies

#### Frontend
- [epub_view](https://pub.dev/packages/epub_view) - EPUB reader
- [file_picker](https://pub.dev/packages/file_picker) - File picker
- [http](https://pub.dev/packages/http) - HTTP client

#### Backend
- Flask - Web framework
- Flask-CORS - Cross-origin support

### 🛣️ Roadmap

- [x] Basic EPUB reading functionality
- [x] Text selection and backend communication
- [x] Modular code refactoring
- [ ] Real AI grammar analysis (GPT/Claude API integration)
- [ ] Built-in dictionary
- [ ] Vocabulary notebook and notes
- [ ] Cloud sync for reading progress
- [ ] Dark mode and theme customization
- [ ] E-ink device support

### 🤝 Contributing

Issues and Pull Requests are welcome!

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### 📄 License

This project is licensed under **CC BY-NC 4.0**.

This means:
- ✅ Free to share and adapt
- ✅ Must give appropriate credit
- ❌ No commercial use
- ✅ Derivatives must use same license

See [LICENSE](LICENSE) file for details.

### 👨‍💻 Author

[@Syonling](https://github.com/Syonling)

### 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - Amazing cross-platform framework
- [epub_view](https://pub.dev/packages/epub_view) - EPUB rendering library
- All contributors and supporters

---

## 📞 Contact

<!-- - Email: your.email@example.com
- Twitter: [@yourhandle](https://twitter.com/yourhandle) -->
- Project Link: [https://github.com/Syonling/epub_reader](https://github.com/Syonling/epub_reader)

---

<p align="center">Made with ❤️ and Flutter</p>
