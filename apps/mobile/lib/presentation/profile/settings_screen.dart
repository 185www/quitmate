import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/coach/ai_agent_service.dart';
import '../../core/notifications/notification_content_generator.dart';

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

  // LLM settings (summary only; full config moved to LlmSettingsScreen)
  String _apiKey = '';
  String _apiBaseUrl = 'https://api.openai.com/v1';
  String _aiModel = 'gpt-4o-mini';
  bool _useLlm = false;

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
          _apiBaseUrl =
              prefs['ai_api_base'] as String? ?? 'https://api.openai.com/v1';
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

      // Re-initialize AiAgentService with new LLM settings
      await AiAgentService.instance.updateLlmService(
        apiKey: _apiKey,
        baseUrl: _apiBaseUrl,
        model: _aiModel,
        enabled: _useLlm,
      );

      final notif = ref.read(notificationServiceProvider);
      if (_dailyReminder) {
        // Generate personalized notification content via LLM or fallback
        final user = await ref.read(userUseCaseProvider).getCurrentUser();
        final llm = AiAgentService.instance.llmService;
        final daysSinceQuit = user?.daysSinceQuit ?? 0;
        final userContext = user != null
            ? '戒断天数：$daysSinceQuit天，目标：${user.targetType.name}'
            : null;
        final body = await NotificationContentGenerator.generateMorningReminder(
          daysSinceQuit: daysSinceQuit,
          llmService: llm,
          userContext: userContext,
        );
        await notif.scheduleDailyReminder(
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
          title: 'QuitMate提醒',
          body: body,
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
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
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
          _SectionHeader(title: '电池与后台'),
          ListTile(
            leading: const Icon(Icons.battery_charging_full),
            title: const Text('电池优化白名单'),
            subtitle: const Text('允许后台运行，确保提醒正常送达'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _openBatterySettings(),
          ),
          ExpansionTile(
            leading: const Icon(Icons.devices),
            title: const Text('各品牌设置指引'),
            children: [
              _OemGuideTile(
                brand: '小米/Redmi',
                steps: ['设置 → 应用设置 → 应用管理 → QuitMate',
                  '开启「自启动」',
                  '电池优化中选择「不优化」'],
              ),
              _OemGuideTile(
                brand: 'OPPO/一加',
                steps: ['设置 → 电池 → 更多电池设置',
                  '允许 QuitMate「后台高耗电」',
                  '或在应用详情中开启「允许后台活动」'],
              ),
              _OemGuideTile(
                brand: 'vivo/iQOO',
                steps: ['i管家 → 应用管理 → QuitMate',
                  '开启「自启动」和「后台高耗电」'],
              ),
              _OemGuideTile(
                brand: '华为/荣耀',
                steps: ['设置 → 电池 → 应用启动管理 → QuitMate',
                  '关闭「自动管理」，手动开启全部三项',
                  '或在「受保护应用」中添加 QuitMate'],
              ),
            ],
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
          ListTile(
            leading: const Icon(Icons.psychology),
            title: const Text('AI 助手设置'),
            subtitle: Text(
              _useLlm ? '已启用 · $_aiModel' : '使用内置规则引擎',
              style: TextStyle(fontSize: 12, color: _useLlm ? null : Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.push('/settings/llm'),
          ),
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

  void _openBatterySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '请前往系统设置 → 应用管理 → QuitMate，\n'
          '关闭电池优化，并允许自启动',
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '知道了',
          onPressed: () {},
        ),
      ),
    );
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

class _OemGuideTile extends StatelessWidget {
  final String brand;
  final List<String> steps;

  const _OemGuideTile({required this.brand, required this.steps});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(brand,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              )),
          const SizedBox(height: 4),
          ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        )),
                    Expanded(
                      child: Text(step,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          )),
                    ),
                  ],
                ),
              )),
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
