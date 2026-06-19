import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/coach/llm_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyReminder = true;
  bool _urgeReminder = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _loading = true;
  bool _saving = false;

  // LLM settings
  String _apiKey = '';
  String _apiBaseUrl = 'https://api.openai.com/v1';
  String _aiModel = 'gpt-4o-mini';
  bool _useLlm = false;
  bool _testingLlm = false;
  bool _llmTested = false;
  bool _llmConnected = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await ref.read(userUseCaseProvider).getPreferences();
      if (mounted) {
        setState(() {
          _dailyReminder = prefs['daily_reminder'] as bool? ?? true;
          _urgeReminder = prefs['urge_reminder'] as bool? ?? true;
          final hour = prefs['reminder_hour'] as int? ?? 9;
          final minute = prefs['reminder_minute'] as int? ?? 0;
          _reminderTime = TimeOfDay(hour: hour, minute: minute);
          _useLlm = prefs['use_llm'] as bool? ?? false;
          _apiKey = prefs['ai_api_key'] as String? ?? '';
          _apiBaseUrl = prefs['ai_api_base'] as String? ?? 'https://api.openai.com/v1';
          _aiModel = prefs['ai_model'] as String? ?? 'gpt-4o-mini';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _saving = true);
    try {
      final prefs = await ref.read(userUseCaseProvider).getPreferences();
      prefs['daily_reminder'] = _dailyReminder;
      prefs['urge_reminder'] = _urgeReminder;
      prefs['reminder_hour'] = _reminderTime.hour;
      prefs['reminder_minute'] = _reminderTime.minute;
      prefs['use_llm'] = _useLlm;
      prefs['ai_api_key'] = _apiKey;
      prefs['ai_api_base'] = _apiBaseUrl;
      prefs['ai_model'] = _aiModel;
      await ref.read(userUseCaseProvider).savePreferences(prefs);

      final notif = ref.read(notificationServiceProvider);
      if (_dailyReminder) {
        await notif.scheduleDailyReminder(
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
          title: 'QuitMate提醒',
          body: '记得记录今天的进展！',
        );
      } else {
        await notif.cancelAll();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已保存')),
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

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('设置')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _savePreferences,
                ),
        ],
      ),
      body: ListView(
        children: [
          _SectionHeader(title: '通知设置'),
          SwitchListTile(
            title: const Text('每日提醒'),
            subtitle: const Text('每天提醒你记录进展'),
            value: _dailyReminder,
            onChanged: (v) => setState(() => _dailyReminder = v),
          ),
          SwitchListTile(
            title: const Text('渴望高峰提醒'),
            subtitle: const Text('在容易复发的时间提醒你'),
            value: _urgeReminder,
            onChanged: (v) => setState(() => _urgeReminder = v),
          ),
          ListTile(
            title: const Text('提醒时间'),
            subtitle: Text(_reminderTime.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _reminderTime,
              );
              if (picked != null) {
                setState(() => _reminderTime = picked);
              }
            },
          ),
          const Divider(),
          _SectionHeader(title: '显示设置'),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('手动切换深色/浅色主题'),
            value: isDark,
            onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v),
          ),
          const Divider(),
          _SectionHeader(title: 'AI教练设置'),
          SwitchListTile(
            title: const Text('启用LLM增强'),
            subtitle: Text(_useLlm ? '使用API获取更智能的回复' : '使用内置规则引擎'),
            value: _useLlm,
            onChanged: (v) => setState(() => _useLlm = v),
          ),
          if (_useLlm) ...[
            ListTile(
              title: const Text('API地址'),
              subtitle: Text(_apiBaseUrl, style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.link, size: 18),
              onTap: () => _showEditDialog('API地址', 'https://api.openai.com/v1', _apiBaseUrl, (v) => setState(() => _apiBaseUrl = v)),
            ),
            ListTile(
              title: const Text('API Key'),
              subtitle: Text(
                _apiKey.isEmpty ? '未设置' : '${_apiKey.substring(0, 8.clamp(0, _apiKey.length))}...',
                style: TextStyle(fontSize: 12, color: _apiKey.isEmpty ? Colors.grey : null),
              ),
              trailing: const Icon(Icons.key, size: 18),
              onTap: () => _showEditDialog('API Key', 'sk-...', _apiKey, (v) => setState(() => _apiKey = v), isSecret: true),
            ),
            ListTile(
              title: const Text('模型'),
              subtitle: Text(_aiModel, style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.memory, size: 18),
              onTap: () => _showModelPicker(),
            ),
            ListTile(
              title: const Text('测试连接'),
              subtitle: Text(
                _llmTested ? (_llmConnected ? '✅ 成功' : '❌ 失败') : '点击测试',
              ),
              trailing: _testingLlm
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.network_check, size: 18),
              onTap: _testLlmConnection,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '支持OpenAI、DeepSeek、Ollama等兼容API',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
          const Divider(),
          _SectionHeader(title: '数据管理'),
          ListTile(
            title: const Text('导出数据'),
            subtitle: const Text('导出你的所有记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/export'),
          ),
          ListTile(
            title: const Text('清除数据'),
            subtitle: const Text('删除所有本地数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearDataDialog(context),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String title, String hint, String current, void Function(String) onSave, {bool isSecret = false}) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: isSecret,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showModelPicker() {
    final models = ['gpt-4o-mini', 'gpt-4o', 'gpt-3.5-turbo', 'deepseek-chat', 'claude-3-haiku'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择模型'),
        children: models.map((model) => RadioListTile<String>(
          title: Text(model, style: const TextStyle(fontSize: 14)),
          value: model,
          groupValue: _aiModel,
          onChanged: (value) {
            if (value != null) {
              setState(() => _aiModel = value);
              Navigator.pop(ctx);
            }
          },
        )).toList(),
      ),
    );
  }

  Future<void> _testLlmConnection() async {
    setState(() => _testingLlm = true);
    try {
      final service = LlmService(
        apiKey: _apiKey,
        baseUrl: _apiBaseUrl,
        model: _aiModel,
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

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('此操作不可恢复，确定要清除所有数据吗？\n\n所有记录、设置和个人数据将被永久删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final db = await ref.read(appDatabaseProvider).database;
                await db.delete('daily_log');
                await db.delete('craving_log');
                await db.delete('relapse_plan');
                await db.delete('user_profile');
                // Reset badges (keep definitions, clear earned status)
                await db.update('badge', {'earned_at': null});
                await ref.read(notificationServiceProvider).cancelAll();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('数据已清除')),
                  );
                  // Force navigation to welcome by clearing all routes
                  context.go('/welcome');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('清除失败: $e')),
                  );
                }
              }
            },
            child: const Text('确认清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

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
