import 'package:flutter/material.dart';
import '../../../core/relapse/relapse_tolerance_service.dart';
import '../../../core/theme/app_theme.dart';

/// 复发宽容卡片 — 非评判性的复发历史展示
///
/// 设计原则：
/// - 标题 "跌倒了没关系，重要的是站起来"
/// - 无复发时展示鼓励信息
/// - 有复发时展示时间线和恢复建议
/// - "记录一次跌倒" 按钮打开温和对话框
/// - 中文文本，支持深色模式
class RelapseToleranceCard extends StatefulWidget {
  final RelapseSummary summary;
  final List<RelapseEvent> relapseEvents;
  final RecoveryTrajectory? trajectory;
  final void Function(RelapseEvent event) onRelapseRecorded;
  final int streakDays;

  const RelapseToleranceCard({
    super.key,
    required this.summary,
    required this.relapseEvents,
    this.trajectory,
    required this.onRelapseRecorded,
    this.streakDays = 0,
  });

  @override
  State<RelapseToleranceCard> createState() => _RelapseToleranceCardState();
}

class _RelapseToleranceCardState extends State<RelapseToleranceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final hasRelapses = widget.summary.totalRelapses > 0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.cardRadius),
          side: BorderSide(
            color: colors.dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              _buildHeader(theme, colors, spacing),
              SizedBox(height: spacing.sm),

              // ── Encouragement message ──
              Container(
                padding: EdgeInsets.all(spacing.sm),
                decoration: BoxDecoration(
                  color: hasRelapses
                      ? colors.companionColor.withOpacity(0.08)
                      : colors.successColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(spacing.inputRadius),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasRelapses ? Icons.favorite : Icons.emoji_events,
                      color: hasRelapses
                          ? colors.companionColor
                          : colors.successColor,
                      size: 20,
                    ),
                    SizedBox(width: spacing.xs),
                    Expanded(
                      child: Text(
                        hasRelapses
                            ? widget.summary.encouragement
                            : '你已经 ${widget.streakDays} 天没有复发，太棒了！',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: hasRelapses
                              ? colors.companionColor
                              : colors.successColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (hasRelapses) ...[
                SizedBox(height: spacing.md),

                // ── Stats row ──
                _buildStatsRow(theme, colors, spacing),

                SizedBox(height: spacing.md),

                // ── Bounce-back rate visualization ──
                _buildBounceBackRate(theme, colors, spacing),

                SizedBox(height: spacing.md),

                // ── Recovery trajectory (if available) ──
                if (widget.trajectory != null)
                  _buildRecoveryTrajectory(
                      theme, colors, spacing, widget.trajectory!),

                SizedBox(height: spacing.md),

                // ── Relapse timeline ──
                if (widget.relapseEvents.isNotEmpty)
                  _buildTimeline(theme, colors, spacing),
              ],

              SizedBox(height: spacing.md),

              // ── Record button ──
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showRecordDialog,
                  icon: Icon(Icons.add_circle_outline,
                      size: 18, color: theme.colorScheme.primary),
                  label: Text(
                    '记录一次跌倒',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: spacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(spacing.buttonRadius),
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Header
  // ──────────────────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme, AppColors colors, AppSpacing spacing) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(spacing.xs),
          decoration: BoxDecoration(
            color: colors.warningColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(spacing.iconRadius),
          ),
          child: Icon(Icons.healing, color: colors.warningColor, size: 22),
        ),
        SizedBox(width: spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '跌倒了没关系，重要的是站起来',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '复发宽容机制',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        _buildForgivenessBadge(theme, colors),
      ],
    );
  }

  Widget _buildForgivenessBadge(ThemeData theme, AppColors colors) {
    final count = widget.summary.currentForgivenessCount;
    final remaining = 3 - count;
    final color = remaining == 3
        ? colors.successColor
        : remaining == 2
            ? colors.warningColor
            : remaining == 1
                ? colors.warningColor
                : colors.dangerColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '剩余 $remaining/3',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Stats row
  // ──────────────────────────────────────────────────────────
  Widget _buildStatsRow(ThemeData theme, AppColors colors, AppSpacing spacing) {
    final stats = [
      _StatItem(
        label: '总复发次数',
        value: '${widget.summary.totalRelapses}',
        color: colors.textTertiary,
      ),
      _StatItem(
        label: '本周',
        value: '${widget.summary.relapsesThisWeek}',
        color: widget.summary.relapsesThisWeek > 1
            ? colors.warningColor
            : colors.textTertiary,
      ),
      _StatItem(
        label: '距上次复发',
        value: '${widget.summary.daysSinceLastRelapse}天',
        color: widget.summary.daysSinceLastRelapse >= 7
            ? colors.successColor
            : colors.textTertiary,
      ),
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: spacing.xs,
              horizontal: spacing.xxs,
            ),
            child: Column(
              children: [
                Text(
                  s.value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: s.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  s.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Bounce-back rate
  // ──────────────────────────────────────────────────────────
  Widget _buildBounceBackRate(
      ThemeData theme, AppColors colors, AppSpacing spacing) {
    final rate = widget.summary.bounceBackRate;
    final percent = (rate * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '反弹恢复率',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$percent%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: rate >= 0.7
                    ? colors.successColor
                    : rate >= 0.4
                        ? colors.warningColor
                        : colors.dangerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.xxs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 8,
            backgroundColor: colors.dividerColor.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              rate >= 0.7
                  ? colors.successColor
                  : rate >= 0.4
                      ? colors.warningColor
                      : colors.dangerColor,
            ),
          ),
        ),
        SizedBox(height: spacing.xxs),
        Text(
          rate >= 0.7
              ? '你的恢复能力很棒！大多数复发后你都能回到正轨'
              : rate >= 0.4
                  ? '恢复率还可以，继续加油'
                  : '我们可以一起找到更好的恢复策略',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // Recovery trajectory
  // ──────────────────────────────────────────────────────────
  Widget _buildRecoveryTrajectory(
    ThemeData theme,
    AppColors colors,
    AppSpacing spacing,
    RecoveryTrajectory trajectory,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: colors.coachColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(spacing.inputRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 18, color: colors.coachColor),
              SizedBox(width: spacing.xs),
              Text(
                '恢复轨迹：${trajectory.trendDescription}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.coachColor,
                ),
              ),
              const Spacer(),
              Text(
                '${trajectory.recoveryScore}分',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.coachColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xxs),
          Text(
            trajectory.advice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Timeline
  // ──────────────────────────────────────────────────────────
  Widget _buildTimeline(
      ThemeData theme, AppColors colors, AppSpacing spacing) {
    final events = List<RelapseEvent>.from(widget.relapseEvents)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '复发记录',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing.xs),
        ...events.take(5).asMap().entries.map((entry) {
          final idx = entry.key;
          final event = entry.value;
          final tips = _recoveryTipsFor(event);

          return Column(
            children: [
              _buildTimelineItem(
                  theme, colors, spacing, event, tips, idx, events.length),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTimelineItem(
    ThemeData theme,
    AppColors colors,
    AppSpacing spacing,
    RelapseEvent event,
    List<String> tips,
    int index,
    int total,
  ) {
    final isLast = index == total - 1;
    final daysAgo =
        DateTime.now().difference(event.timestamp).inDays;

    String timeLabel;
    if (daysAgo == 0) {
      timeLabel = '今天';
    } else if (daysAgo == 1) {
      timeLabel = '昨天';
    } else if (daysAgo < 7) {
      timeLabel = '$daysAgo天前';
    } else if (daysAgo < 30) {
      timeLabel = '${daysAgo ~/ 7}周前';
    } else {
      timeLabel = '${daysAgo ~/ 30}月前';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: event.bouncedBack
                        ? colors.successColor
                        : colors.warningColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colors.dividerColor.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: spacing.sm),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        timeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      if (event.bouncedBack) ...[
                        SizedBox(width: spacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: colors.successColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '已恢复',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.successColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    '触发：${event.trigger}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (event.copingAttempted.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      '尝试：${event.copingAttempted}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                  if (tips.isNotEmpty) ...[
                    SizedBox(height: spacing.xxs),
                    ...tips.take(2).map((tip) => Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  size: 12, color: colors.coachColor),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.coachColor.withOpacity(0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Record dialog
  // ──────────────────────────────────────────────────────────
  void _showRecordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordRelapseSheet(
        onRecord: (event) {
          widget.onRelapseRecorded(event);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper data class
// ─────────────────────────────────────────────────────────────────────────────
class _StatItem {
  final String label;
  final String value;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Record Relapse Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RecordRelapseSheet extends StatefulWidget {
  final void Function(RelapseEvent event) onRecord;

  const _RecordRelapseSheet({required this.onRecord});

  @override
  State<_RecordRelapseSheet> createState() => _RecordRelapseSheetState();
}

class _RecordRelapseSheetState extends State<_RecordRelapseSheet> {
  final _triggerCtrl = TextEditingController();
  final _situationCtrl = TextEditingController();
  final _copingCtrl = TextEditingController();
  String _triggerCategory = '压力';
  bool _saving = false;

  final _triggerCategories = [
    '压力',
    '社交',
    '习惯',
    '情绪',
    '无聊',
    '其他',
  ];

  final _triggerHints = {
    '压力': '例如：工作压力大、遇到困难…',
    '社交': '例如：朋友递烟、聚会场合…',
    '习惯': '例如：饭后习惯、早上第一件事…',
    '情绪': '例如：心情低落、焦虑、生气…',
    '无聊': '例如：无所事事、空闲时间…',
    '其他': '描述发生了什么…',
  };

  @override
  void dispose() {
    _triggerCtrl.dispose();
    _situationCtrl.dispose();
    _copingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: spacing.cardPadding,
        right: spacing.cardPadding,
        top: spacing.sm,
        bottom: bottomInset + spacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: spacing.md),

          // Header — warm, non-judgmental
          Row(
            children: [
              Icon(Icons.healing, color: colors.companionColor, size: 28),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '记录一次跌倒',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '这只是了解自己的过程，没有任何评判',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.md),

          // Trigger category
          Text(
            '是什么触发了这次？',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: spacing.xs),
          Wrap(
            spacing: spacing.xxs,
            runSpacing: spacing.xxs,
            children: _triggerCategories.map((cat) {
              final selected = _triggerCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _triggerCategory = cat),
                labelStyle: TextStyle(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: spacing.sm),

          // Trigger detail
          TextField(
            controller: _triggerCtrl,
            decoration: InputDecoration(
              labelText: '具体发生了什么？',
              hintText: _triggerHints[_triggerCategory],
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            maxLines: 2,
          ),
          SizedBox(height: spacing.sm),

          // Situation
          TextField(
            controller: _situationCtrl,
            decoration: const InputDecoration(
              labelText: '当时你在哪里？和谁在一起？',
              hintText: '可选 — 帮助你发现模式',
              prefixIcon: Icon(Icons.place, size: 20),
            ),
            maxLines: 2,
          ),
          SizedBox(height: spacing.sm),

          // Coping attempted
          TextField(
            controller: _copingCtrl,
            decoration: InputDecoration(
              labelText: '你当时尝试了什么？',
              hintText: '即使没成功，任何尝试都值得记录',
              prefixIcon: Icon(Icons.favorite_border, size: 20),
            ),
            maxLines: 2,
          ),
          SizedBox(height: spacing.md),

          // Encouragement reminder
          Container(
            padding: EdgeInsets.all(spacing.sm),
            decoration: BoxDecoration(
              color: colors.companionColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(spacing.inputRadius),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: 16, color: colors.companionColor),
                SizedBox(width: spacing.xs),
                Expanded(
                  child: Text(
                    '每一次记录都是迈向更好的自己的一步。你做得很好。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.companionColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.md),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: spacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(spacing.buttonRadius),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('温柔地记录'),
            ),
          ),
          SizedBox(height: spacing.sm),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_triggerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请简单描述一下发生了什么')),
      );
      return;
    }
    setState(() => _saving = true);
    // Brief delay for UX feel
    await Future.delayed(const Duration(milliseconds: 300));
    final event = RelapseEvent(
      timestamp: DateTime.now(),
      trigger: _triggerCtrl.text.trim(),
      situation: _situationCtrl.text.trim().isEmpty
          ? null
          : _situationCtrl.text.trim(),
      copingAttempted: _copingCtrl.text.trim(),
      bouncedBack: false, // Will be updated later by the service
    );
    widget.onRecord(event);
  }
}
