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
