import 'package:flutter/material.dart';

/// A dialog that explains the value of notifications before requesting permission.
/// Shown after the user sets their quit date during onboarding.
class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback onGrant;
  final VoidCallback onSkip;

  const NotificationPermissionDialog({
    super.key,
    required this.onGrant,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Text('🔔'),
          const SizedBox(width: 8),
          Text('每天给你一句提醒', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '在你最需要的时候，我会给你发一条提醒，帮你撑过那些关键时刻。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            '我们承诺：',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _PromiseRow(icon: '✅', text: '每天最多 3 条通知'),
          const SizedBox(height: 4),
          _PromiseRow(icon: '✅', text: '绝对不会在深夜发送'),
          const SizedBox(height: 4),
          _PromiseRow(icon: '✅', text: '你可以随时关闭'),
        ],
      ),
      actions: [
        TextButton(onPressed: onSkip, child: const Text('以后再说')),
        FilledButton(onPressed: onGrant, child: const Text('好的，开启提醒')),
      ],
    );
  }
}

class _PromiseRow extends StatelessWidget {
  final String icon;
  final String text;
  const _PromiseRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}
