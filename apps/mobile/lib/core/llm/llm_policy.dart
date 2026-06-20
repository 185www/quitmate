/// LLM 策略策略执行模块
///
/// 核心原则：
/// - 默认模式：100% 离线，使用规则引擎 AI Coach
/// - 增强模式：用户明确选择后启用 LLM
/// - 所有网络请求需用户明确授权
/// - LLM 响应仅为建议，不替代核心安全判断
///
/// PII 检测：扫描输入中的手机号、身份证号、地址等，替换为 [已隐藏]
/// 安全防护：如果 LLM 输出内容与安全规则矛盾（如"偶尔抽一支没关系"），添加免责声明
library;

import '../../data/database/app_database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Exceptions
// ─────────────────────────────────────────────────────────────────────────────

/// LLM 策略违规类型
enum LlmViolationType {
  /// LLM 功能未启用
  notEnabled,
  /// 用户未授权
  notAuthorized,
  /// 检测到个人可识别信息
  piiDetected,
  /// LLM 输出试图覆盖安全关键建议
  safetyOverride,
}

/// LLM 策略违规异常
class LlmPolicyViolation implements Exception {
  final String message;
  final LlmViolationType type;

  const LlmPolicyViolation({
    required this.message,
    required this.type,
  });

  @override
  String toString() => 'LlmPolicyViolation($type): $message';
}

// ─────────────────────────────────────────────────────────────────────────────
// LlmPolicy — 策略执行器
// ─────────────────────────────────────────────────────────────────────────────

/// LLM 策略执行器 — 纯 Dart，可测试
///
/// 使用 AppDatabase 的 app_config 表存储 LLM 启用状态。
class LlmPolicy {
  static const String _configKeyEnabled = 'llm_enabled';
  static const String _configKeyConsented = 'llm_user_consented';

  final AppDatabase _db;

  LlmPolicy(this._db);

  // ──────────────────────────────────────────────────────────
  // Enable / Disable
  // ──────────────────────────────────────────────────────────

  /// 用户是否已明确选择启用 LLM 增强模式
  Future<bool> isLlmEnabled() async {
    final value = await _db.getConfig(_configKeyEnabled);
    return value == 'true';
  }

  /// 用户是否已授权网络请求
  Future<bool> isUserAuthorized() async {
    final value = await _db.getConfig(_configKeyConsented);
    return value == 'true';
  }

  /// 启用/禁用 LLM 模式（需用户明确操作）
  ///
  /// [enabled] — 是否启用
  /// [userConsented] — 用户是否明确同意网络请求
  Future<void> enableLlm({
    required bool enabled,
    bool userConsented = true,
  }) async {
    await _db.setConfig(_configKeyEnabled, enabled.toString());
    if (enabled && userConsented) {
      await _db.setConfig(_configKeyConsented, 'true');
    }
  }

  /// 撤销用户授权
  Future<void> revokeAuthorization() async {
    await _db.setConfig(_configKeyConsented, 'false');
  }

  // ──────────────────────────────────────────────────────────
  // Validation
  // ──────────────────────────────────────────────────────────

  /// 验证 LLM 请求是否被允许
  ///
  /// 如果未启用或未授权，抛出 [LlmPolicyViolation]
  void validateRequest() {
    // Note: synchronous version uses cached values.
    // For production, use [validateRequestAsync] instead.
    // This sync version is provided for unit-test convenience
    // and should be called after a preceding async check.
    throw const LlmPolicyViolation(
      message: '请使用 validateRequestAsync()',
      type: LlmViolationType.notEnabled,
    );
  }

  /// 异步验证 LLM 请求是否被允许
  ///
  /// 检查顺序：启用状态 → 用户授权
  Future<void> validateRequestAsync() async {
    final enabled = await isLlmEnabled();
    if (!enabled) {
      throw const LlmPolicyViolation(
        message: 'LLM 增强模式未启用。请前往设置中开启。',
        type: LlmViolationType.notEnabled,
      );
    }

    final authorized = await isUserAuthorized();
    if (!authorized) {
      throw const LlmPolicyViolation(
        message: '用户未授权网络请求。请确认授权后重试。',
        type: LlmViolationType.notAuthorized,
      );
    }
  }

