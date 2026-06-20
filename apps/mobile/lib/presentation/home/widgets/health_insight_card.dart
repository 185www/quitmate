// ═══════════════════════════════════════════════════════════════════════════════
// P1.2.4 — Health Insight Card (Dashboard Widget)
//
// Shows adaptive health insights on the home dashboard.
// When high stress / poor sleep is detected, proactively pushes guidance.
// Users can self-report sleep hours and stress level via an inline dialog.
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/health/health_data_service.dart';
import '../../../core/health/stress_intervention_engine.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HealthInsightCard
// ─────────────────────────────────────────────────────────────────────────────

/// A dashboard card that adapts its content based on the latest
/// [HealthSnapshot].
///
/// States:
/// - **No data** → prompt to record with a "记录" button.
/// - **High stress** → breathing exercise suggestion.
/// - **Poor sleep** → rest reminder.
/// - **Good state** → positive reinforcement.
///
/// All colours and radii come from the theme — zero hardcoded values.
class HealthInsightCard extends ConsumerStatefulWidget {
  const HealthInsightCard({super.key});

  @override
  ConsumerState<HealthInsightCard> createState() => _HealthInsightCardState();
}

class _HealthInsightCardState extends ConsumerState<HealthInsightCard> {
  HealthSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    final service = ref.read(healthServiceProvider);
    final snapshot = await service.getLatestSnapshot();
    if (mounted) setState(() => _snapshot = snapshot);

