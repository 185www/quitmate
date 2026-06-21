import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import '../../../../core/theme/app_theme.dart';

/// 冲浪会话记录数据点
class UrgeWaveDataPoint {
  /// 距离开始的时间（分钟）
  final double minutes;
  /// 渴望强度（0~10）
  final double intensity;

  const UrgeWaveDataPoint({
    required this.minutes,
    required this.intensity,
  });
}

/// 冲浪会话历史摘要
class UrgeWaveSessionSummary {
  /// 已完成的冲浪会话总数
  final int totalSessions;
  /// 平均持续时间（秒）
  final int averageDurationSeconds;
  /// 成功率（0.0 ~ 1.0）
  final double successRate;

  const UrgeWaveSessionSummary({
    required this.totalSessions,
    required this.averageDurationSeconds,
    required this.successRate,
  });
}

/// 与渴望日志联动 — 记录每次冲浪结果的波形图
///
/// 展示：
/// - TIPP 理论曲线：渴望在 ~3 分钟达到峰值后下降
/// - 用户实际记录的数据点
/// - 历史统计摘要
class UrgeWaveChart extends StatelessWidget {
  /// 用户在本次/最近一次冲浪中记录的渴望强度数据
  final List<UrgeWaveDataPoint> userEntries;

  /// 冲浪历史摘要
  final UrgeWaveSessionSummary? summary;

  /// 图表显示的总时长（分钟），默认 5 分钟
  final int totalMinutes;

