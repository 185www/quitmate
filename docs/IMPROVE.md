# QuitMate 改进计划

> 版本: v2 · 更新时间: 2026-06-21

---

## 第一批改进 (P0-P2) ✅ 已完成

### P0-1: SOS 呼吸节奏修正 ✅
- **问题**: 4-7-8 呼吸法动画不正确，4s AnimationController 无法表达 4-7-8 非对称节奏
- **修复**: 重写为 Timer 状态机，19s 完整周期 (吸气4s + 屏息7s + 呼气8s)，共享 BreathTiming 常量
- **涉及文件**: `breath_timing.dart`, `sos_breathing_sheet.dart`, `immersive_breathing_guide.dart`

### P0-2: 通知权限引导优化 ✅
- **问题**: 启动时直接弹出权限对话框，用户未感知价值就拒绝
- **修复**: 拆分 initialize()，新增 notification_permission_dialog.dart 价值说明弹窗，在戒烟日期设置后请求
- **涉及文件**: `notification_service.dart`, `notification_permission_dialog.dart`, `quit_date_wizard_screen.dart`

### P1-3: 强制安装留存优化 ✅
- **问题**: 新用户首次打开必须走完整流程，无法先体验
- **修复**: 新增"随便看看"路径 + PopScope 退出意图拦截（金钱钩子），延迟 FTND/AUDIT 评估
- **涉及文件**: `welcome_screen.dart`, `discovery_screen.dart`, `education_screen.dart`

### P1-4: 教育内容深度优化 ✅
- **问题**: 戒烟好处只有标题无详情，缺乏紧迫感
- **修复**: 替换为可展开详情卡片 + "如果继续" 损失厌恶警告
- **涉及文件**: `education_screen.dart`

### P2-5: 桌面小组件 LLM 个性化 ✅
- **问题**: 小组件只显示静态数据
- **修复**: 新增 generateWidgetInsight() LLM + 静态回退，添加 personalizedInsight 字段
- **涉及文件**: `widget_service_v2.dart`

### P2-6: LLM 通知内容生成 ✅
- **问题**: 通知内容是固定模板
- **修复**: 新增 notification_content_generator.dart，LLM 生成 + 模板回退
- **涉及文件**: `notification_content_generator.dart`

### P3-7: LLM Token 成本追踪 ✅
- **问题**: 无法监控 LLM 调用成本
- **修复**: 新增 llm_usage_tracker.dart 单例，追踪输入/输出 token，估算月费用
- **涉及文件**: `llm_usage_tracker.dart`

### P3-8: LLM Prompt 压缩 ✅
- **问题**: 上下文过长浪费 token
- **修复**: 新增 buildCompressedWeekSummary()，压缩周总结从 ~1200 到 ~300 token
- **涉及文件**: `llm_prompt_builder.dart`

---

## 第二批改进 (P0-P1) 🔄 进行中

### P0-9: CI 流水线修复 ✅
- **问题**: ci.yml 分支配置语法错误 (`ain, develop]`) + 2个 Dart 编译错误导致 CI 从未正确运行
- **修复**: 
  - 修正分支配置为 `[main, develop]`
  - 修复 `llm_usage_tracker.dart` 数字分隔符 Unicode 问题
  - 修复 `widget_service_v2.dart` raw string 引号语法
  - 移除 `--no-fatal-infos --no-fatal-warnings` 使错误正确阻断
- **涉及文件**: `.github/workflows/ci.yml`, `llm_usage_tracker.dart`, `widget_service_v2.dart`

### P0-10: Release 签名与构建修复 ✅
- **问题**: Release APK 使用 debug keystore 签名，构建因 keystore 路径和 compileSdk 版本失败
- **修复**:
  - 生成正式 keystore，配置 GitHub Secrets
  - 更新 build.gradle compileSdk=36，正确读取 key.properties
  - 修复 release.yml storeFile 路径
- **涉及文件**: `build.gradle`, `release.yml`, GitHub Secrets (KEYSTORE_*)

### P0-11: 用户年龄持久化 ✅
- **问题**: 用户年龄硬编码为 30 岁，User 实体无 age 字段，切换目标类型时重置，离开页面后丢失
- **修复**:
  - User 实体新增 `int? age` 字段
  - 数据库版本 8→9，ALTER TABLE 添加 age 列
  - Repository 和 UseCase 传递 age 参数
  - RealityCheckScreen 初始化时加载已有年龄，保存时持久化
  - 移除 _updateDefaults() 中的 `_age = 30` 重置
- **涉及文件**: `user.dart`, `app_database.dart`, `user_repository_impl.dart`, `user_usecase.dart`, `reality_check_screen.dart`

### P1-12: 桌面组件扩展至 3 种 ✅
- **问题**: 只有 1 个进度追踪组件，缺少风险警报和每日激励组件
- **修复**: 新增 2 个 Android 原生 Widget
  - **风险警报 (4×1)**: RiskAlertWidgetProvider — 显示风险等级、分数、渴求强度进度条，30分钟更新，风险颜色编码
  - **每日激励 (4×2)**: MotivationWidgetProvider — 显示每日语录/提示、连续天数、个性化洞察，60分钟更新
  - 包含布局 XML、WidgetInfo XML、字符串资源
- **涉及文件**: `RiskAlertWidgetProvider.java`, `MotivationWidgetProvider.java`, `risk_alert_widget_layout.xml`, `motivation_widget_layout.xml`, `risk_alert_widget_info.xml`, `motivation_widget_info.xml`, `widget_strings.xml`, `AndroidManifest.xml`

### P1-13: LLM 设置界面 ✅
- **问题**: LLM 功能架构完善但无设置 UI，用户无法配置 API Key / Base URL / 模型，所有 AI 功能不可达
- **修复**: 新增完整 AI 设置页面
  - AI 开关 (启用/禁用 LLM)
  - API 配置 (Key、Base URL、模型名称，Key 自动遮蔽)
  - 快速预设 (OpenAI、DeepSeek、Ollama 本地)
  - 连接测试按钮 (实时验证 API 可用性)
  - 用量统计卡片 (输入/输出 token、调用次数、月费用估算)
  - 隐私保护说明 (PII 清洗、安全审查、本地回退保证)
  - 设置页入口已集成到现有 settings_screen.dart
- **涉及文件**: `llm_settings_screen.dart`, `settings_screen.dart`, `app_router.dart`

---

## 改进总结

| 批次 | 总项数 | 已完成 | 状态 |
|------|--------|--------|------|
| 第一批 (v1.10.0) | 8 | 8 | ✅ 全部完成 |
| 第二批 (v1.11.0) | 5 | 5 | ✅ 全部完成 |
| **合计** | **13** | **13** | **✅** |
