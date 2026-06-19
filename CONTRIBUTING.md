# 🤝 贡献指南 (CONTRIBUTING)

首先，感谢你对 **QuitMate（戒烟戒酒助手）** 项目的关注和支持！🎉

无论是修复 Bug、改进文档、还是添加新功能，每一份贡献都弥足珍贵。本指南将帮助你了解如何参与贡献。

---

## 📋 目录

- [行为准则](#-行为准则)
- [如何报告 Bug](#-如何报告-bug)
- [如何提交功能建议](#-如何提交功能建议)
- [如何提交 Pull Request](#-如何提交-pull-request)
- [代码风格指南](#-代码风格指南)
- [提交信息规范](#-提交信息规范)
- [测试要求](#-测试要求)
- [项目结构概览](#-项目结构概览)
- [联系方式与交流](#-联系方式与交流)

---

## 🌈 行为准则

请确保你的言行尊重他人，保持友善和建设性的态度。我们欢迎所有人参与，不歧视任何背景的贡献者。遇到不当行为，请联系维护者。

---

## 🐛 如何报告 Bug

发现 Bug？请在 [Issues](https://github.com/185www/quitmate/issues) 页面提交，并使用 **Bug Report** 模板：

1. 点击 [新建 Issue](https://github.com/185www/quitmate/issues/new/choose)
2. 选择 **🐛 Bug Report** 模板
3. 按模板填写以下信息：
   - **问题描述**：清晰描述你遇到的问题
   - **复现步骤**：一步步说明如何重现该 Bug
   - **期望行为**：你期望的正确行为是什么
   - **实际行为**：实际发生了什么
   - **设备信息**：设备型号、操作系统版本、App 版本
   - **截图/日志**：如有请附上

> 💡 **提示**：一个清晰、可复现的 Bug 报告能大幅提高修复效率！

---

## 💡 如何提交功能建议

有好点子？请同样在 [Issues](https://github.com/185www/quitmate/issues) 提交：

1. 点击 [新建 Issue](https://github.com/185www/quitmate/issues/new/choose)
2. 选择 **✨ Feature Request** 模板
3. 按模板填写以下信息：
   - **功能描述**：你希望添加什么功能
   - **动机/背景**：为什么需要这个功能，解决什么问题
   - **建议方案**：你设想的实现方式（可选）
   - **优先级**：标注你认为的优先级（P0 紧急 / P1 重要 / P2 一般 / P3 低）

提交后，维护者和社区成员会讨论评估该建议的可行性。

---

## 🔀 如何提交 Pull Request

### 步骤概览

```bash
# 1. Fork 本仓库（在 GitHub 页面点击 Fork 按钮）

# 2. 克隆你 Fork 的仓库到本地
git clone https://github.com/<你的用户名>/quitmate.git
cd quitmate

# 3. 添加上游仓库为远程源
git remote add upstream https://github.com/185www/quitmate.git

# 4. 创建特性分支（从最新 main 分支切出）
git checkout main
git pull upstream main
git checkout -b feature/your-feature-name

# 5. 进行开发...

# 6. 提交更改（遵循提交规范）
git add .
git commit -m "feat: 添加用户健康数据导出功能"

# 7. 推送到你的 Fork
git push origin feature/your-feature-name

# 8. 在 GitHub 上创建 Pull Request
```

### PR 提交清单

在提交 PR 前，请确认以下事项：

- [ ] 代码通过 `flutter analyze` 无任何警告或错误
- [ ] 所有测试通过：`flutter test`
- [ ] 新功能包含对应的单元测试
- [ ] 已遵循本项目的代码风格规范
- [ ] 提交信息符合 [Conventional Commits](#-提交信息规范) 规范
- [ ] PR 标题清晰描述了改动内容
- [ ] 如有需要，已更新相关文档
- [ ] 如涉及破坏性变更，在 PR 描述中明确说明

### 分支命名规范

| 类型 | 前缀 | 示例 |
|:---|:---:|:---|
| 新功能 | `feature/` | `feature/health-data-export` |
| Bug 修复 | `fix/` | `fix/crash-on-statistics-page` |
| 重构 | `refactor/` | `refactor/bloc-state-management` |
| 文档 | `docs/` | `docs/update-readme` |
| 性能优化 | `perf/` | `perf/optimize-chart-rendering` |
| 测试 | `test/` | `test/add-cbt-exercise-tests` |

---

## 📝 代码风格指南

本项目遵循 **Dart 官方代码规范** 和 **Flutter 最佳实践**。

### 基本规则

1. **格式化**：使用 `dart format` 格式化代码
   ```bash
   dart format lib/ test/
   ```

2. **静态分析**：确保 `flutter analyze` 零警告
   ```bash
   flutter analyze
   ```

3. **命名规范**：
   - 文件名：`snake_case.dart`（如 `health_recovery_tracker.dart`）
   - 类名：`PascalCase`（如 `HealthRecoveryTracker`）
   - 变量/函数：`camelCase`（如 `calculateHealthScore`）
   - 常量：`lowerCamelCase`（如 `maxRetryAttempts`）
   - 私有成员：以 `_` 开头

4. **代码组织**：
   ```dart
   // 1. import 语句（按顺序：dart: → package: → 相对路径）
   import 'dart:async';
   import 'package:flutter/material.dart';
   import '../../domain/entities/user.dart';

   // 2. part 语句（如有）

   // 3. 类定义
   class MyWidget extends StatelessWidget {
     // 3.1 常量/静态成员
     static const _defaultPadding = 16.0;

     // 3.2 最终字段
     final String title;

     // 3.3 构造函数
     const MyWidget({super.key, required this.title});

     // 3.4 覆写方法
     @override
     Widget build(BuildContext context) {
       // ...
     }

     // 3.5 其他方法
     // 3.6 私有方法
   }
   ```

5. **注释**：
   - 公共 API 使用 `///` 文档注释
   - 复杂逻辑使用 `//` 行注释说明
   - 中文注释与英文代码混合时，注释使用中文

6. **BLoC/Cubit 规范**：
   - 每个 Feature 一个独立的 BLoC/Cubit 文件夹
   - Event/State 使用 `freezed` 或手写不可变类
   - 避免在 BLoC 中直接调用 UI 相关代码

### 代码质量工具

```bash
# 格式化检查
dart format --set-exit-if-changed lib/ test/

# 静态分析
flutter analyze --fatal-infos

# 运行所有测试
flutter test

# 代码覆盖率
flutter test --coverage
```

---

## 📮 提交信息规范

本项目采用 **Conventional Commits** 规范，提交描述**支持中文**。

### 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

| 类型 | 说明 |
|:---|:---|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档变更 |
| `style` | 代码格式调整（不影响逻辑） |
| `refactor` | 重构（既非新功能也非 Bug 修复） |
| `perf` | 性能优化 |
| `test` | 添加或修改测试 |
| `build` | 构建系统或依赖变更 |
| `ci` | CI/CD 配置变更 |
| `chore` | 其他杂项变更 |
| `revert` | 回滚提交 |

### 示例

```bash
# 新功能
git commit -m "feat(ai-coach): 添加 AI 教练对话历史记录功能"

# Bug 修复
git commit -m "fix(statistics): 修复图表在深色模式下显示异常的问题"

# 文档
git commit -m "docs(readme): 更新项目架构图说明"

# 重构
git commit -m "refactor(domain): 优化健康恢复追踪用例的逻辑结构"

# 带详细说明的提交
git commit -m "feat(gamification): 新增连续打卡成就系统

- 添加连续 7/14/30/100 天打卡成就
- 每个成就对应不同的勋章图标
- 成就达成时触发本地通知提醒
- 解决 #42"
```

---

## 🧪 测试要求

我们要求所有 PR 必须包含相应的测试，确保代码质量。

### 测试策略

| 层级 | 必须覆盖 | 推荐工具 |
|:---|:---|:---|
| **单元测试** | Domain 用例、Data Repository、Core 工具 | `flutter_test` + `mockito` |
| **Widget 测试** | 关键 UI 组件 | `flutter_test` + `bloc_test` |
| **集成测试** | 核心用户流程（如首次设置、打卡流程） | `integration_test` |

### 编写测试的原则

1. **新功能必须有测试**：新增的 UseCase、Repository、关键 Widget 必须配套测试
2. **Bug 修复必须有回归测试**：修复 Bug 时需添加测试防止回归
3. **测试应独立可重复**：避免测试间相互依赖
4. **使用有意义的测试名**：清晰描述测试场景

```dart
// ✅ 好的测试命名
test('当用户连续打卡7天时应解锁七天坚持成就', () { ... });

// ❌ 不好的测试命名
test('testAchievement', () { ... });
```

### 运行测试

```bash
# 运行全部测试
flutter test

# 运行特定文件
flutter test test/domain/usecases/calculate_health_score_test.dart

# 运行并显示覆盖率
flutter test --coverage
```

---

## 📁 项目结构概览

QuitMate 采用 **Clean Architecture** 分层架构：

```
lib/
├── core/              # 核心层：常量、工具、错误处理、加密、主题
│   ├── constants/     # 全局常量
│   ├── errors/        # 领域异常定义
│   ├── utils/         # 通用工具函数
│   ├── crypto/        # AES-256 加密模块
│   └── theme/         # Material 主题配置
├── data/              # 数据层：实现领域层定义的接口
│   ├── models/        # 数据模型（Entity ↔ JSON 转换）
│   ├── repositories/  # Repository 实现
│   ├── datasources/   # 本地/远程数据源
│   └── dto/           # 数据传输对象
├── domain/            # 领域层：纯业务逻辑，无框架依赖
│   ├── entities/      # 领域实体
│   ├── repositories/  # Repository 抽象接口
│   └── usecases/      # 业务用例
├── presentation/      # 表现层：UI 与状态管理
│   ├── screens/       # 页面（按功能模块组织）
│   ├── widgets/       # 可复用组件
│   ├── blocs/         # BLoC/Cubit（按功能模块组织）
│   └── routes/        # 路由与导航配置
└── main.dart          # 应用入口与初始化
```

### 依赖方向

```
Presentation → Domain ← Data
     ↓                          ↑
   (依赖)                   (实现)
```

- **Domain 层**是最核心的层，不依赖任何外部框架
- **Data 层**实现 Domain 层定义的 Repository 接口
- **Presentation 层**通过 UseCase 与 Domain 层交互

---

## 📬 联系方式与交流

| 渠道 | 说明 |
|:---|:---|
| **GitHub Issues** | [提交 Issue](https://github.com/185www/quitmate/issues) — Bug 报告与功能建议 |
| **GitHub Discussions** | [参与讨论](https://github.com/185www/quitmate/discussions) — 通用讨论与问答 |
| **Pull Requests** | [提交 PR](https://github.com/185www/quitmate/pulls) — 代码贡献 |

### 维护者审核周期

- **Bug 修复**：通常在 3-5 个工作日内审核回复
- **功能建议**：通常在 1-2 周内评估并回复
- **Pull Request**：通常在 1 周内完成审核

> ⚠️ 维护者均为兼职贡献，如遇紧急安全问题，请在 Issue 中标注 `🔒 security` 标签。

---

## 📄 许可证

提交贡献即表示你同意你的代码将基于 [MIT License](./LICENSE) 发布。

---

<div align="center">

**感谢你的贡献！让我们一起帮助更多人戒烟戒酒 💪**

</div>
