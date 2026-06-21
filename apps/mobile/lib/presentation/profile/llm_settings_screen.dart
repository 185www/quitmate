import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/coach/llm_service.dart';
import '../../core/llm/llm_usage_tracker.dart';

/// Dedicated screen for LLM / AI assistant configuration.
///
/// Allows users to:
/// - Enable / disable LLM-powered AI features
/// - Configure API key, base URL, and model name
/// - Pick from quick presets (OpenAI, DeepSeek, Ollama)
/// - Test the API connection
/// - View estimated usage / cost
/// - Read privacy safeguards
class LlmSettingsScreen extends ConsumerStatefulWidget {
  const LlmSettingsScreen({super.key});

  @override
  ConsumerState<LlmSettingsScreen> createState() => _LlmSettingsScreenState();
}

class _LlmSettingsScreenState extends ConsumerState<LlmSettingsScreen> {
  // ── Form controllers ──────────────────────────────────────────────────
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;

  // ── State ────────────────────────────────────────────────────────────
  bool _llmEnabled = false;
  bool _obscureApiKey = true;
  bool _loading = true;
  bool _saving = false;
  bool _testingLlm = false;
  bool _llmTested = false;
  bool _llmConnected = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _baseUrlController = TextEditingController(text: 'https://api.openai.com/v1');
    _modelController = TextEditingController(text: 'gpt-4o-mini');
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  // ── Load / Save ──────────────────────────────────────────────────────
  Future<void> _loadSettings() async {
    try {
      final prefs = await ref.read(userUseCaseProvider).getPreferences();
      if (mounted) {
        setState(() {
          _llmEnabled = prefs['use_llm'] as bool? ?? false;
          _apiKeyController.text = prefs['ai_api_key'] as String? ?? '';
          _baseUrlController.text =
              prefs['ai_api_base'] as String? ?? 'https://api.openai.com/v1';
          _modelController.text =
              prefs['ai_model'] as String? ?? 'gpt-4o-mini';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      final prefs = await ref.read(userUseCaseProvider).getPreferences();
      prefs['use_llm'] = _llmEnabled;
      prefs['ai_api_key'] = _apiKeyController.text.trim();
      prefs['ai_api_base'] = _baseUrlController.text.trim();
      prefs['ai_model'] = _modelController.text.trim();
      await ref.read(userUseCaseProvider).savePreferences(prefs);

      // Sync with LlmPolicy so the policy layer knows the current state
      final policy = ref.read(llmPolicyProvider);
      await policy.enableLlm(enabled: _llmEnabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI 设置已保存'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Test connection ──────────────────────────────────────────────────
  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入 API Key')),
      );
      return;
    }
    setState(() => _testingLlm = true);
    try {
      final service = LlmService(
        apiKey: _apiKeyController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
        model: _modelController.text.trim(),
      );
      final ok = await service.testConnection();
      if (mounted) {
        setState(() {
          _llmTested = true;
          _llmConnected = ok;
          _testingLlm = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _llmTested = true;
          _llmConnected = false;
          _testingLlm = false;
        });
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI 助手设置')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 助手设置'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveSettings,
                ),
        ],
      ),
      body: ListView(
        children: [
          // ── Enable / Disable ─────────────────────────────────────────
          _SectionHeader(title: 'AI 助手'),
          SwitchListTile(
            title: const Text('启用 AI 助手'),
            subtitle: const Text('开启后将使用大语言模型增强分析和建议'),
            value: _llmEnabled,
            onChanged: (v) => setState(() => _llmEnabled = v),
            secondary: Icon(
              _llmEnabled ? Icons.psychology : Icons.psychology_outlined,
              color: _llmEnabled ? colorScheme.primary : null,
            ),
          ),

          const Divider(),

          // ── API Configuration ────────────────────────────────────────
          _SectionHeader(title: 'API 配置'),

          if (!_llmEnabled)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '请先开启 AI 助手开关',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else ...[
            _buildTextField(
              controller: _apiKeyController,
              label: 'API Key',
              hint: 'sk-...',
              icon: Icons.key,
              obscure: _obscureApiKey,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscureApiKey = !_obscureApiKey),
              ),
            ),
            _buildTextField(
              controller: _baseUrlController,
              label: 'Base URL',
              hint: 'https://api.openai.com/v1',
              icon: Icons.language,
            ),
            _buildTextField(
              controller: _modelController,
              label: '模型名称',
              hint: 'gpt-4o-mini',
              icon: Icons.smart_toy,
            ),

            // Test connection
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _testingLlm ? null : _testConnection,
                icon: _testingLlm
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: const Text('测试连接'),
              ),
            ),

            if (_llmTested)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      _llmConnected ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: _llmConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _llmConnected ? '连接成功' : '连接失败',
                      style: TextStyle(
                        color: _llmConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '支持 OpenAI、DeepSeek、Ollama 等兼容 API',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],

          const Divider(),

          // ── Quick Presets ───────────────────────────────────────────
          _SectionHeader(title: '快速预设'),
          _buildPresetCard(
            title: 'OpenAI GPT-4o Mini',
            subtitle: '推荐 · 成本最低',
            url: 'https://api.openai.com/v1',
            model: 'gpt-4o-mini',
            cost: '约 ¥0.01/天',
            colorScheme: colorScheme,
          ),
          _buildPresetCard(
            title: 'DeepSeek V3',
            subtitle: '性价比最高',
            url: 'https://api.deepseek.com/v1',
            model: 'deepseek-chat',
            cost: '约 ¥0.005/天',
            colorScheme: colorScheme,
          ),
          _buildPresetCard(
            title: 'Ollama 本地',
            subtitle: '完全离线 · 零成本',
            url: 'http://localhost:11434/v1',
            model: 'qwen2.5:7b',
            cost: '免费',
            colorScheme: colorScheme,
          ),

          const Divider(),

          // ── Usage Statistics ────────────────────────────────────────
          _SectionHeader(title: '用量估算'),
          _buildUsageCard(colorScheme),

          const Divider(),

          // ── Privacy Notice ──────────────────────────────────────────
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield,
                          size: 18, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '隐私保护',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 所有对话数据在发送前会自动去除个人信息（手机号、身份证、银行卡等）',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• AI 回复会经过安全审查，防止不当建议',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• 关闭 AI 助手后，所有功能仍可正常使用（本地算法替代）',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: _llmEnabled,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPresetCard({
    required String title,
    required String subtitle,
    required String url,
    required String model,
    required String cost,
    required ColorScheme colorScheme,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.flash_on),
        title: Text(title),
        subtitle: Text('$subtitle · $cost'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          setState(() {
            _baseUrlController.text = url;
            _modelController.text = model;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已选择 $title'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsageCard(ColorScheme colorScheme) {
    final tracker = LlmUsageTracker.instance;
    final inputTokens = tracker.totalInputTokens;
    final outputTokens = tracker.totalOutputTokens;
    final calls = tracker.totalCalls;
    final estimatedCost = tracker.estimateMonthlyCost();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUsageRow(
              '输入 Token',
              _formatTokenCount(inputTokens),
              Icons.input,
              colorScheme,
            ),
            const SizedBox(height: 8),
            _buildUsageRow(
              '输出 Token',
              _formatTokenCount(outputTokens),
              Icons.output,
              colorScheme,
            ),
            const SizedBox(height: 8),
            _buildUsageRow(
              'API 调用次数',
              '$calls 次',
              Icons.sync,
              colorScheme,
            ),
            const SizedBox(height: 8),
            _buildUsageRow(
              '估算月费用',
              '¥${estimatedCost.toStringAsFixed(4)}',
              Icons.payments,
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Format large token counts to a compact string (e.g. "1.2K", "3.5M").
  String _formatTokenCount(int tokens) {
    if (tokens >= 1000000) {
      return '${(tokens / 1000000).toStringAsFixed(1)}M';
    } else if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(1)}K';
    }
    return '$tokens';
  }
}

// ── Reusable section header (same as the private one in settings_screen) ──

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
