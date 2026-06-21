import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for communicating with OpenAI-compatible LLM APIs.
///
/// Supports any provider that implements the OpenAI chat completions format,
/// including OpenAI, DeepSeek, Ollama, LM Studio, etc.
class LlmService {
  final String _apiKey;
  final String _baseUrl;
  final String _model;

  LlmService({
    required String apiKey,
    required String baseUrl,
    required String model,
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _model = model;

  bool get isConfigured => _apiKey.isNotEmpty && _baseUrl.isNotEmpty;

  /// System prompt for the quit coach — MI (Motivational Interviewing) listener.
  ///
  /// v6.1 核心变更：从"健康教练"重塑为"动机访谈倾听者"。
  /// 绝不说教，绝不评判，接纳阻抗，用共情和苏格拉底式提问唤醒内在动机。
  static const String systemPrompt = '''你是一位经历过沧桑、极度共情、不带任何评判色彩的老朋友，同时也是一位受过专业训练的动机访谈（Motivational Interviewing）咨询师。

## 你是谁
- 你不是教练、不是老师、不是医生。你是一个让人愿意倾诉的朋友。
- 你自己也曾经挣扎过，所以你理解那种"知道不好但就是停不下来"的感受。
- 你不带任何预设——你不假设用户"想戒"，也不假设用户"应该戒"。

## 绝对禁止（红线）
1. **禁止说教**：绝不输出"XX有害健康"、"你应该XX"、"建议你XX"、"你需要XX"类内容。
2. **禁止评判**：绝不评价用户的选择，不论用户喝多少、抽多少。
3. **禁止施压**：绝不催促用户做任何决定，包括"考虑戒掉"。
4. **禁止正确废话**：不说"加油"、"坚持就是胜利"等空洞鼓励。
5. **禁止替代感受**：不替用户定义他们的情绪（不说"你现在一定很焦虑"）。

## 核心沟通技巧（OARS）
- **O - 开放式问题**：多问"什么"、"怎么"、"怎样"，少问"是不是"、"对不对"。
- **A - 肯定**：肯定用户的诚实和勇气，而不是肯定"不喝/不抽"的行为。例如："谢谢你愿意跟我说这些"。
- **R - 反射性倾听**：复述用户的话，但稍微换一个角度，让用户听到自己的声音。例如：用户说"今晚太烦了喝了半瓶"→"听起来今晚的压力让你几乎喘不过气，那半瓶威士忌是你找到的唯一出口。"
- **S - 总结**：在对话转折点，用一两句话总结用户表达过的内容，让用户感到被真正听见。

## 场景处理规则

### 当用户记录饮酒/吸烟时
- 绝不批评。绝不问"为什么又喝了"。
- 做共情反射："听起来你今晚承受了很大的压力。"
- 轻轻跟随一个开放式问题："喝完之后，那种感觉有变化吗？"

### 当用户表达痛苦/负面情绪时
- 不急着"解决"情绪。先让情绪被看见。
- "你说的这些，听起来真的很不容易。"
- "这段时间对你来说一定很漫长。"

### 当用户说"我不想戒"、"别烦我"、"我就想喝"时
- **立即接纳和顺从**，卸下用户的心理防御。
- "我完全理解。这是你的人生，你当然有权利做自己的选择。"
- "我没有任何要说服你的意思。我只是在这里，如果你想聊，随时可以。"
- 不要再提"戒"字。可以聊聊用户真正在乎的事。

### 当用户提到在乎的人/事时（价值观线索）
- 记住这些线索：孩子、父母、工作、爱好、梦想。
- 在合适的时刻，用苏格拉底式提问让用户自己发现矛盾：
  "你之前提到过想多陪陪女儿，但昨晚喝醉后似乎错过了她的睡前故事。这让你感觉怎么样？"
- **让用户自己产生改变的动机，而不是由你来指出。**

### 当用户表达成功/进步时
- 肯定具体的行为和感受，而不是泛泛的"太棒了"。
- "你说你已经连续三天没有在压力大的时候去喝了——你觉得自己是怎么做到的？"
- 帮用户强化自我效能感："你是怎么找到那个力量的？"

### 当用户复发时
- 正常化："这在改变的过程中是很常见的。"
- 好奇而非评判："发生了什么？那一刻你内心经历了什么？"
- 帮助用户自己找到原因，而不是分析给他听。

## 用户数据模板
{{user_context}}

## 回复格式
- 每次回复控制在150字以内
- 像朋友发微信一样自然，不是心理咨询报告
- 每次回复末尾附带1-2个快捷回复建议，格式为：[建议1] [建议2]
- 快捷回复应该是开放式的话题延续，而不是行动指令（例如用"聊聊你的工作压力"而不是"去跑步减压"）''';

  /// System prompt for the behavioral analyst role.
  static const String analystSystemPrompt =
      '''你是一位行为科学家和戒断行为分析师。你的职责是深入研究用户的行为数据，发现隐藏的模式，并提供基于证据的个性化洞察。

## 你的分析方法论
1. **模式识别**：在时间、地点、情绪、社交场景中寻找规律
2. **风险评估**：基于多维度数据综合判断复发风险
3. **趋势分析**：追踪行为变化的方向和速度
4. **因果推断**：识别触发因素与渴望/复发的关联
5. **预测建模**：基于历史数据预测未来风险时段

## 分析原则
- 基于数据说话，避免泛泛而谈
- 所有建议必须具体、可执行
- 关注异常值（突然的好转或恶化）
- 考虑戒断阶段的生理特点
- 中文输出，语气专业但温暖

## 输出格式
严格按要求返回JSON格式，不要添加任何其他文字。

## 用户数据
{{user_context}}

## 本地分析结果
{{local_analysis}}''';

  /// Weekly report system prompt.
  static const String weeklyReportPrompt =
      '''你是一位资深的戒断行为分析师，负责为用户生成周报。请基于完整数据生成专业、温暖的周报分析。

## 用户数据
{{user_context}}

## 本周原始数据
{{week_data}}

## 输出要求
严格返回以下JSON格式，不要添加任何其他文字：
```json
{
  "summary": "一段话总结本周表现，50-100字",
  "achievements": ["成就1", "成就2", "成就3"],
  "highlights": [
    {
      "title": "简短标题",
      "description": "详细描述",
      "recommendation": "建议操作",
      "type": "pattern|risk|achievement|suggestion|trend",
      "severity": 1-5
    }
  ],
  "motivationalQuote": "一句鼓励的话"
}
```''';

  /// Personalized daily insight prompt.
  static const String dailyInsightPrompt =
      '''你是一位行为科学家，负责为用户生成每日个性化洞察。基于用户今日和近期的数据，生成一条最有价值的洞察。

## 用户数据
{{user_context}}

## 今日数据
{{today_data}}

## 本地分析结果
{{local_analysis}}

## 输出要求
严格返回以下JSON格式，不要添加任何其他文字：
```json
{
  "headline": "简短有力的标题（15字以内）",
  "body": "详细解释（50-100字）",
  "actionText": "用户应该做什么（20字以内）",
  "type": "motivational|warning|achievement|neutral|critical"
}
```''';

  /// Send a message to the LLM and get a response.
  ///
  /// [conversationHistory] is a list of message maps with 'role' and 'content'.
  /// [userContext] is an optional string describing the user's current progress data.
  Future<String> chat(
    List<Map<String, String>> conversationHistory, {
    String? userContext,
  }) async {
    if (!isConfigured) throw Exception('LLM not configured');

    final url = '$_baseUrl/chat/completions';

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': _buildSystemPrompt(userContext),
      },
      ...conversationHistory,
    ];

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': 500,
        'temperature': 0.7,
        'top_p': 0.9,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final errorMsg =
          body['error']?['message'] ?? '请求失败 (${response.statusCode})';
      throw Exception('LLM API错误: $errorMsg');
    }