    // Also listen for real-time updates
    service.healthStream.listen((s) {
      if (mounted) setState(() => _snapshot = s);
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    final spacing = Theme.of(context).extension<AppSpacing>();
    final r = spacing?.cardRadius ?? 16;
    final p = spacing?.cardPadding ?? 20;

    // Determine card state
    final hasData = _snapshot != null;
    final isHighStress = _snapshot?.isHighStress ?? false;
    final isPoorSleep = _snapshot?.isPoorSleep ?? false;
    final isGood = _snapshot?.isGoodState ?? false;

    // Pick icon & accent colour
    final IconData icon;
    final Color accent;
    final String title;
    final String subtitle;

    if (!hasData) {
      icon = Icons.favorite_border_rounded;
      accent = colorScheme.primary;
      title = '健康数据';
      subtitle = '记录今天的睡眠和压力水平';
    } else if (isHighStress) {
      icon = Icons.air_rounded;
      accent = appColors?.dangerColor ?? colorScheme.error;
      title = '今天压力较大，试试呼吸放松';
      subtitle = '压力水平 ${_snapshot!.stressLevel}/10';
    } else if (isPoorSleep) {
      icon = Icons.dark_mode_rounded;
      accent = appColors?.warningColor ?? colorScheme.tertiary;
      title = '昨晚睡眠不足，注意休息';
      subtitle = '睡眠 ${_snapshot!.sleepHours?.toStringAsFixed(1) ?? '?'} 小时';
    } else if (isGood) {
      icon = Icons.sentiment_satisfied_alt_rounded;
      accent = appColors?.successColor ?? colorScheme.primary;
      title = '今天状态不错，继续保持！';
      subtitle = '身心状态良好';
    } else {
      icon = Icons.monitor_heart_outlined;
      accent = colorScheme.primary;
      title = '健康数据';
      subtitle = '已记录今日数据';
    }

    // Run intervention engine to possibly get a secondary insight
    final engine = StressInterventionEngine();
    final interventions = engine.evaluate(health: _snapshot);
    final InterventionSuggestion? topIntervention =
        interventions.isNotEmpty ? interventions.first : null;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
      child: Padding(
        padding: EdgeInsets.all(p),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(spacing?.iconRadius ?? 10),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                SizedBox(width: spacing?.sm ?? 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Mini stats row (when data exists) ──────────────────────
            if (hasData) ...[
              SizedBox(height: spacing?.sm ?? 12),
              _MiniStatsRow(snapshot: _snapshot!),
            ],

            // ── Intervention insight chip ───────────────────────────────
            if (topIntervention != null &&
                topIntervention.type != 'positive') ...[
              SizedBox(height: spacing?.sm ?? 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(spacing?.chipRadius ?? 12),
                ),
                child: Row(
                  children: [
                    Icon(
                      topIntervention.type == 'sos'
                          ? Icons.warning_amber_rounded
                          : topIntervention.type == 'breathing'
                              ? Icons.air_rounded
                              : Icons.bedtime_rounded,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        topIntervention.body,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Record / update button ─────────────────────────────────
            SizedBox(height: spacing?.sm ?? 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton.tonal(
                onPressed: () => _showReportDialog(context),
                style: FilledButton.styleFrom(
                  backgroundColor: (hasData
                          ? appColors?.coachColor ?? colorScheme.secondary
                          : colorScheme.primary)
                      .withOpacity(0.15),
                  foregroundColor: hasData
                      ? (appColors?.coachColor ?? colorScheme.secondary)
                      : colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        spacing?.buttonRadius ?? 12),
                  ),
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(hasData ? '更新健康数据' : '记录健康数据'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Self-report dialog ─────────────────────────────────────────────────

  Future<void> _showReportDialog(BuildContext context) async {
    final spacing = Theme.of(context).extension<AppSpacing>();
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();

    // Pre-fill from existing snapshot
    double sleepHours = _snapshot?.sleepHours ?? 7.0;
    double stressLevel = (_snapshot?.stressLevel ?? 5).toDouble();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(spacing?.cardRadius ?? 20),
          ),
          title: Text(
            '记录健康数据',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Sleep hours ──────────────────────────────────────────
              Text(
                '昨晚睡眠时长（小时）',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _NumberStepper(
                    value: sleepHours,
                    min: 0,
                    max: 14,
                    step: 0.5,
                    onChanged: (v) => setDialogState(() => sleepHours = v),
                    accentColor: colorScheme.primary,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Stress level slider ──────────────────────────────────
              Text(
                '当前压力水平',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '轻松',
                    style: TextStyle(
                        fontSize: 11,
                        color: (appColors?.successColor ??
                            colorScheme.primary)),
                  ),
                  Text(
                    '极大',
                    style: TextStyle(
                        fontSize: 11,
                        color: (appColors?.dangerColor ??
                            colorScheme.error)),
                  ),
                ],
              ),
              Slider(
                value: stressLevel,
                min: 1,
                max: 10,
                divisions: 9,
                label: '${stressLevel.round()}',
                onChanged: (v) => setDialogState(() => stressLevel = v),
                activeColor: _stressSliderColor(
                    stressLevel, appColors, colorScheme),
              ),
              Center(
                child: Text(
                  '${stressLevel.round()} / 10',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _stressSliderColor(
                        stressLevel, appColors, colorScheme),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final snapshot = HealthSnapshot(
                  timestamp: DateTime.now(),
                  sleepHours: sleepHours,
                  stressLevel: stressLevel.round(),
                  source: 'self_report',
                );
                await ref
                    .read(healthServiceProvider)
                    .recordSelfReport(snapshot);
                if (mounted) {
                  setState(() => _snapshot = snapshot);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Color _stressSliderColor(
    double level,
    AppColors? appColors,
    ColorScheme colorScheme,
  ) {
    if (level >= 7) return appColors?.dangerColor ?? colorScheme.error;
    if (level >= 4) return appColors?.warningColor ?? colorScheme.tertiary;
    return appColors?.successColor ?? colorScheme.primary;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MiniStatsRow — sleep, stress bar, heart rate
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStatsRow extends StatelessWidget {
  final HealthSnapshot snapshot;
  const _MiniStatsRow({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    final spacing = Theme.of(context).extension<AppSpacing>();

    return Row(
      children: [
        // Sleep
        if (snapshot.sleepHours != null)
          Expanded(
            child: _MiniStat(
              icon: Icons.dark_mode_outlined,
              iconColor: colorScheme.primary,
              label: '睡眠',
              value: '${snapshot.sleepHours!.toStringAsFixed(1)}h',
              spacing: spacing,
            ),
          ),

        if (snapshot.sleepHours != null && snapshot.stressLevel != null)
          SizedBox(width: spacing?.xs ?? 8),

        // Stress bar
        if (snapshot.stressLevel != null)
          Expanded(
            child: _MiniStat(
              icon: Icons.emoji_emotions_outlined,
              iconColor: _stressColor(snapshot.stressLevel!, appColors, colorScheme),
              label: '压力',
              value: '${snapshot.stressLevel}/10',
              spacing: spacing,
              barValue: snapshot.stressLevel! / 10,
              barColor: _stressColor(snapshot.stressLevel!, appColors, colorScheme),
            ),
          ),

        if (snapshot.stressLevel != null && snapshot.heartRateBpm != null)
          SizedBox(width: spacing?.xs ?? 8),

        // Heart rate
        if (snapshot.heartRateBpm != null)
          Expanded(
            child: _MiniStat(
              icon: Icons.favorite_outline,
              iconColor: appColors?.dangerColor ?? colorScheme.error,
              label: '心率',
              value: '${snapshot.heartRateBpm!.round()} bpm',
              spacing: spacing,
            ),
          ),
      ],
    );
  }

  Color _stressColor(int level, AppColors? c, ColorScheme cs) {
    if (level >= 7) return c?.dangerColor ?? cs.error;
    if (level >= 4) return c?.warningColor ?? cs.tertiary;
    return c?.successColor ?? cs.primary;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MiniStat — single stat cell
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final AppSpacing? spacing;
  final double? barValue;
  final Color? barColor;

  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.spacing,
    this.barValue,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        if (barValue != null && barColor != null) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: barValue!.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(barColor!),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NumberStepper — compact +/- control for sleep hours
// ─────────────────────────────────────────────────────────────────────────────

class _NumberStepper extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final Color accentColor;

  const _NumberStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, size: 18, color: accentColor),
            onPressed: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 18, color: accentColor),
            onPressed: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}