  const UrgeWaveChart({
    super.key,
    this.userEntries = const [],
    this.summary,
    this.totalMinutes = 5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: EdgeInsets.all(spacing.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(spacing.cardRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 标题 ──
          Row(
            children: [
              Icon(
                Icons.waves_rounded,
                size: 20,
                color: appColors.coachColor,
              ),
              const SizedBox(width: 8),
              Text(
                '渴望像海浪，会来也会走',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),

          // ── 图表区域 ──
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _UrgeWaveChartPainter(
                isDark: isDark,
                totalMinutes: totalMinutes,
                userEntries: userEntries,
                primaryColor: Theme.of(context).colorScheme.primary,
                surfaceColor: Theme.of(context).colorScheme.surface,
                onSurfaceColor: Theme.of(context).colorScheme.onSurface,
                coachColor: appColors.coachColor,
                successColor: appColors.successColor,
              ),
            ),
          ),

          SizedBox(height: spacing.sm),

          // ── 图例 ──
          Row(
            children: [
              _buildLegend(
                context,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                label: '理论渴望曲线',
              ),
              const SizedBox(width: 16),
              _buildLegend(
                context,
                color: appColors.coachColor,
                label: '你的记录',
              ),
            ],
          ),

          // ── 历史统计 ──
          if (summary != null) ...[
            SizedBox(height: spacing.lg),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            SizedBox(height: spacing.md),
            _buildStatsRow(context, summary!, spacing, appColors),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context,
      {required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    UrgeWaveSessionSummary summary,
    AppSpacing spacing,
    AppColors appColors,
  ) {
    return Row(
      children: [
        _buildStatItem(
          context,
          icon: Icons.surfing_rounded,
          value: '${summary.totalSessions}',
          label: '冲浪次数',
          iconColor: appColors.coachColor,
        ),
        const Spacer(),
        _buildStatItem(
          context,
          icon: Icons.timer_outlined,
          value: '${summary.averageDurationSeconds ~/ 60}'
              ':'
              '${(summary.averageDurationSeconds % 60).toString().padLeft(2, '0')}',
          label: '平均时长',
          iconColor: appColors.companionColor,
        ),
        const Spacer(),
        _buildStatItem(
          context,
          icon: Icons.trending_up_rounded,
          value: '${(summary.successRate * 100).toInt()}%',
          label: '成功率',
          iconColor: appColors.successColor,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 波形图 CustomPainter
// ═══════════════════════════════════════════════════════════════════════════════

class _UrgeWaveChartPainter extends CustomPainter {
  final bool isDark;
  final int totalMinutes;
  final List<UrgeWaveDataPoint> userEntries;
  final Color primaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final Color coachColor;
  final Color successColor;

  // 绘图区域内边距
  static const double _paddingLeft = 32;
  static const double _paddingRight = 16;
  static const double _paddingTop = 12;
  static const double _paddingBottom = 28;

  _UrgeWaveChartPainter({
    required this.isDark,
    required this.totalMinutes,
    required this.userEntries,
    required this.primaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.coachColor,
    required this.successColor,
  });

  /// TIPP 理论渴望曲线：在 ~3 分钟达到峰值后下降
  ///
  /// 使用 gamma 分布变形：
  /// - 0~3min: 上升（快速攀升）
  /// - 3~5min: 下降（逐渐消退）
  double _theoreticalIntensity(double minutes) {
    if (minutes <= 0) return 2.0;
    if (minutes <= 3.0) {
      // 快速上升阶段
      final t = minutes / 3.0;
      return 2.0 + 7.0 * (1 - pow(1 - t, 2)); // 2→9
    } else {
      // 逐渐下降阶段
      final t = (minutes - 3.0) / (totalMinutes - 3.0);
      return 9.0 - 6.0 * t * (2 - t); // 9→3 (缓出)
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = _paddingLeft;
    final chartRight = size.width - _paddingRight;
    final chartTop = _paddingTop;
    final chartBottom = size.height - _paddingBottom;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    // ── 网格线 ──
    _drawGrid(canvas, size, chartLeft, chartRight, chartTop, chartBottom,
        chartWidth, chartHeight);

    // ── 理论曲线 ──
    _drawTheoreticalCurve(
        canvas, chartLeft, chartTop, chartWidth, chartHeight);

    // ── 用户数据点 ──
    _drawUserEntries(canvas, chartLeft, chartTop, chartWidth, chartHeight);
  }

  void _drawGrid(Canvas canvas, Size size, double chartLeft, double chartRight,
      double chartTop, double chartBottom, double chartWidth, double chartHeight) {
    final gridPaint = Paint()
      ..color = onSurfaceColor.withOpacity(isDark ? 0.08 : 0.06)
      ..strokeWidth = 0.5;

    // 水平线（强度刻度 0, 2, 4, 6, 8, 10）
    for (int intensity = 0; intensity <= 10; intensity += 2) {
      final y = chartBottom - (intensity / 10.0) * chartHeight;
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
    }

    // 垂直线（每分钟）
    for (int m = 0; m <= totalMinutes; m++) {
      final x = chartLeft + (m / totalMinutes) * chartWidth;
      canvas.drawLine(Offset(x, chartTop), Offset(x, chartBottom), gridPaint);
    }

    // ── Y轴标签 ──
    for (int intensity = 0; intensity <= 10; intensity += 2) {
      final y = chartBottom - (intensity / 10.0) * chartHeight;
      final textSpan = TextSpan(
        text: '$intensity',
        style: TextStyle(
          color: onSurfaceColor.withOpacity(isDark ? 0.4 : 0.35),
          fontSize: 9,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartLeft - tp.width - 6, y - tp.height / 2));
    }

    // ── X轴标签 ──
    for (int m = 0; m <= totalMinutes; m++) {
      final x = chartLeft + (m / totalMinutes) * chartWidth;
      final textSpan = TextSpan(
        text: '${m}分',
        style: TextStyle(
          color: onSurfaceColor.withOpacity(isDark ? 0.4 : 0.35),
          fontSize: 9,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartBottom + 6));
    }
  }

  void _drawTheoreticalCurve(Canvas canvas, double chartLeft, double chartTop,
      double chartWidth, double chartHeight) {
    final path = Path();
    final steps = 100;

    for (int i = 0; i <= steps; i++) {
      final minutes = (i / steps) * totalMinutes;
      final intensity = _theoreticalIntensity(minutes).clamp(0.0, 10.0);

      final x = chartLeft + (minutes / totalMinutes) * chartWidth;
      final y = chartTop + (1 - intensity / 10.0) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // 曲线下方渐变填充
    final fillPath = Path.from(path);
    fillPath.lineTo(chartLeft + chartWidth, chartTop + chartHeight);
    fillPath.lineTo(chartLeft, chartTop + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(isDark ? 0.12 : 0.08),
          primaryColor.withOpacity(0),
        ],
      ).createShader(Rect.fromLTRB(
          chartLeft, chartTop, chartLeft + chartWidth, chartTop + chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // 曲线描边
    final strokePaint = Paint()
      ..color = primaryColor.withOpacity(isDark ? 0.6 : 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // 峰值标记
    final peakMinutes = 3.0;
    final peakIntensity = _theoreticalIntensity(peakMinutes);
    final peakX = chartLeft + (peakMinutes / totalMinutes) * chartWidth;
    final peakY = chartTop + (1 - peakIntensity / 10.0) * chartHeight;

    final peakDashedPaint = Paint()
      ..color = onSurfaceColor.withOpacity(isDark ? 0.15 : 0.12)
      ..strokeWidth = 1;
    final dashPath = Path();
    for (double y = peakY; y <= chartTop + chartHeight; y += 6) {
      dashPath.moveTo(peakX, y);
      dashPath.lineTo(peakX, min(y + 3, chartTop + chartHeight));
    }
    canvas.drawPath(dashPath, peakDashedPaint);

    // 峰值标签
    final peakLabel = TextSpan(
      text: '峰值',
      style: TextStyle(
        color: onSurfaceColor.withOpacity(isDark ? 0.5 : 0.4),
        fontSize: 9,
      ),
    );
    final peakTp = TextPainter(
      text: peakLabel,
      textDirection: TextDirection.ltr,
    )..layout();
    peakTp.paint(canvas, Offset(peakX - peakTp.width / 2, peakY - 16));
  }

  void _drawUserEntries(Canvas canvas, double chartLeft, double chartTop,
      double chartWidth, double chartHeight) {
    if (userEntries.isEmpty) return;

    // 用户数据点连线
    if (userEntries.length > 1) {
      final sortedEntries = List<UrgeWaveDataPoint>.from(userEntries)
        ..sort((a, b) => a.minutes.compareTo(b.minutes));

      final userPath = Path();
      for (int i = 0; i < sortedEntries.length; i++) {
        final entry = sortedEntries[i];
        final x = chartLeft + (entry.minutes / totalMinutes) * chartWidth;
        final y = chartTop + (1 - entry.intensity / 10.0) * chartHeight;

        if (i == 0) {
          userPath.moveTo(x, y);
        } else {
          // 平滑贝塞尔曲线
          final prev = sortedEntries[i - 1];
          final prevX =
              chartLeft + (prev.minutes / totalMinutes) * chartWidth;
          final prevY =
              chartTop + (1 - prev.intensity / 10.0) * chartHeight;
          final cpX = (prevX + x) / 2;
          userPath.cubicTo(cpX, prevY, cpX, y, x, y);
        }
      }

      final userStrokePaint = Paint()
        ..color = coachColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(userPath, userStrokePaint);
    }

    // 用户数据点
    for (final entry in userEntries) {
      final x = chartLeft + (entry.minutes / totalMinutes) * chartWidth;
      final y = chartTop + (1 - entry.intensity / 10.0) * chartHeight;

      // 外圈光晕
      final glowPaint = Paint()
        ..color = coachColor.withOpacity(0.2);
      canvas.drawCircle(Offset(x, y), 8, glowPaint);

      // 内圈
      final dotPaint = Paint()
        ..color = coachColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      // 白色中心
      final centerPaint = Paint()
        ..color = isDark ? surfaceColor : Colors.white;
      canvas.drawCircle(Offset(x, y), 2, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _UrgeWaveChartPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.totalMinutes != totalMinutes ||
        !listEquals(oldDelegate.userEntries, userEntries);
  }
}