import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/action/dashboard/dashboard_screen.dart';
import '../../presentation/action/urge_toolkit/urge_toolkit_screen.dart';
import '../../presentation/action/daily_log/daily_log_screen.dart';
import '../../presentation/action/skills_lab/skills_lab_screen.dart';
import '../../presentation/maintenance/relapse_plan/relapse_plan_screen.dart';
import '../../presentation/maintenance/lifestyle/lifestyle_screen.dart';
import '../../presentation/profile/profile_screen.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class ActionTabScreen extends StatelessWidget {
  const ActionTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('行动改变')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionTile(icon: Icons.psychology, title: '渴望管理工具箱', subtitle: '冲浪法、替代行为、SOS求助', onTap: () => context.push('/action/urge-toolkit')),
          _ActionTile(icon: Icons.edit_note, title: '每日记录', subtitle: '记录情绪、诱因和应对方式', onTap: () => context.push('/action/daily-log')),
          _ActionTile(icon: Icons.school, title: 'CBT技能训练', subtitle: '认知行为疗法技巧学习', onTap: () => context.push('/action/skills-lab')),
        ],
      ),
    );
  }
}

class MaintenanceTabScreen extends StatelessWidget {
  const MaintenanceTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('维持防复发')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionTile(icon: Icons.shield, title: '复发预防计划', subtitle: '高危情境预案和应对策略', onTap: () => context.push('/maintenance/relapse-plan')),
          _ActionTile(icon: Icons.fitness_center, title: '生活方式重塑', subtitle: '运动、冥想、健康习惯', onTap: () => context.push('/maintenance/lifestyle')),
        ],
      ),
    );
  }
}

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionTile(icon: Icons.download, title: '导出数据', subtitle: '导出你的记录和报告', onTap: () => context.push('/profile/export')),
          _ActionTile(icon: Icons.settings, title: '设置', subtitle: '通知、提醒、偏好设置', onTap: () => context.push('/profile/settings')),
          _ActionTile(icon: Icons.info_outline, title: '关于', subtitle: '版本信息、隐私政策、免责声明', onTap: () => context.push('/profile/about')),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}