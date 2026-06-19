<div align="center">

# 🚭 QuitMate · 戒烟戒酒助手

**智能戒烟戒酒 · 科学三阶干预 · 纯离线隐私安全**

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.8.0-orange.svg)](https://github.com/185www/quitmate/releases)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey.svg)](https://github.com/185www/quitmate)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-9B59B6.svg)]()

**A Flutter-based smart quit smoking/drinking assistant with AI coaching, CBT exercises, gamification, and 100% offline privacy.**

基于 Flutter 构建的智能戒烟戒酒助手，采用科学三阶干预模型，内置 AI 教练与 CBT 认知行为练习，游戏化激励，全程纯离线运行、AES-256 加密保护隐私。

</div>

---

## ✨ 核心特性

| 特性 | 说明 |
|:---:|:---|
| 🧠 **三阶干预模型** | 科学戒烟戒酒路径：认知觉醒 → 行动改变 → 维持防复发，循序渐进达成目标 |
| 🤖 **AI 智能教练** | 内置大语言模型驱动的个性化辅导，随时提供专业建议与情感支持 |
| 🧩 **CBT 认知练习** | 基于认知行为疗法的结构化练习，识别并改变不良思维模式 |
| 🎮 **游戏化激励** | 成就系统、连续打卡、等级晋升，让坚持变得有趣有动力 |
| 📊 **数据可视化** | 健康恢复时间线、节省金额统计、戒断趋势图表，直观呈现进步 |
| 🔒 **隐私安全** | 全程纯离线运行，AES-256 加密存储，数据绝不外传 |
| 🏥 **健康恢复追踪** | 从戒烟/戒酒第 1 分钟起，实时追踪身体各项指标的恢复进度 |
| 💪 **应急干预** | 渴望来袭时一键触发紧急干预策略，帮你度过关键时刻 |
| 🌙 **深色模式** | 支持浅色/深色主题切换，呵护你的眼睛 |
| 📱 **跨平台** | 一套代码同时支持 iOS 与 Android，体验一致 |

---

## 📸 应用截图

> 📝 **注意**：截图待补充，欢迎贡献！
>
> 如您已安装使用 QuitMate，欢迎提交截图至 [Issue #模板截图征集](https://github.com/185www/quitmate/issues) 或通过 PR 贡献。

| 功能页 | 统计页 | AI 教练 |
|:---:|:---:|:---:|
| *待补充* | *待补充* | *待补充* |

---

## 🛠 技术栈

| 类别 | 技术 |
|:---|:---|
| **框架** | Flutter 3.24+ |
| **语言** | Dart 3.5+ |
| **状态管理** | BLoC / Cubit |
| **本地存储** | Hive + AES-256 加密 |
| **依赖注入** | GetIt + Injectable |
| **路由** | GoRouter |
| **AI 推理** | 本地 LLM (ONNX Runtime / llama.cpp) |
| **图表** | fl_chart |
| **架构模式** | Clean Architecture |
| **测试** | Flutter Test + Mockito + Integration Test |

---

## 🏗 架构设计

QuitMate 采用 **Clean Architecture** 分层架构，确保关注点分离与高可测试性：

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │  Screens  │  │  Widgets  │  │  BLoC/Cubit │  │  States  │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
├─────────────────────────────────────────────────────────┤
│                      Domain Layer                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐   │
│  │ Entities  │  │  Use Cases │  │  Repository Interface │  │
│  └──────────┘  └──────────┘  └──────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                       Data Layer                          │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────────┐   │
│  │  Models   │  │  Repositories │  │  Data Sources    │   │
│  └──────────┘  └──────────────┘  └───────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                       Core Layer                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │ Constants │  │  Utils   │  │   Errors  │  │  Crypto  │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────┘
```

**数据流向**：`Screen → BLoC → UseCase → Repository → DataSource`

每一层职责清晰，依赖方向由外向内（Presentation → Domain ← Data），Domain 层不依赖任何外部框架。

---

## 🚀 快速开始

### 前置条件

- **Flutter SDK** ≥ 3.24.0
- **Dart SDK** ≥ 3.5.0
- **Android Studio** / **VS Code**（推荐安装 Flutter 插件）
- **Xcode** ≥ 15（仅 iOS 开发需要，macOS 环境）
- **Git**

### 安装与运行

```bash
# 1. 克隆仓库
git clone https://github.com/185www/quitmate.git
cd quitmate

# 2. 获取依赖
flutter pub get

# 3. 生成代码（如使用 build_runner）
dart run build_runner build --delete-conflicting-outputs

# 4. 运行（调试模式）
flutter run

# 5. 构建 APK
flutter build apk --release

# 6. 构建 iOS（需要 macOS）
flutter build ios --release
```

### 环境配置

```bash
# 复制环境配置模板
cp .env.example .env

# 根据需要编辑配置项（本项目为纯离线，配置项较少）
```

---

## 📁 项目结构

```
quitmate/
├── .github/
│   └── ISSUE_TEMPLATE/          # Issue 模板
│       ├── bug_report.md
│       └── feature_request.md
├── assets/
│   ├── images/                  # 图片资源
│   ├── icons/                   # 图标资源
│   └── models/                  # AI 模型文件
├── lib/
│   ├── core/                     # 核心工具层
│   │   ├── constants/           # 常量定义
│   │   ├── errors/              # 异常与错误处理
│   │   ├── utils/               # 工具函数
│   │   ├── crypto/              # AES-256 加密模块
│   │   └── theme/               # 主题配置
│   ├── data/                     # 数据层
│   │   ├── models/              # 数据模型
│   │   ├── repositories/        # Repository 实现
│   │   ├── datasources/         # 数据源（本地/远程）
│   │   └── dto/                 # 数据传输对象
│   ├── domain/                   # 领域层
│   │   ├── entities/            # 领域实体
│   │   ├── repositories/        # Repository 接口
│   │   └── usecases/            # 业务用例
│   ├── presentation/             # 表现层
│   │   ├── screens/             # 页面
│   │   ├── widgets/             # 通用组件
│   │   ├── blocs/               # BLoC 状态管理
│   │   └── routes/              # 路由配置
│   └── main.dart                 # 应用入口
├── test/                         # 测试
│   ├── unit/                    # 单元测试
│   ├── widget/                  # Widget 测试
│   └── integration/             # 集成测试
├── .env.example                  # 环境变量模板
├── analysis_options.yaml         # Dart 静态分析配置
├── pubspec.yaml                  # 依赖管理
├── README.md                     # 项目说明
├── CONTRIBUTING.md               # 贡献指南
└── LICENSE                       # 许可证
```

---

## 🧪 测试

本项目采用多层测试策略，确保代码质量：

```bash
# 运行所有单元测试与 Widget 测试
flutter test

# 运行指定目录的测试
flutter test test/unit/
flutter test test/widget/

# 运行集成测试（需要连接设备或模拟器）
flutter test integration_test/

# 生成测试覆盖率报告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 测试层级

| 层级 | 覆盖范围 | 依赖 |
|:---:|:---|:---|
| **单元测试** | Domain 用例、Core 工具、Data 模型 | flutter_test, mockito |
| **Widget 测试** | UI 组件渲染与交互 | flutter_test, bloc_test |
| **集成测试** | 完整用户流程 | integration_test |

---

## 🤝 参与贡献

我们热烈欢迎并感谢每一位贡献者！无论是提交 Bug、建议新功能，还是直接提交代码。

📋 请阅读 [**贡献指南 (CONTRIBUTING.md)**](./CONTRIBUTING.md) 了解详细流程，包括：

- 🐛 如何报告 Bug
- 💡 如何提交功能建议
- 🔀 如何提交 Pull Request
- 📝 代码风格与提交规范

<details>
<summary><b>快速概览：提交流程</b></summary>

1. **Fork** 本仓库
2. 创建特性分支：`git checkout -b feature/your-feature-name`
3. 提交更改：`git commit -m "feat: 添加新功能描述"`
4. 推送分支：`git push origin feature/your-feature-name`
5. 提交 **Pull Request** 并填写 PR 模板

</details>

---

## 📄 开源协议

本项目基于 [MIT License](./LICENSE) 开源。

```
MIT License

Copyright (c) 2024 QuitMate Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🙏 鸣谢

- **Flutter** — 跨平台 UI 框架
- **认知行为疗法 (CBT)** — 科学干预方法论
- **所有贡献者** — 感谢你们让 QuitMate 变得更好

---

<div align="center">

**用科技守护健康，让改变从今天开始 💪**

Made with ❤️ by [QuitMate Contributors](https://github.com/185www/quitmate/graphs/contributors)

</div>