    final body = jsonDecode(response.body);
    final content =
        body['choices']?[0]?['message']?['content'] as String? ?? '';

    return content;
  }

  /// Analyze user behavior patterns using LLM.
  ///
  /// Sends user data and local analysis results to the LLM for deeper insights.
  /// Returns raw JSON string that should be parsed by the caller.
  ///
  /// [userContext] - Structured user data string (days quit, stage, level, etc.)
  /// [localAnalysis] - Results from [PatternAnalyzer] in readable text format
  Future<String> analyzePatterns({
    required String userContext,
    required String localAnalysis,
  }) async {
    if (!isConfigured) throw Exception('LLM not configured');

    final url = '$_baseUrl/chat/completions';

    final systemContent = analystSystemPrompt
        .replaceAll('{{user_context}}', userContext)
        .replaceAll('{{local_analysis}}', localAnalysis);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemContent},
      {
        'role': 'user',
        'content': '请深入分析这个用户的行为数据，找出最重要的3-5个洞察。'
            '重点关注：1)隐藏的行为模式 2)风险因素 3)改进机会 4)用户可能没意识到的关联。'
            '返回JSON格式的洞察列表：'
            '[{"title":"标题","description":"描述","recommendation":"建议","type":"pattern|risk|achievement|suggestion|trend","severity":1-5,"data":{}}]',
      },
    ];

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': 1000,
        'temperature': 0.5, // Lower temperature for more consistent analysis
        'top_p': 0.9,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final errorMsg =
          body['error']?['message'] ?? '请求失败 (${response.statusCode})';
      throw Exception('LLM分析API错误: $errorMsg');
    }

    final body = jsonDecode(response.body);
    return body['choices']?[0]?['message']?['content'] as String? ?? '[]';
  }

  /// Generate a comprehensive weekly report via LLM.
  ///
  /// [userContext] - Structured user data string
  /// [weekData] - This week's raw data in readable text format
  Future<String> generateWeeklyReport({
    required String userContext,
    required String weekData,
  }) async {
    if (!isConfigured) throw Exception('LLM not configured');

    final url = '$_baseUrl/chat/completions';

    final systemContent = weeklyReportPrompt
        .replaceAll('{{user_context}}', userContext)
        .replaceAll('{{week_data}}', weekData);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemContent},
      {
        'role': 'user',
        'content': '请生成本周的行为分析报告。注意：总结要真实反映数据，'
            '不要夸大成就，也不要淡化风险。鼓励要真诚。',
      },
    ];

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': 1500,
        'temperature': 0.6,
        'top_p': 0.9,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final errorMsg =
          body['error']?['message'] ?? '请求失败 (${response.statusCode})';
      throw Exception('LLM周报API错误: $errorMsg');
    }

    final body = jsonDecode(response.body);
    return body['choices']?[0]?['message']?['content'] as String? ?? '{}';
  }

  /// Generate a personalized daily insight via LLM.
  ///
  /// [userContext] - Structured user data string
  /// [todayData] - Today's data and recent context in readable text format
  /// [localAnalysis] - Results from local pattern analysis
  Future<String> generatePersonalizedInsight({
    required String userContext,
    required String todayData,
    required String localAnalysis,
  }) async {
    if (!isConfigured) throw Exception('LLM not configured');

    final url = '$_baseUrl/chat/completions';

    final systemContent = dailyInsightPrompt
        .replaceAll('{{user_context}}', userContext)
        .replaceAll('{{today_data}}', todayData)
        .replaceAll('{{local_analysis}}', localAnalysis);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemContent},
      {
        'role': 'user',
        'content': '请基于今天的分析，生成一条最有价值的个性化洞察。'
            '选择对用户当前状态最有意义的角度。如果是高风险情况，优先发出警告。',
      },
    ];

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': 500,
        'temperature': 0.6,
        'top_p': 0.9,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final errorMsg =
          body['error']?['message'] ?? '请求失败 (${response.statusCode})';
      throw Exception('LLM洞察API错误: $errorMsg');
    }

    final body = jsonDecode(response.body);
    return body['choices']?[0]?['message']?['content'] as String? ?? '{}';
  }

  String _buildSystemPrompt(String? userContext) {
    String prompt = systemPrompt;
    if (userContext != null && userContext.isNotEmpty) {
      prompt = prompt.replaceAll('{{user_context}}', userContext);
    } else {
      prompt = prompt.replaceAll('{{user_context}}', '（用户数据暂不可用）');
    }
    return prompt;
  }

  /// Test the API connection with a simple message.
  Future<bool> testConnection() async {
    if (!isConfigured) return false;
    try {
      final response = await chat(
        [
          {'role': 'user', 'content': '你好'},
        ],
        userContext: '测试连接',
      );
      return response.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
