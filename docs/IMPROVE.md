# QuitMate 改进方案

> 基于 2026-06-20 用户反馈整理
> 整理人：Super Z（AI 代码审查 + 产品分析）

---

## 目录

- [反馈一：强制安装用户的留存问题](#反馈一强制安装用户的留存问题)
- [反馈二：Onboarding 启动成本过高](#反馈二onboarding-启动成本过高)
- [反馈三：「戒断的好处」内容过于笼统](#反馈三戒断的好处内容过于笼统)
- [反馈四：SOS 呼吸法节奏过快](#反馈四sos-呼吸法节奏过快)
- [反馈五：通知权限未在首次启动时获取](#反馈五通知权限未在首次启动时获取)
- [反馈六：LLM 能力未充分发挥](#反馈六llm-能力未充分发挥)
- [反馈七：桌面小组件内容单调、缺乏个性化](#反馈七桌面小组件内容单调缺乏个性化)
- [反馈八：LLM 上下文过长导致 Token 成本问题](#反馈八llm-上下文过长导致-token-成本问题)

---

## 反馈一：强制安装用户的留存问题

### 问题描述

对于被他人强制安装 QuitMate 的用户（如家人代装、企业 EAP 统一下发），当前设计存在严重的"即时流失"风险：

- 用户打开 App → 看到是戒烟/戒酒相关 → 毫无戒断意愿 → 立即退出
- 当前的 Welcome Screen 虽然已有"不管你是自己来的，还是被拉来的"文案，以及"我现在就很难受"的 SOS 入口，但对于被强制安装且无戒断意愿的用户来说，这两个入口都不够有吸引力——他们既不难受，也不想看自己的情况

### 当前实现

`presentation/onboarding/welcome_screen.dart` 提供了两条路径：
- **路径 A**："我现在就很难受" →  urge toolkit（SOS 呼吸法）
- **路径 B**："我想看看自己的情况" → reality check（现实检验）
- **路径 C**（底部小字）："我已经准备好了，直接开始" → assessment 问卷

### 改进方案

**核心思路：为"不想戒"的用户创造一个"无压力发现通道"，降低心理门槛，让他们在不承诺戒断的前提下先感受到价值。**

#### 1.1 新增第三条路径："我就随便看看"

在 Welcome Screen 增加第三张卡片，针对被拉来/无所谓/好奇心态的用户：

```
┌─────────────────────────────────────┐
│  🔍  "我就随便看看"                    │
│  "先了解一下，不做任何承诺"             │
└─────────────────────────────────────┘
```

点击后进入一个 **轻量级"Discovery 模式"**：
- 不要求填写问卷、不要求设置戒断目标
- 展示 2-3 个有趣的互动内容（如"算算你的肺龄"、"看看全国有多少人跟你一样"）
- 底部有一个低压力的提示："如果哪天你想戒了，随时回来，你的数据都在"

#### 1.2 优化文案策略

当前 Welcome Screen 的副标题"先花一分钟看看这个"已经是一个好的开始，但可以更具体、更有钩子：

```
当前：先花一分钟看看这个
改进：60 秒，看看这个习惯每年从你身上拿走了什么
```

让用户在退出之前产生一丝好奇。

#### 1.3 "Exit Intent" 机制

当用户在 Welcome Screen 点击返回键或准备退出时，弹出一次极简的挽留弹窗：

```
┌─────────────────────────────────────┐
│  等等，花 30 秒看看这个 →            │
│                                     │
│  "你知道吗？每天 10 根烟，           │
│   一年下来大约花费 ¥5,475"          │
│                                     │
│  [我想看看]          [不了，谢谢]     │
└─────────────────────────────────────┘
```

关键：弹窗内容必须是基于用户可能设定的消费数据的**个性化数字**，而非泛泛而谈。

#### 1.4 涉及文件

| 文件 | 改动 |
|------|------|
| `presentation/onboarding/welcome_screen.dart` | 新增第三条路径卡片 + Exit Intent 弹窗 |
| `presentation/onboarding/discovery_screen.dart`（新建） | Discovery 轻量浏览模式 |
| `core/router/app_router.dart` | 新增 `/onboarding/discovery` 路由 |

---

## 反馈二：Onboarding 启动成本过高

### 问题描述

当前流程：打开 App → 立刻让用户填问卷（FTND/AUDIT 评估）→ 设置现实检验数据 → 教育页面 → 动机页面 → 戒断日设定。

对于刚下载、还在观望的用户来说，一上来就要做题，心理负担太重，很容易放弃。

### 当前流程

```
Welcome → Reality Check（填数据）→ Assessment（FTND/AUDIT 问卷）→ Education（4 页教育）→ Motivation（选理由+打分）→ Quit Date Wizard
```

Reality Check 需要填写每日用量、花费、年数、年龄等 4 个数字字段，再加上 Assessment 的完整量表，在还没感受到任何价值之前就要输入大量信息。

### 改进方案

**核心思路：先给甜头，再要信息。让用户先体验核心价值（如健康恢复时间线），再逐步收集数据。**

#### 2.1 重构 Onboarding 流程为"价值前置"

```
新流程：
Welcome → 价值体验（展示恢复时间线/省钱计算，用默认值）→ 轻量现实检验（2 个字段：用量+花费）→ 设定戒断日 → 完成
                                                            ↓
                                              后续随时可补填 FTND/AUDIT（设置页入口）
```

具体变化：
1. **Reality Check 简化**：只保留"你每天抽多少"和"每包多少钱"两个核心字段，其余数据用合理的默认值填充
2. **FTND/AUDIT 评估后置**：从 Onboarding 流程中移除，改为用户主动进入时再填（设置页 → "评估我的依赖程度"）
3. **Education 页面合并精简**：4 页合并为 2 页，聚焦最有冲击力的内容（身体恢复 + 省钱计算）

#### 2.2 "渐进式数据收集"策略

| 阶段 | 收集什么 | 为什么在这个时机 |
|------|---------|----------------|
| 首次打开 | 无（直接看内容） | 降低门槛，先看价值 |
| 设置戒断日 | 目标类型 + 用量 + 花费 | 最小可用数据 |
| 首周使用中 | 每日打卡（心情/渴望） | 已有动机，数据有即时反馈 |
| 设置页 | FTND/AUDIT 量表 | 用户主动想了解自己时 |
| 首月后 | 更多个人数据 | 已形成习惯，愿意投入 |

#### 2.3 涉及文件

| 文件 | 改动 |
|------|------|
| `presentation/onboarding/reality_check_screen.dart` | 简化为 2 个必填字段 |
| `presentation/onboarding/education/education_screen.dart` | 4 页 → 2 页 |
| `presentation/onboarding/assessment/assessment_screen.dart` | 从 Onboarding 流程移除，改为设置页入口 |
| `core/router/app_router.dart` | 调整 Onboarding 路由顺序 |

---

## 反馈三：「戒断的好处」内容过于笼统

### 问题描述

Education Screen 第三页"戒断的好处"展示了 6 个维度：省钱、健康、心情、家人、精力、自信。

每个维度只显示了一行极简描述（如"省了"、"身体变好"、"情绪稳定"），没有展开说明：
- **为什么**家人关系会改善？
- **如果**不戒断，健康会有**什么严重后果**？
- **戒断后**心情能获得**什么样的**改善？
- 精力和自信具体体现在哪里？
- 省下的钱相当于什么（可视化锚点）？

### 当前实现

`education_screen.dart` 中 `_LifePage` 的 `_benefitGrid`：

```dart
const _benefitGrid = [
  _BenefitItem('💰', '省钱', '省了'),
  _BenefitItem('❤️', '健康', '身体变好'),
  _BenefitItem('😊', '心情', '情绪稳定'),
  _BenefitItem('👨‍👩‍👧', '家人', '关系改善'),
  _BenefitItem('🏃', '精力', '活力充沛'),
  _BenefitItem('🧠', '自信', '自控力强'),
];
```

每个 benefit 只有一个 emoji + 标题 + 6 字副标题，点击后没有任何展开。

### 改进方案

#### 3.1 将六宫格改为可展开的详情卡片

每个 benefit 从静态网格改为可点击的展开卡片：

| 维度 | 当前描述 | 改进后描述（展开） |
|------|---------|------------------|
| 💰 省钱 | "省了" | "按你每天 15 元算，一年省 ¥5,475，相当于一部新手机。十年省 ¥54,750，够一次全家旅行。如果继续，这笔钱只会越来越多。" |
| ❤️ 健康 | "身体变好" | "20 分钟后心率恢复正常；24 小时后心脏病发作风险开始降低；1 年后冠心病风险降低一半；5 年后中风风险降至非吸烟者水平。如果继续吸烟， COPD、肺癌、心血管疾病的风险持续上升。" |
| 😊 心情 | "情绪稳定" | "戒断初期可能有 2-3 周的焦虑波动，但之后情绪会显著改善。研究表明戒烟者抑郁症状减少，焦虑水平降低，整体心理幸福感提升。不戒的话，尼古丁的波动会让你长期处于焦虑-缓解的恶性循环中。" |
| 👨‍👩‍👧 家人 | "关系改善" | "二手烟/酒气会导致家人呼吸道疾病风险增加 20-30%，儿童中耳炎风险增加。戒断后，家庭氛围更和谐，家人不再为你担心。你的孩子也更不容易模仿这个习惯。" |
| 🏃 精力 | "活力充沛" | "戒断后血氧水平提升，体力恢复明显。原本爬三层楼就喘，一个月后你会发现耐力显著改善。运动表现提升，不再每天午后犯困。不戒的话，长期缺氧会让你的体力持续下降。" |
| 🧠 自信 | "自控力强" | "每成功抵抗一次渴望，你的前额叶皮层就在强化。这不是鸡汤——神经科学证实意志力像肌肉，越练越强。成功戒断的人普遍报告更高的自我效能感和生活掌控感。" |

#### 3.2 增加"不戒的代价"对比视角

在每个好处卡片中增加一个"如果继续"的对比说明，利用"损失厌恶"心理：
- 人对失去的敏感度约为获得的 2 倍（Kahneman & Tversky, 1979）
- "如果继续"比"如果戒掉"更有冲击力

#### 3.3 使用用户的真实数据动态生成

结合 Reality Check 中用户输入的每日花费和用量，动态计算：
- "按你每天 X 元的花费，一年就是 ¥XXX"
- "按你每天 X 支的用量，一年你吸入的焦油相当于 XX 盒"

这需要将 Reality Check 的数据在进入 Education 之前持久化，并在 Education 页面读取。

#### 3.4 涉及文件

| 文件 | 改动 |
|------|------|
| `presentation/onboarding/education/education_screen.dart` | `_LifePage` 从静态网格改为可展开详情卡片 |
| `domain/entity/user.dart` | 确保有 `dailyCost`、`dailyConsumption` 字段可读取 |
| `assets/content/education/`（新建） | 将 benefits 详细文案抽为 JSON 资源文件，支持动态替换用户数据 |

---

## 反馈四：SOS 呼吸法节奏过快

### 问题描述

首页底部的"渴望来了，呼吸一下"按钮打开后，呼吸引导的节奏太快，用户跟不上。

### 当前实现

存在两套呼吸引导，节奏不一致：

**1. `sos_breathing_sheet.dart`（首页 SOS 按钮）**
- `AnimationController` 的 `duration` 为 `Duration(seconds: 4)`，即一个完整吸-呼循环只有 4 秒
- 阶段判定：`breathValue < 0.4` → 吸气，`0.4-0.6` → 屏息，`> 0.6` → 呼气
- 这意味着：吸气 1.6s，屏息 0.8s，呼气 1.6s — 远快于标准的 4-7-8 呼吸法

**2. `immersive_breathing_guide.dart`（Urge Toolkit 内）**
- `_inhaleDuration = 4`，`_holdDuration = 7`，`_exhaleDuration = 8`
- 标准的 4-7-8 呼吸法，节奏正确

### 改进方案

#### 4.1 统一呼吸节奏为标准 4-7-8

修改 `sos_breathing_sheet.dart` 的 `AnimationController`：

```dart
// 当前（错误，太快）
_breathController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 4),  // 一个循环 4s
)..repeat(reverse: true);

// 修复后（标准 4-7-8 呼吸法）
// 吸气 4s + 屏息 7s + 呼气 8s = 一个循环 19s
// 但 AnimationController 的 repeat(reverse) 不适合非对称节奏
// 需要改用 Timer + 状态机方式
```

由于 4-7-8 的三个阶段不等长（4s ≠ 8s），不能用简单的 `repeat(reverse: true)`，需要改用 `ImmersiveBreathingGuide` 中的 Timer + 状态机方式。

#### 4.2 具体实现建议

参考 `immersive_breathing_guide.dart` 中已有的 `_BreathPhase` 枚举和循环计算逻辑，将其中的呼吸节奏参数复用到 `sos_breathing_sheet.dart`：

```dart
// 从 immersive_breathing_guide.dart 中提取共享常量
class BreathTiming {
  static const int inhaleSeconds = 4;
  static const int holdSeconds = 7;
  static const int exhaleSeconds = 8;
  static const int cycleSeconds = inhaleSeconds + holdSeconds + exhaleSeconds; // 19
}
```

#### 4.3 涉及文件

| 文件 | 改动 |
|------|------|
| `presentation/home/sos_breathing_sheet.dart` | 重写呼吸动画逻辑，对齐 4-7-8 节奏 |
| `core/constants/breath_timing.dart`（新建） | 提取共享呼吸节奏常量 |
| `presentation/action/urge_toolkit/widgets/immersive_breathing_guide.dart` | 引用共享常量，消除重复 |

---

## 反馈五：通知权限未在首次启动时获取

### 问题描述

App 依赖通知来发送关怀提醒、渴望预警等关键消息，但：
1. **Notification 权限请求时机错误**：`NotificationService.initialize()` 在 `main.dart` 中 `AppErrorHandler` 之后立即调用，此时用户还在看启动页/PIPL 同意页
2. **用户感知为零**：权限请求在后台静默执行，用户甚至不知道通知功能需要授权
3. **Android 13+ 需要 POST_NOTIFICATIONS 运行时权限**：如果用户拒绝且从未在设置中手动开启，后续所有通知全部失败
4. **没有二次请求机制**：用户拒绝权限后，没有任何引导或二次请求

### 当前实现

`main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppErrorHandler.initialize();
  await NotificationService.instance.initialize();  // ← 权限请求在这里，但用户还在启动页
  runApp(...);
}
```

`notification_service.dart` 的 `_requestNotificationPermission()` 在 `initialize()` 中被调用，会在 `main()` 阶段弹系统权限对话框——用户还没看到 App 长什么样就收到了权限请求。

### 改进方案

#### 5.1 延迟权限请求到"价值锚点"

**原则：先让用户感受到"我为什么需要通知"，再请求权限。**

最佳时机：在 Onboarding 流程中，用户设定戒断日之后，弹出引导说明：

```
┌─────────────────────────────────────────┐
│  🔔 每天给你一句提醒                     │
│                                         │
│  在你最需要的时候，我会给你发一条提醒，   │
│  帮你撑过那些关键时刻。                   │
│                                         │
│  我们承诺：                               │
│  ✅ 每天最多 3 条通知                     │
│  ✅ 绝对不在深夜发送                      │
│  ✅ 你可以随时关闭                        │
│                                         │
│  [好的，开启提醒]        [以后再说]       │
└─────────────────────────────────────────┘
```

用户点击"好的，开启提醒"后，才调用系统权限请求。如果用户选择"以后再说"，在设置页保留二次入口。

#### 5.2 Notification 权限请求拆分

| 时机 | 操作 | 原因 |
|------|------|------|
| `main.dart` | `initialize()` **不请求权限**，只初始化插件和通道 | 避免启动时弹权限对话框 |
| Onboarding 戒断日设定后 | 弹出引导说明 → 用户同意 → 请求 POST_NOTIFICATIONS | 用户已理解价值 |
| 设置页 | "通知设置" → 检查权限状态 → 未开启则引导 | 二次入口 |
| 渴望高峰时 | 调用 `scheduleUrgeReminder()` | 需要权限已被授予 |

#### 5.3 国产 ROM 兼容增强

华为/小米/OPPO/vivo 等国产 ROM 的通知权限管理更复杂（可能有"允许通知"、"锁屏显示"、"横幅通知"三个独立开关）。建议：
- 在权限被授予后，检测通知是否真的能正常送达（发一条测试通知）
- 如果测试失败，引导用户去系统设置手动开启

#### 5.4 涉及文件

| 文件 | 改动 |
|------|------|
| `main.dart` | `initialize()` 中不再自动请求权限 |
| `core/notifications/notification_service.dart` | 拆分 `initialize()` 和 `requestPermission()` |
| `presentation/onboarding/quit_date_wizard/quit_date_wizard_screen.dart` | 戒断日设定后弹出通知权限引导 |
| `presentation/profile/settings_screen.dart` | 增加通知权限状态检测 + 二次请求入口 |

---

## 反馈六：LLM 能力未充分发挥

### 问题描述

LLM（大语言模型）是一个"超级大脑"，但当前应用对 LLM 的使用还比较浅层。具体表现：

1. **LLM 仅用于 AI Coach 对话**：用户需要主动打开聊天界面才能获得 LLM 的帮助
2. **LLM 没有被用于个性化内容生成**：如教育页面的好处说明、每日洞察等都是硬编码的
3. **LLM 没有被用于通知内容**：通知文案固定，无法根据用户数据动态生成
4. **LLM 没有被用于桌面组件**：组件内容固定，无法提供个性化关怀

### 当前 LLM 使用情况

| 功能 | 是否使用 LLM | 当前实现 |
|------|-------------|---------|
| AI Coach 对话 | ✅ | `llm_service.dart` 的 `chat()` 方法 |
| 行为分析 | ✅ | `analyzePatterns()` — 增强本地 PatternAnalyzer |
| 每日洞察 | ✅ | `generatePersonalizedInsight()` |
| 周报生成 | ✅ | `generateWeeklyReport()` |
| 教育内容 | ❌ | 硬编码在 `education_screen.dart` |
| 通知文案 | ❌ | 固定文案 |
| 桌面组件文案 | ❌ | `WidgetTips` 静态轮换（10 条） |
| 呼吸引导文案 | ❌ | 固定文案 |

### 改进方案

#### 6.1 LLM 驱动的通知内容

当前通知是固定文案，改为根据用户数据动态生成：

```
场景：用户已戒烟 3 天，昨天有 2 次高强度渴望
LLM 生成通知：
  "你已经坚持了 3 天，昨天的两次渴望你都扛过来了。
   今天上午 10-11 点是你的高风险时段，提前准备一下。"
```

实现要点：
- 每日清晨调用 `generatePersonalizedInsight()` 生成当天通知
- 如果 LLM 未启用/不可用，回退到 `WidgetTips.getTipOfTheDay()` 静态文案
- 通知文案缓存到本地，避免重复调用

#### 6.2 LLM 驱动的教育内容个性化

当前 `_LifePage` 的好处说明是硬编码的，改为：
- 用户填完 Reality Check 后，用 LLM 根据用户的具体数据（每日用量、花费、年限）生成个性化的好处说明
- 如："你每天抽 10 支烟，按目前的市场价，一年花在烟上的钱约 ¥5,475——这够买一部新手机了。如果继续 10 年，就是 ¥54,750。"
- 缓存生成结果，避免每次打开都重新生成

#### 6.3 LLM 作为"后台分析师"

当前的 AI Coach 是被动式的（用户主动对话才响应），增加主动式能力：
- 每周自动分析用户数据变化趋势，生成周报推送
- 在检测到风险升高时（连续 3 天渴望强度上升），主动推送关怀消息
- 检测到"沉默期"（3 天未打开 App），推送温和的召回消息

#### 6.4 涉及文件

| 文件 | 改动 |
|------|------|
| `core/notifications/notification_service.dart` | 支持从 LLM 获取动态通知文案 |
| `core/coach/daily_insight_generator.dart` | 增加通知文案生成模式 |
| `core/coach/llm_prompt_builder.dart` | 增加通知文案的 prompt 模板 |
| `presentation/onboarding/education/education_screen.dart` | 读取 LLM 生成的个性化好处说明 |
| `core/widgets/widget_service_v2.dart` | 集成 LLM 生成的每日关怀语（详见反馈七） |

---

## 反馈七：桌面小组件内容单调、缺乏个性化

### 问题描述

当前的桌面小组件存在以下问题：

1. **只有一种卡片样式**：展示恢复天数、省了多少钱、生命长了多少、SOS 按钮——纯数据展示，缺乏情感连接
2. **内容千篇一律**：每天只有数据数字在变化，文案完全一样，很快失去新鲜感
3. **缺少关怀和激励内容**：没有个性化的话语来触动用户
4. **WidgetTips 只有 10 条静态轮换**：`WidgetTips.getTipOfTheDay()` 基于日期伪随机从 10 条固定文案中选一条，内容是通用建议，而非个性化关怀

### 当前实现

`widget_service.dart`（原版）：
- 传递 5 个数据字段：`widget_days`、`widget_money`、`widget_life`、`widget_recovery`、`widget_progress`
- 纯数据展示

`widget_service_v2.dart`（增强版，但改进有限）：
- 增加了更多字段：`risk_label`、`daily_tasks_completed` 等
- `WidgetTips` 仍然是 10 条静态文案
- 没有个性化内容生成

### 改进方案

#### 7.1 多种小组件卡片类型

提供 3 种可选的桌面小组件卡片：

| 类型 | 内容 | 目的 |
|------|------|------|
| **数据卡** | 恢复天数 + 省了多少钱 + SOS 按钮 | 信息概览（当前已有） |
| **关怀卡** | LLM 生成的每日个性化话语 | 情感连接，每天不同 |
| **警示卡** | 高危时段预警 + 当日风险等级 | 行动提醒，放在手机主屏有警示作用 |

用户可以在设置中自由组合和选择显示哪种卡片。

#### 7.2 LLM 驱动的个性化关怀文案

这是本次改进的核心亮点。**不是每天贴一句鸡汤**，而是基于用户真实数据的"灵魂拷问"。

**设计原则**：
1. **基于数据**：结合用户的戒断天数、近期渴望记录、心情趋势、连胜天数等
2. **灵魂拷问而非鸡汤**："你今天第 15 天了，上周三你因为压力差点破戒。今天有什么计划应对压力吗？" vs "加油，你是最棒的！"
3. **每天不同**：基于前一天的数据变化动态生成
4. **不重复**：缓存最近 7 天的文案，确保不重复

**LLM Prompt 模板**（新增）：

```
你是一位关心用户的戒烟/戒酒助手。请基于用户数据生成一句简短的桌面组件关怀语。

要求：
1. 不超过 30 个字
2. 必须引用用户的具体数据（天数、渴望次数、心情等）
3. 不要说"加油"之类的空话
4. 可以是一个问题、一个提醒、或者一个事实
5. 语气像关心你的朋友，不是老师也不是教练

用户数据：
- 戒断天数：{days}
- 昨天心情：{mood}/5
- 昨天渴望次数：{craving_count} 次
- 连续打卡：{streak} 天
- 本周风险等级：{risk_level}

输出格式：直接输出一句话，不要引号。
```

**示例输出**（基于不同用户状态）：

| 用户状态 | LLM 生成文案 |
|---------|-------------|
| 戒断第 3 天，情绪低落 | "前三天最难熬，你正在经历正常的戒断反应，不是退步" |
| 连续 14 天，状态好 | "两周了，你身体里的尼古丁受体已经减少了 50%" |
| 昨天破戒了 | "昨天的事已经过去了，你的最长纪录是 11 天，现在重新开始" |
| 高风险日（上午 10-11 点） | "上午 10 点是你最难熬的时候，准备好应对方案了吗？" |
| 连续 7 天，心情好 | "一周了。你比 97% 在第三天放弃的人走得更远" |

#### 7.3 警示卡的高危时段动态展示

```
┌─────────────────────────────────────┐
│  ⚠️ 今日高风险时段                    │
│                                     │
│  上午 10:00 - 11:00                  │
│  基于你过去两周的渴望记录分析          │
│                                     │
│  [提前准备]                           │
└─────────────────────────────────────┘
```

这与 `CravingPredictor` 的 `highRiskWindows` 联动。

#### 7.4 涉及文件

| 文件 | 改动 |
|------|------|
| `core/widgets/widget_service_v2.dart` | 增加 3 种卡片类型的数据模型 + LLM 关怀语生成 |
| `core/coach/llm_prompt_builder.dart` | 新增 `buildWidgetInsightPrompt()` |
| `android/app/src/main/res/layout/quitmate_widget_layout.xml` | 新增关怀卡和警示卡布局 |
| `android/app/src/main/kotlin/org/quitmate/app/QuitMateWidgetProvider.kt` | 支持多卡片类型渲染 |
| `presentation/profile/settings_screen.dart` | 增加小组件类型选择 |

---

## 反馈八：LLM 上下文过长导致 Token 成本问题

### 问题描述

当前 `LlmPromptBuilder.buildWeekDataText()` 会将用户一周的每日详情 + 20 条渴望明细全部拼入 Prompt：

```
## 每日详情
- 6/15: 心情3/5, 渴望6/10 ✅ 触发：压力,社交
- 6/16: 心情4/5, 渴望4/10 ✅ 触发：无聊
...（7 天 × 约 80 字/天 = 560 字）

## 渴望明细（最近20条）
- 6/15 10:30 强度7/10 触发：压力 地点：办公室 ✅
...（20 条 × 约 60 字/条 = 1200 字）
```

加上 system prompt（约 800 字）、user context（约 300 字）、local analysis（约 500 字），一次周报生成的 input tokens 估计在 **3,000-4,000 字（约 6,000-8,000 tokens）**。

虽然 GPT-4o Mini 的价格很低（input $0.15/1M tokens），但随着功能扩展（反馈六中提出的多场景 LLM 调用），每日调用量可能从 1-2 次增加到 4-6 次，长期成本仍需关注。

### 当前 LLM 调用场景及 Token 估算

| 场景 | 频率 | 估算 Input Tokens | 估算 Output Tokens |
|------|------|-------------------|-------------------|
| AI Coach 对话 | 用户触发 | ~1,500（含对话历史） | ~300 |
| 每日洞察 | 每日 1 次 | ~2,000 | ~200 |
| 周报 | 每周 1 次 | ~6,000 | ~800 |
| 通知文案（新增） | 每日 1 次 | ~1,500 | ~100 |
| Widget 关怀语（新增） | 每日 1 次 | ~1,000 | ~60 |
| **合计（每日）** | | **~4,500** | **~460** |

按 GPT-4o Mini 定价：
- Input: $0.15/1M → 每日 ~$0.0007
- Output: $0.60/1M → 每日 ~$0.0003
- **每日总成本 < ¥0.01 元**，月成本 < ¥0.3 元

### 改进方案

#### 8.1 上下文压缩策略

虽然当前成本极低，但为了长期可持续性和功能扩展空间，仍建议实施上下文压缩：

**1. 本地聚合替代原始数据**

当前：发送 20 条原始渴望明细
改进：先用 `PatternAnalyzer` 在本地聚合，只发送聚合后的摘要

```dart
// 当前
## 渴望明细（最近20条）
- 6/15 10:30 强度7/10 触发：压力 地点：办公室 ✅
- 6/15 14:15 强度5/10 触发：无聊 地点：家 ✅
...

// 改进后
## 本周渴望摘要
- 总次数：12 次，成功抵抗 10 次（83%）
- 高峰时段：上午 10-11 点（4 次）
- Top 3 触发因素：压力（5 次,42%）、社交（3 次,25%）、无聊（2 次,17%）
- 平均强度：5.8/10，呈下降趋势
- 高风险日：周三（3 次渴望，平均强度 7.3）
```

**2. 对话历史滑动窗口**

AI Coach 对话历史不要无限累积，保留最近 10 轮 + 摘要：
- 最近 10 轮对话的完整记录
- 10 轮之前的对话压缩为一句话摘要

**3. 缓存机制**

| 数据类型 | 缓存策略 | 原因 |
|---------|---------|------|
| 每日洞察 | 每日生成一次，缓存 24 小时 | 用户不会反复查看同一天的洞察 |
| Widget 关怀语 | 每日生成一次，缓存到次日零点 | 桌面组件每天刷新一次 |
| 通知文案 | 与每日洞察共用，不单独调用 | 避免重复调用 |
| 周报 | 每周生成一次，缓存到下周 | 数据不会频繁变化 |
| AI Coach 对话 | 不缓存，但压缩历史 | 需要实时响应 |

#### 8.2 成本监控

在 `LlmService` 中增加 token 使用量统计：

```dart
class LlmUsageTracker {
  int totalInputTokens = 0;
  int totalOutputTokens = 0;
  int totalCalls = 0;

  void record(int inputTokens, int outputTokens) {
    totalInputTokens += inputTokens;
    totalOutputTokens += outputTokens;
    totalCalls++;
  }

  double estimateCost() {
    // GPT-4o Mini pricing
    final inputCost = totalInputTokens * 0.15 / 1_000_000;
    final outputCost = totalOutputTokens * 0.60 / 1_000_000;
    return inputCost + outputCost;
  }
}
```

#### 8.3 涉及文件

| 文件 | 改动 |
|------|------|
| `core/coach/llm_prompt_builder.dart` | `buildWeekDataText()` 改用聚合摘要替代原始数据 |
| `core/coach/pattern_analyzer.dart` | 增加数据聚合方法 |
| `core/coach/conversation_context.dart` | 增加对话历史滑动窗口 + 摘要 |
| `core/coach/llm_service.dart` | 增加 `LlmUsageTracker` |
| `data/database/app_database.dart` | 新增 `llm_usage` 表用于持久化统计 |

---

## 改进优先级排序

| 优先级 | 反馈 | 理由 | 预估工时 |
|--------|------|------|---------|
| **P0** | 反馈四：SOS 呼吸法节奏过快 | 纯技术 bug，直接修复 | 2-3h |
| **P0** | 反馈五：通知权限获取时机 | 影响核心功能（通知），当前实现等于无效 | 3-4h |
| **P1** | 反馈一：强制安装用户留存 | 直接影响新增用户留存率 | 1-2 天 |
| **P1** | 反馈二：Onboarding 启动成本 | 直接影响转化率 | 1-2 天 |
| **P1** | 反馈三：好处内容笼统 | 影响用户决策，内容升级 | 1-2 天 |
| **P2** | 反馈七：桌面小组件个性化 | 功能增强，依赖 LLM 能力 | 2-3 天 |
| **P2** | 反馈六：LLM 能力充分发挥 | 功能增强，涉及多模块改动 | 2-3 天 |
| **P3** | 反馈八：LLM Token 成本优化 | 当前成本极低，可后置 | 1-2 天 |

**建议执行顺序**：反馈四 → 反馈五 → 反馈一 → 反馈二 → 反馈三 → 反馈七 → 反馈六 → 反馈八

---

*本文档由 Super Z 于 2026-06-20 基于用户反馈整理。所有改动建议均基于当前源码分析，具体实现方案供开发参考。*
