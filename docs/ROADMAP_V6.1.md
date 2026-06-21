# QuitMate v6.1 产品迭代 Roadmap（动机唤醒计划）

> 更新时间：2026-06-21 | 产品经理：新任 PM
> 父版本：v6.0（Android 专注优化）

---

## 背景与核心命题

当前 QuitMate 的功能（打卡、健康时间线、应急干预）主要服务于 **"已有强烈戒断意愿"** 的用户（行动期）。但对于 **"完全没有戒断意愿、甚至抗拒戒断"** 的用户（前意向阶段），目前的强干预逻辑会引发严重的逆反心理，导致用户流失。

**本版本核心命题**：利用大模型的强交互能力，将 App 从"监督者"转变为"动机唤醒者"，让无意愿的用户也能在潜移默化中产生改变的动力。

---

## 三个阶段总览

| 阶段 | 核心目标 | 预计工时 | 优先级 |
|------|---------|---------|--------|
| **Phase A** | AI 人设重构 + 觉察日记 | 1-2 天 | P0 |
| **Phase B** | 数据安全加固 + 推送优化 | 1-2 天 | P1 |
| **Phase C** | 紧急联系人/社会契约 | 1 天 | P2 |

---

## Phase A：AI 人设重构 + 觉察日记（P0）

### A1. 重构 AI System Prompt — 从"健康教练"到"动机访谈倾听者"

**现状问题**：
- `LlmService.systemPrompt` 角色定位为"温暖、专业的戒烟/戒酒教练"
- 回应指南中包含大量"建议"类输出（"建议SOS呼吸"、"教授具体应对技巧"）
- 规则引擎 `AiCoachEngine` 和 `CoachResponseTemplates` 中存在爹味说教（"你需要新的工具"、"建议你"）
- 缺少对"无意愿用户"的专门处理逻辑

**修改范围**：

#### 1. `lib/core/coach/llm_service.dart` — `systemPrompt` 重写
- **角色设定**：从"戒烟/戒酒教练"改为"经历过沧桑、极度共情、不带任何评判色彩的老朋友"或"专业的动机访谈咨询师"
- **绝对禁止**：禁止输出"喝酒有害健康"、"你应该去跑步"、"建议你多喝水"等说教
- **核心沟通技巧**：强化 OARS 技巧说明，增加"接纳阻抗"规则
- **新增"无意愿用户"处理规则**：当用户明确表示不想戒时，AI 必须顺从并接纳

#### 2. `lib/core/coach/ai_coach_engine.dart` — 规则引擎响应重写
- **渴望处理**：移除直接建议（"试试按下SOS按钮"），改为共情反射+开放式提问
- **情绪处理**：移除"建议你"类输出，改为"你觉得这个情绪和你生活中的什么事有关？"
- **帮助请求**：不再直接给出列表式建议，而是先问"你之前试过什么方法？什么有效？"
- **新增"抗拒"handler**：检测"不想戒"、"别烦我"、"我就想喝"等关键词，以接纳+顺从回应
- **新增"价值观"handler**：检测用户提到的在乎事物（家人、孩子、工作、健康），用苏格拉底式提问引导发现矛盾

#### 3. `lib/core/coach/coach_response_templates.dart` — 模板全面重写
- 所有 `craving` 模板：去掉直接建议，改为反射性回应+提问
- 所有 `emotion` 模板：去掉"建议你"开头，改为共情+开放式提问
- 所有 `help` 模板：先了解再回应，不主动输出建议列表
- 新增 `resistance` 主题：接纳+顺从的响应模板
- 新增 `values` 主题：价值观冲突引导模板
- 更新 `initialQuickReplies`：增加"我今天感觉很糟"、"我喝了/抽了"、"我不想戒"等选项
- 更新 `quickRepliesByTopic`：各主题的快捷回复更偏向倾听式

#### 4. `lib/core/coach/llm_prompt_builder.dart` — 无需大改
- 现有数据构建逻辑合理，只需在用户上下文中增加"用户阶段"的权重提示

### A2. 新增"觉察日记"模块

**设计理念**：替代强制打卡。不想戒的用户可以诚实记录饮酒行为，AI 绝不批评。

**修改范围**：

#### 1. `lib/domain/entity/daily_log.dart` — 新增字段
- `isAwarenessLog`（bool）：标记为觉察日记（vs 传统打卡）
- `awarenessType`（String?）：觉察类型（'consumption'|'emotion'|'trigger'|'free'）
- `rawInput`（String?）：用户原始输入文本（觉察日记的核心内容）

#### 2. `lib/data/database/app_database.dart` — 数据库迁移
- 版本 9→10，ALTER TABLE 添加 `is_awareness_log`, `awareness_type`, `raw_input` 列

