import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../domain/entity/user.dart';

/// First-time entry screen with multiple paths:
/// A. "我现在就很难受" → instant help, no questions
/// B. "我想看看自己的情况" → reality check / self-discovery
/// C. "我就随便看看" → casual discovery (for forced-install users)
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitHook();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const Spacer(flex: 1),
                // App identity
                Icon(
                  Icons.spa_rounded,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'QuitMate',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '60 秒，看看这个习惯每年从你身上拿走了什么',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(flex: 2),
                // Path A: Immediate help
                _PathCard(
                  icon: Icons.emergency,
                  iconColor: Colors.red,
                  iconBgColor: Colors.red.shade50,
                  title: '我现在就很难受',
                  subtitle: '渴求来了，帮我扛过这一刻',
                  onTap: () => _goInstantHelp(),
                ),
                const SizedBox(height: 16),
                // Path B: Self-discovery
                _PathCard(
                  icon: Icons.visibility,
                  iconColor: Colors.indigo,
                  iconBgColor: Colors.indigo.shade50,
                  title: '我想看看自己的情况',
                  subtitle: '了解一下习惯对自己意味着什么',
                  onTap: () => context.push('/onboarding/reality-check'),
                ),
                const SizedBox(height: 16),
                // Path C: Casual discovery
                _PathCard(
                  icon: Icons.search,
                  iconColor: Colors.teal,
                  iconBgColor: Colors.teal.shade50,
                  title: '我就随便看看',
                  subtitle: '先了解一下，不做任何承诺',
                  onTap: () => context.push('/onboarding/discovery'),
                ),
                const SizedBox(height: 24),
                // Skip to assessment
                TextButton(
                  onPressed: () => context.push('/onboarding/assessment'),
                  child: Text(
                    '直接开始评估 →',
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show a personalized bottom-sheet hook when the user tries to exit.
  void _showExitHook() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('等等，花 30 秒看看这个 →', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '你知道吗？每天一包烟，一年下来大约花费 ¥5,475。十年就是 ¥54,750，够一次全家出国旅行。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context); // Actually exit
                      },
                      child: const Text('不了，谢谢'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/onboarding/reality-check');
                      },
                      child: const Text('我想看看'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Path A: Create a minimal user and go straight to urge toolkit
  Future<void> _goInstantHelp() async {
    try {
      final user = await ref.read(userUseCaseProvider).getCurrentUser();
      if (user == null) {
        await ref.read(userUseCaseProvider).createUser(
              targetType: TargetType.smoking,
              quitDate: DateTime.now(),
            );
      }
      if (mounted) context.push('/action/urge-toolkit');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('出错了: $e')),
        );
      }
    }
  }
}

class _PathCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PathCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
