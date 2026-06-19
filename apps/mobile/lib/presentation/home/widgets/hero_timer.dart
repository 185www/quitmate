import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entity/user.dart';

/// Hero timer section showing the quit-day counter, motivational message,
/// and a rotating daily quote.
///
/// Displays a loading spinner while the user data loads.  If the user has
/// no quit date it shows a "准备好了吗？" prompt with a button to set one.
/// Otherwise it renders the large "第 X 天" centrepiece.
class HeroTimerSection extends StatelessWidget {
  const HeroTimerSection({super.key, required this.userFuture});

  /// A future that resolves to the current [User] (may be `null`).
  final Future<User?> userFuture;

  // ── Daily quote rotation ──────────────────────────────────────────
  /// Returns a quote string that rotates based on the day of year so the
  /// dashboard always feels fresh.
  static String getDailyQuote() {
    final quotes = [
      '"每一次抵抗，你都在重写自己的大脑。"',
      '"平均需要6-30次尝试——你只是还没到达终点。"',
      '"渴望像海浪，会来也会走。你不需要和它对抗。"',
      '"你的身体在20分钟内就开始修复。"',
      '"一年后，你的冠心病风险降低50%。"',
      '"运动可以在15分钟内减少50%的渴求感。"',
      '"你不是在放弃什么——你是在赢得自由。"',
      '"每一个不使用的时刻，都是胜利。"',
    ];
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return quotes[dayOfYear % quotes.length];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: userFuture,
      builder: (context, snap) {
        final user = snap.data;
        final colorScheme = Theme.of(context).colorScheme;

        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 180, child: Center(child: CircularProgressIndicator()));
        }

        if (user == null || !user.hasQuitDate) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '准备好了吗？',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '选一个好日子，正式开始你的戒断之旅',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.push('/preparation/quit-date'),
                  icon: const Icon(Icons.edit_calendar_rounded),
                  label: const Text('选择开始日期'),
                ),
              ],
            ),
          );
        }

        final days = user.daysSinceQuit;
        String message;
        if (days == 0) {
          message = '今天是最重要的一天，你已经迈出了第一步';
        } else if (days <= 3) {
          message = '最难熬的头几天，你正在坚持，真了不起';
        } else if (days <= 7) {
          message = '第一周了！身体的修复已经悄悄开始';
        } else if (days <= 14) {
          message = '两周了，味觉和嗅觉都在恢复';
        } else if (days <= 30) {
          message = '一个月了，肺部开始清理，体力在回升';
        } else if (days <= 90) {
          message = '$days 天了，你的坚持正在重塑自己';
        } else {
          message = '$days 天，你已经是自己的英雄了';
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big day counter
              Text(
                '第 $days 天',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 48,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                getDailyQuote(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.65),
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
