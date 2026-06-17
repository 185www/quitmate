import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: '通知'),
          SwitchListTile(
            title: const Text('每日提醒'),
            subtitle: const Text('每天提醒你记录'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('渴望高峰期提醒'),
            subtitle: const Text('在容易复发的时间提醒你'),
            value: true,
            onChanged: (value) {},
          ),
          const Divider(),
          const _SectionHeader(title: '显示'),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('跟随系统设置'),
            value: true,
            onChanged: (value) {},
          ),
          const Divider(),
          const _SectionHeader(title: '数据'),
          ListTile(
            title: const Text('导出数据'),
            subtitle: const Text('导出你的所有记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('清除数据'),
            subtitle: const Text('删除所有本地数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认清除'),
                  content: const Text('此操作不可恢复，确定要清除所有数据吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('确认'),
                    ),
                  ],
                ),
              );
            },
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
            ),
      ),
    );
  }
}