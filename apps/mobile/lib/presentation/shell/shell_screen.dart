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
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          final routes = ['/', '/action', '/maintenance', '/profile'];
          context.go(routes[index]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle), label: '行动'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: '维持'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QuitMate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.local_fire_department, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text('坚持戒断', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('0 天', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatCard(icon: Icons.psychology, label: '渴望管理', onTap: () => context.push('/action/urge-toolkit'))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.edit_note, label: '每日记录', onTap: () => context.push('/action/daily-log'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(icon: Icons.school, label: '技能训练', onTap: () => context.push('/action/skills-lab'))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.shield, label: '防复发', onTap: () => context.push('/maintenance/relapse-plan'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _StatCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
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