import 'dart:math';
import 'package:flutter/material.dart';
import '../../../domain/entity/challenge.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Pre-defined challenge library (read-only teaser)
    final challengeLibrary = _buildChallengeLibrary();
    final activeChallenge = _getActiveChallenge(challengeLibrary);
    final completedChallenges = <WeeklyChallenge>[]; // No completed yet

    return Scaffold(
      appBar: AppBar(
        title: const Text('每周挑战'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
              label: const Text('即将上线', style: TextStyle(fontSize: 12)),
              backgroundColor: colorScheme.primaryContainer,
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active challenge section
          if (activeChallenge != null) ...[
            _SectionHeader(
              title: '当前挑战',
              subtitle: '坚持就是胜利',
              icon: Icons.local_fire_department,
              iconColor: Colors.orange,
            ),
            const SizedBox(height: 12),
            _ActiveChallengeCard(challenge: activeChallenge),
            const SizedBox(height: 24),
          ] else ...[
            _SectionHeader(
              title: '当前挑战',
              subtitle: '选择一个挑战开始',
              icon: Icons.local_fire_department,
              iconColor: Colors.orange,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      child: Icon(
                        Icons.flag,
                        size: 36,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '还没有开始任何挑战',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '从下方挑战库中选择一个，开启你的挑战之旅',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Challenge library
          _SectionHeader(
            title: '挑战库',
            subtitle: '${challengeLibrary.length} 个挑战等你来',
            icon: Icons.library_books,
            iconColor: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          ...challengeLibrary.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChallengeCard(challenge: c),
            ),
          ),

          // Completed challenges
          if (completedChallenges.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(
              title: '已完成挑战',
              subtitle: '${completedChallenges.length} 个成就',
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
            ),
            const SizedBox(height: 12),
            ...completedChallenges.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompletedChallengeCard(challenge: c),
              ),
            ),
          ],

          // Coming soon teaser
          const SizedBox(height: 24),
          Card(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.rocket_launch, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '挑战追踪即将上线',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '完成挑战记录、XP奖励和社区排行榜将在后续更新中推出',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  WeeklyChallenge? _getActiveChallenge(List<WeeklyChallenge> challenges) {
    // For now, return null — no active challenge tracking yet
    return null;
  }

  List<WeeklyChallenge> _buildChallengeLibrary() {
    final now = DateTime.now();
    return [
      WeeklyChallenge(
        id: 'pure_7days',
        title: '7天纯净挑战',
        description: '完全戒断7天，不触碰任何成瘾物质。这是最基础也最重要的挑战。',
        targetDays: 7,
        startDate: now,
        xpReward: 150,
        emoji: '💎',
      ),
      WeeklyChallenge(
        id: 'craving_buster',
        title: '渴望克星',
        description: '连续7天记录并抵抗所有渴望。每次成功抵抗都是一次胜利。',
        targetDays: 7,
        startDate: now,
        xpReward: 120,
        emoji: '⚔️',
      ),
      WeeklyChallenge(
        id: 'cbt_learner',
        title: 'CBT学习者',
        description: '完成7个CBT练习，掌握认知行为疗法的核心技巧，改变思维模式。',
        targetDays: 7,
        startDate: now,
        xpReward: 130,
        emoji: '🧠',
      ),
      WeeklyChallenge(
        id: 'early_riser',
        title: '早起打卡',
        description: '连续7天在9点前打卡。规律作息是戒断成功的重要保障。',
        targetDays: 7,
        startDate: now,
        xpReward: 100,
        emoji: '🌅',
      ),
      WeeklyChallenge(
        id: 'fitness_champ',
        title: '运动达人',
        description: '连续7天进行至少15分钟运动。运动能显著降低渴求感。',
        targetDays: 7,
        startDate: now,
        xpReward: 140,
        emoji: '🏃',
      ),
      WeeklyChallenge(
        id: 'mindfulness_7',
        title: '正念7天',
        description: '每天使用呼吸练习，培养正念觉察力，学会与渴望和平共处。',
        targetDays: 7,
        startDate: now,
        xpReward: 110,
        emoji: '🧘',
      ),
    ];
  }
}

// ──────────────────────────────────────────────────────────
// Section Header
// ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Active Challenge Card with large circular progress
// ──────────────────────────────────────────────────────────
class _ActiveChallengeCard extends StatelessWidget {
  final WeeklyChallenge challenge;
  const _ActiveChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Large circular progress ring
                _CircularProgressRing(
                  progress: challenge.progress,
                  size: 100,
                  strokeWidth: 8,
                  completedDays: challenge.progressDays,
                  targetDays: challenge.targetDays,
                ),
                const SizedBox(width: 20),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            challenge.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              challenge.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        challenge.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Progress bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: challenge.progress,
                                minHeight: 6,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '+${challenge.xpReward} XP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Challenge Library Card
// ──────────────────────────────────────────────────────────
class _ChallengeCard extends StatelessWidget {
  final WeeklyChallenge challenge;
  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Generate a consistent hue from the challenge id
    final hue = challenge.id.hashCode % 360;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Show a "coming soon" toast-like message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('「${challenge.title}」挑战追踪即将上线！'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Small circular progress ring (0% since not started)
              _CircularProgressRing(
                progress: 0,
                size: 64,
                strokeWidth: 5,
                completedDays: 0,
                targetDays: challenge.targetDays,
                hue: hue.toDouble(),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          challenge.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            challenge.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '+${challenge.xpReward} XP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      challenge.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${challenge.targetDays} 天挑战',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.lock_outline,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '即将开放',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Completed Challenge Card
// ──────────────────────────────────────────────────────────
class _CompletedChallengeCard extends StatelessWidget {
  final WeeklyChallenge challenge;
  const _CompletedChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _CircularProgressRing(
              progress: 1.0,
              size: 56,
              strokeWidth: 4,
              completedDays: challenge.targetDays,
              targetDays: challenge.targetDays,
              completedColor: Colors.green,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${challenge.emoji} ${challenge.title}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    challenge.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (challenge.completedDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '完成于 ${_formatDate(challenge.completedDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${challenge.xpReward} XP ✓',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.month}/${d.day}';
}

// ──────────────────────────────────────────────────────────
// Circular Progress Ring (custom painter)
// ──────────────────────────────────────────────────────────
class _CircularProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final int completedDays;
  final int targetDays;
  final double? hue;
  final Color? completedColor;

  const _CircularProgressRing({
    required this.progress,
    required this.size,
    required this.strokeWidth,
    required this.completedDays,
    required this.targetDays,
    this.hue,
    this.completedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ringColor = completedColor ??
        (hue != null
            ? HSLColor.fromAHSL(1.0, hue!.abs().toDouble(), 0.6, 0.5).toColor()
            : colorScheme.primary);
    final isComplete = progress >= 1.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: 1.0,
              color: colorScheme.surfaceContainerHighest,
              strokeWidth: strokeWidth,
            ),
          ),
          // Progress ring
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              color: isComplete ? (completedColor ?? Colors.green) : ringColor,
              strokeWidth: strokeWidth,
            ),
          ),
          // Center text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isComplete ? '✓' : '$completedDays',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.bold,
                  color: isComplete
                      ? (completedColor ?? Colors.green)
                      : colorScheme.onSurface,
                ),
              ),
              Text(
                isComplete ? '完成' : '/ $targetDays天',
                style: TextStyle(
                  fontSize: size * 0.13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth * 2) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (progress >= 1.0) {
      canvas.drawCircle(center, radius, paint);
    } else if (progress > 0) {
      final sweepAngle = 2 * pi * progress;
      const startAngle = -pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}