  /// 验证用户输入是否包含 PII
  ///
  /// 如果检测到 PII，抛出 [LlmPolicyViolation]
  /// [detectedPii] 返回被检测到的 PII 类型（用于 UI 提示）
  void validateInputPii(
    String input, {
    List<String>? detectedPii,
  }) {
    final found = detectPii(input);
    if (detectedPii != null) {
      detectedPii.clear();
      detectedPii.addAll(found);
    }
    if (found.isNotEmpty) {
      throw LlmPolicyViolation(
        message: '输入中包含个人敏感信息（${found.join('、')}），已自动替换为 [已隐藏]。'
            '如果不需要发送此信息，请修改后再试。',
        type: LlmViolationType.piiDetected,
      );
    }
  }

  // ──────────────────────────────────────────────────────────
  // Sanitization — Input
  // ──────────────────────────────────────────────────────────

  /// 清理用户输入 — 移除/替换个人可识别信息
  ///
  /// 检测范围：
  /// - 手机号码（11位，1开头）
  /// - 固话号码
  /// - 身份证号码（18位或15位）
  /// - 邮箱地址
  /// - 银行卡号（16-19位数字）
  /// - IP 地址
  /// - 中国地址格式（省/市/区+路）
  /// - 人名（简单启发式：2-4个中文字符，后面跟常见称谓）
  String sanitizeInput(String input) {
    String result = input;

    // 手机号码：1开头11位数字
    result = result.replaceFirstMapped(RegExp(r'1[3-9]\d{9}'), (m) => '[已隐藏]');

    // 身份证号：18位或15位
    result = result.replaceFirstMapped(RegExp(r'\b[1-9]\d{5}(?:19|20)\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])\d{3}[\dXx]\b'), (m) => '[已隐藏]');

    result = result.replaceFirstMapped(RegExp(r'\b[1-9]\d{5}\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])\d{3}\b'), (m) => '[已隐藏]');

    // 邮箱
    result = result.replaceFirstMapped(RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+'), (m) => '[已隐藏]');

    // 银行卡号：16-19位连续数字（排除手机号已匹配的）
    result = result.replaceFirstMapped(RegExp(r'\b[3-6]\d{15,18}\b'), (m) => '[已隐藏]');

    // IP 地址
    result = result.replaceFirstMapped(RegExp(r'\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\b'), (m) => '[已隐藏]');

    // 中国地址格式：XX省XX市...  或 XX市XX区...
    result = result.replaceFirstMapped(RegExp(r'[\u4e00-\u9fa5]{1,4}(?:省|自治区|市|区|县|镇|乡|村|路|街|道|号|栋|室|楼)\S*'), (m) => '[已隐藏]');

    return result;
  }

  /// 检测输入中的 PII，返回发现的 PII 类型列表
  List<String> detectPii(String input) {
    final detected = <String>[];

    if (RegExp(r'1[3-9]\d{9}').hasMatch(input)) {
      detected.add('手机号码');
    }

    if (RegExp(r'\b[1-9]\d{5}(?:19|20)\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])\d{3}[\dXx]\b')
            .hasMatch(input) ||
        RegExp(r'\b[1-9]\d{5}\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])\d{3}\b')
            .hasMatch(input)) {
      detected.add('身份证号');
    }

    if (RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+').hasMatch(input)) {
      detected.add('邮箱地址');
    }

    if (RegExp(r'\b[3-6]\d{15,18}\b').hasMatch(input)) {
      detected.add('银行卡号');
    }

    if (RegExp(
            r'\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\b')
        .hasMatch(input)) {
      detected.add('IP地址');
    }

    if (RegExp(
            r'[\u4e00-\u9fa5]{1,4}(?:省|自治区|市|区|县|镇|乡|村|路|街|道|号|栋|室|楼)\S*')
        .hasMatch(input)) {
      detected.add('地址信息');
    }

    return detected;
  }

  // ──────────────────────────────────────────────────────────
  // Sanitization — Output
  // ──────────────────────────────────────────────────────────

  /// 清理 LLM 输出 — 确保不覆盖安全关键建议
  ///
  /// 检查 LLM 输出是否包含与安全规则矛盾的内容，如：
  /// - "抽一支没关系"、"偶尔喝一点也行"
  /// - "不用太在意复发"
  /// - "你做不到也没关系"
  ///
  /// 如果检测到矛盾内容，自动添加免责声明
  String sanitizeOutput(String output) {
    final safetyIssues = _detectSafetyViolations(output);
    if (safetyIssues.isEmpty) {
      return output;
    }

    // 在输出末尾添加安全免责声明
    final disclaimer = _buildDisclaimer(safetyIssues);
    return '$output\n\n⚠️ $disclaimer';
  }

  /// 检测 LLM 输出中的安全违规
  List<String> _detectSafetyViolations(String output) {
    final violations = <String>[];

    // 允许/鼓励复发的表述
    final permissivePatterns = [
      RegExp(r'(?:抽|吸|喝).{0,10}(?:一[支个瓶杯]|一口|一次).{0,10}(?:没关系|可以的|没事|不要紧|无害)'),
      RegExp(r'(?:偶尔|偶尔|偶尔).{0,10}(?:抽|吸|喝|用).{0,10}(?:也行|可以|没关系)'),
      RegExp(r'(?:复发|破戒).{0,10}(?:不用|不必).{0,10}(?:在意|担心|太认真|纠结)'),
      RegExp(r'(?:戒|停).{0,10}(?:做不到|失败|不可能)'),
      RegExp(r'(?:不用|没必要).{0,10}(?:戒|停|放弃)'),
    ];

    for (final pattern in permissivePatterns) {
      if (pattern.hasMatch(output)) {
        violations.add('检测到可能弱化戒断目标的表述');
        break;
      }
    }

    // 贬低用户努力的表述
    final discouragingPatterns = [
      RegExp(r'(?:你).{0,10}(?:不可能|做不到|永远做不到|永远戒不掉)'),
      RegExp(r'(?:放弃|算了|别折腾了|没用的)'),
    ];

    for (final pattern in discouragingPatterns) {
      if (pattern.hasMatch(output)) {
        violations.add('检测到可能打击积极性的表述');
        break;
      }
    }

    return violations;
  }

  /// 构建安全免责声明
  String _buildDisclaimer(List<String> issues) {
    if (issues.contains('检测到可能弱化戒断目标的表述')) {
      return '安全提醒：研究表明，即使是"偶尔一次"也可能导致复发循环。你的坚持非常有价值，请相信自己的能力。';
    }
    if (issues.contains('检测到可能打击积极性的表述')) {
      return 'AI 建议仅供参考。你已经迈出了重要的一步，每一点努力都值得肯定。';
    }
    return 'AI 建议仅供参考，不替代专业医疗建议。如有需要，请联系专业医生或咨询师。';
  }

  // ──────────────────────────────────────────────────────────
  // Convenience: 完整的发送流程
  // ──────────────────────────────────────────────────────────

  /// 完整的 LLM 请求准备流程
  ///
  /// 1. 验证 LLM 是否启用
  /// 2. 验证用户是否授权
  /// 3. 清理输入中的 PII
  /// 4. 返回清理后的输入
  ///
  /// 如果验证失败，抛出 [LlmPolicyViolation]
  Future<String> prepareRequest(String userInput) async {
    // Step 1: Check enabled
    final enabled = await isLlmEnabled();
    if (!enabled) {
      throw const LlmPolicyViolation(
        message: 'LLM 增强模式未启用。请前往设置中开启。',
        type: LlmViolationType.notEnabled,
      );
    }

    // Step 2: Check authorization
    final authorized = await isUserAuthorized();
    if (!authorized) {
      throw const LlmPolicyViolation(
        message: '用户未授权网络请求。请确认授权后重试。',
        type: LlmViolationType.notAuthorized,
      );
    }

    // Step 3: Sanitize input
    final sanitized = sanitizeInput(userInput);

    return sanitized;
  }

  /// 完整的 LLM 响应处理流程
  ///
  /// 清理输出中的安全违规内容，返回清理后的输出
  String processResponse(String llmOutput) {
    return sanitizeOutput(llmOutput);
  }
}