#### 3. `lib/presentation/action/daily_log/daily_log_screen.dart` — 重构为双模式
- 顶部增加 Tab 切换："每日打卡" | "觉察日记"
- **觉察日记模式**：
  - 自由文本输入区域（核心）：让用户用自己的话记录
  - 底部 3 个快捷按钮（降低门槛）：
    - "我今天感觉很糟，想喝酒" → 自动填充
    - "我刚才喝了，有点后悔" → 自动填充
    - "我不想戒，别烦我" → 自动填充
  - 无"是否复发"的道德判断
  - 保存后给予正向反馈（"谢谢你诚实面对自己的感受，觉察是改变的第一步"）
  - 可选：AI 共情回应（复用教练引擎的反射功能）

#### 4. `lib/core/router/app_router.dart` — 新增路由
- `/action/awareness-diary` → `AwarenessDiaryScreen`（如果决定拆分为独立页面）

#### 5. `lib/presentation/home/dashboard_screen.dart` — 首页入口
- 在"每日打卡"卡片旁增加"觉察日记"快捷入口

### A3. 微习惯设计（极简互动）

**修改范围**：

#### 1. `lib/presentation/home/dashboard_screen.dart`
- 新增"一键觉察"浮动按钮（FAB）或卡片
- 点击后只弹出一个底部 Sheet，显示 3-4 个情绪按钮
- 任何选择都给予正向反馈（"谢谢你今天打开了这个App"）

---

## Phase B：数据安全加固 + 推送优化（P1）

### B1. 加密本地 JSON 导出/导入

**现状**：`ExportScreen` 已有 JSON/CSV/Report 三种导出，但缺少导入功能。

**修改范围**：

#### 1. `lib/presentation/profile/export_screen.dart` — 新增导入功能
- 新增"导入数据"按钮（从文件选择器读取 JSON）
- 导入前显示预览（数据条数、日期范围）
- 导入策略：合并（保留两端数据，冲突取新值）或覆盖

#### 2. `lib/core/export/fhir_exporter.dart` — 新增全量 JSON 序列化/反序列化
- `exportFullData()`：将所有用户数据（profile + logs + cravings + badges + game + plans）序列化为加密 JSON
- `importFullData()`：反序列化并写入数据库
- 使用已有的 `EncryptionService` 进行 AES-256 加密

#### 3. `lib/core/sync/data_encryption.dart` — 复用加密模块
- 确保导出文件使用 AES-256-CBC 加密
- 文件后缀：`.quitmate-backup`

#### 4. `lib/data/repository/` — 各 Repository 新增批量导入方法
- `LogRepository.importLogs(List<DailyLogEntry>)`
- `CravingRepository.importCravings(List<CravingEntry>)`
- 等等

### B2. Android 后台保活引导

**修改范围**：

#### 1. `lib/presentation/onboarding/motivation_screen.dart`
- 在通知权限请求后，增加"防走失设置"引导步骤
- 检测是否需要引导（国产 ROM）：通过 `android.os.Build` 判断品牌
- 分步引导用户开启：
  - 自启动权限
  - 后台高耗电允许
  - 电池优化白名单

#### 2. `lib/core/notifications/notification_service.dart`
- 增加 `isNotificationWorking()` 检测方法
- 在 Dashboard 首次显示时检测，如果推送可能失效则提醒

---

## Phase C：紧急联系人/社会契约（P2）

### C1. 紧急联系人功能

**修改范围**：

#### 1. `lib/domain/entity/user.dart` — 新增字段
- `emergencyContacts`（List<EmergencyContact>?）
- 新增 `EmergencyContact` 实体类：name, phone, relation, isEnabled

#### 2. `lib/data/database/app_database.dart` — 新表
- `emergency_contacts` 表：id, user_id, name, phone, relation, is_enabled, created_at

#### 3. `lib/presentation/profile/settings_screen.dart` — 新增入口
- "紧急联系人"设置页：添加/编辑/删除联系人
- 一键发送预设求助短信的功能

#### 4. `lib/presentation/action/urge_toolkit/urge_toolkit_screen.dart`
- 在 SOS 工具包中新增"给朋友发个消息"选项
- 预设隐晦求助模板："我现在状态不太好，能给我打个电话聊聊吗？"
- 用户可自定义消息内容

#### 5. Android SMS 权限
- `AndroidManifest.xml` 添加 `SEND_SMS` 权限
- 运行时权限请求

---

## 验收标准

### Phase A
- [ ] LLM System Prompt 不包含任何"建议你"、"应该"类输出指令
- [ ] 规则引擎对"我不想戒"类输入返回接纳式回应
- [ ] 觉察日记可独立于打卡使用
- [ ] 觉察日记保存后显示正向反馈
- [ ] 快捷按钮可一键填充觉察内容

### Phase B
- [ ] 可导出加密 JSON 备份文件
- [ ] 可从加密 JSON 备份文件恢复数据
- [ ] 国产 ROM 首次启动有后台保活引导

### Phase C
- [ ] 可添加/编辑/删除紧急联系人
- [ ] SOS 工具包可一键发送求助短信
- [ ] 短信内容可自定义

---

*本文档由新任产品经理于 2026-06-21 基于产品迭代建议书制定。聚焦动机唤醒，从"监督者"到"陪伴者"。*