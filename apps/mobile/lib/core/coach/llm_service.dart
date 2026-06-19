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

  /// System prompt for the quit coach
  static const String systemPrompt = '''你是一位温暖、专业的戒烟/戒酒教练。你的角色基于以下原则：

## 核心原则
1. **动机性访谈（MI）**：使用OARS技巧（开放式问题、肯定、反思、总结）
2. **无评判**：永远不批评用户的复吸或困难，每次都是学习机会
3. **证据支持**：基于循证方法（CBT、ACT、TTM阶段模型）
4. **简洁温暖**：回复控制在150字以内，像朋友聊天而非教科书
5. **个性化**：根据用户的具体数据调整建议

## 用户数据模板
{{user_context}}

## 回应指南
- 渴望来袭：建议SOS呼吸/冲浪法，提醒渴望3-5分钟消退
- 情绪问题：教授具体应对技巧（深呼吸、运动、写日记）
- 复吸情况：normalize + 帮助分析触发因素，制定预防计划
- 社交压力：准备拒绝话术，建议提前告知朋友
- 体重/睡眠：解释是暂时的生理反应，给出具体管理建议
- 寻求帮助：给出具体可操作的建议
- 鼓励/成功：肯定进步，强化自我效能感

每次回复末尾附带1-2个快捷回复建议，格式为：[建议1] [建议2]''';

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
