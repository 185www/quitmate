import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyReminder = true;
  bool _urgeReminder = true;
  bool _darkMode = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _loading = true;
  bool _saving = false;

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
          _darkMode = prefs['dark_mode'] as bool? ?? false;
          final hour = prefs['reminder_hour'] as int? ?? 9;
          final minute = prefs['reminder_minute'] as int? ?? 0;
          _reminderTime = TimeOfDay(hour: hour, minute: minute);
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
      prefs['dark_mode'] = _darkMode;
      prefs['reminder_hour'] = _reminderTime.hour;
      prefs['reminder_minute'] = _reminderTime.minute;
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
    final theme = Theme.of(context);

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
            subtitle: const Text('跟随系统设置'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
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
                await db.delete('notification_schedule');
                await ref.read(notificationServiceProvider).cancelAll();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('数据已清除')),
                  );
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
