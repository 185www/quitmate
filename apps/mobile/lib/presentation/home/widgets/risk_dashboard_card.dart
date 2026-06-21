/// Dashboard card showing daily relapse risk score and ML predictions.
///
/// Displays a compact risk gauge, color-coded by risk level, with top risk
/// factors as chips and a primary suggestion. Tapping expands to show a
/// detailed factor breakdown with bar charts. High-risk state adds a
/// subtle pulsing red glow animation.
///
/// Theme-compliant, dark-mode support, all text in Chinese.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ml/craving_predictor.dart';
import '../../../core/ml/relapse_risk_engine.dart';

/// A dashboard card that displays the user's daily relapse risk assessment
/// and ML craving predictions.
///
/// Pass in a pre-computed [RelapseRiskAssessment] and optional
/// [CravingPrediction] to render.
///
/// Example:
/// ```dart
/// RiskDashboardCard(
///   assessment: myAssessment,
///   prediction: myPrediction,
///   onViewPrediction: () => context.push('/prediction-detail'),
/// )
/// ```
class RiskDashboardCard extends StatefulWidget {
  /// Pre-computed relapse risk assessment.
  final RelapseRiskAssessment assessment;

  /// Optional pre-computed craving prediction.
  final CravingPrediction? prediction;

  /// Callback when "查看预测" button is pressed.
  final VoidCallback? onViewPrediction;

  const RiskDashboardCard({
    super.key,
    required this.assessment,
    this.prediction,
    this.onViewPrediction,
  });

  @override
  State<RiskDashboardCard> createState() => _RiskDashboardCardState();
}

class _RiskDashboardCardState extends State<RiskDashboardCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  // Animation controller for the pulsing glow on high-risk.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Animation controller for the score counter.
  late final AnimationController _scoreController;
  late final Animation<int> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = IntTween(
      begin: 0,
      end: widget.assessment.overallScore,
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    ));

    _scoreController.forward();
  }

  @override
  void didUpdateWidget(covariant RiskDashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assessment.overallScore != widget.assessment.overallScore) {
      _scoreAnimation = IntTween(
        begin: _scoreAnimation.value,
        end: widget.assessment.overallScore,
      ).animate(CurvedAnimation(
        parent: _scoreController,
        curve: Curves.easeOutCubic,
      ));
      _scoreController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  // ── Color helpers ──────────────────────────────────────────────────────

  Color _riskColor(BuildContext context, RiskLevel level) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();

    switch (level) {
      case RiskLevel.low:
        return appColors?.successColor ?? const Color(0xFF4CAF50);
      case RiskLevel.moderate:
        return appColors?.warningColor ?? const Color(0xFFFFB74D);
      case RiskLevel.high:
        return const Color(0xFFFF9800);
      case RiskLevel.critical:
        return appColors?.dangerColor ?? colorScheme.error;
    }
  }

  Color _riskBgColor(BuildContext context, RiskLevel level) {
    return _riskColor(context, level).withOpacity(0.10);
  }

  String _levelLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return '低风险';
      case RiskLevel.moderate:
        return '一般风险';
      case RiskLevel.high:
        return '较高风险';
      case RiskLevel.critical:
        return '高风险';
    }
  }

  String _levelEmoji(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return '✅';
      case RiskLevel.moderate:
        return '⚠️';
      case RiskLevel.high:
        return '🔶';
      case RiskLevel.critical:
        return '🔴';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    final spacing = Theme.of(context).extension<AppSpacing>();
    final r = spacing?.cardRadius ?? 16;
    final p = spacing?.cardPadding ?? 20;

    final assessment = widget.assessment;
    final level = assessment.level;
    final riskColor = _riskColor(context, level);
    final isCritical = level == RiskLevel.critical;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            border: Border.all(
              color: isCritical
                  ? riskColor.withOpacity(
                      0.3 + _pulseAnimation.value * 0.4)
                  : colorScheme.outlineVariant,
              width: isCritical ? 1.5 : 0.5,
            ),
            boxShadow: isCritical
                ? [
                    BoxShadow(
                      color: riskColor.withOpacity(
                          0.08 + _pulseAnimation.value * 0.12),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r),
              side: BorderSide.none,
            ),
            child: Padding(
              padding: EdgeInsets.all(p),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────
                  _buildHeader(
                      context, assessment, level, riskColor, spacing),
                  SizedBox(height: spacing?.sm ?? 12),

                  // ── Risk gauge + score ────────────────────────────────
                  _buildGaugeSection(
                      context, assessment, level, riskColor, spacing),
                  SizedBox(height: spacing?.sm ?? 12),

                  // ── Top risk factor chips ────────────────────────────
                  _buildFactorChips(
                      context, assessment.factors, riskColor, spacing),
                  SizedBox(height: spacing?.sm ?? 12),

                  // ── Primary suggestion ────────────────────────────────
                  _buildSuggestion(context, assessment.suggestions, spacing),

                  // ── Expanded detail ──────────────────────────────────
                  if (_expanded) ...[
                    SizedBox(height: spacing?.md ?? 16),
                    const Divider(height: 1),
                    SizedBox(height: spacing?.md ?? 16),
                    _buildFactorBreakdown(
                        context, assessment.factors, riskColor, spacing),

                    // ── Prediction section (if available) ──────────────
                    if (widget.prediction != null) ...[
                      SizedBox(height: spacing?.md ?? 16),
                      _buildPredictionSection(context, widget.prediction!,
                          spacing),
                    ],
                  ],

                  // ── Expand / collapse toggle ──────────────────────────
                  SizedBox(height: spacing?.sm ?? 12),
                  _buildExpandToggle(context, spacing),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Header row ─────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    RelapseRiskAssessment assessment,
    RiskLevel level,
    Color riskColor,
    AppSpacing? spacing,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _riskBgColor(context, level),
            borderRadius:
                BorderRadius.circular(spacing?.iconRadius ?? 10),
          ),
          child: Center(
            child: Text(
              _levelEmoji(level),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        SizedBox(width: spacing?.sm ?? 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今日风险评估',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    _levelLabel(level),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: riskColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${assessment.factors.length} 项评估因子',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Confidence badge (from prediction if available).
        if (widget.prediction != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius:
                  BorderRadius.circular(spacing?.chipRadius ?? 20),
            ),
            child: Text(
              '置信度 ${(widget.prediction!.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  // ── Risk gauge + animated score ────────────────────────────────────────

  Widget _buildGaugeSection(
    BuildContext context,
    RelapseRiskAssessment assessment,
    RiskLevel level,
    Color riskColor,
    AppSpacing? spacing,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Circular gauge.
        SizedBox(
          width: 80,
          height: 80,
          child: AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, _) {
              return CustomPaint(
                painter: _RiskGaugePainter(
                  score: _scoreAnimation.value.toDouble(),
                  maxScore: 100,
                  color: riskColor,
                  trackColor: colorScheme.surfaceContainerHighest,
                  strokeWidth: 8,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_scoreAnimation.value}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: riskColor,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        '/100',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(width: spacing?.md ?? 16),
        // Summary text.
        Expanded(
          child: Text(
            assessment.summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }

  // ── Top risk factor chips ─────────────────────────────────────────────

  Widget _buildFactorChips(
    BuildContext context,
    List<RiskFactor> factors,
    Color riskColor,
    AppSpacing? spacing,
  ) {
    // Show top 3 factors by weighted score.
    final sorted = List<RiskFactor>.from(factors)
      ..sort((a, b) => (b.score * b.weight).compareTo(a.score * a.weight));
    final top3 = sorted.take(3).toList();

    if (top3.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: spacing?.xxs ?? 4,
      runSpacing: (spacing?.xxs ?? 4) + 2,
      children: top3.map((factor) {
        final factorColor = _factorColor(context, factor.score);
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: factorColor.withOpacity(0.10),
            borderRadius:
                BorderRadius.circular(spacing?.chipRadius ?? 20),
            border: Border.all(
              color: factorColor.withOpacity(0.25),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _factorIcon(factor.icon),
                size: 12,
                color: factorColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${factor.name} ${factor.score.round()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _factorColor(BuildContext context, double score) {
    final appColors = Theme.of(context).extension<AppColors>();
    final colorScheme = Theme.of(context).colorScheme;

    if (score <= 25) {
      return appColors?.successColor ?? const Color(0xFF4CAF50);
    } else if (score <= 50) {
      return appColors?.warningColor ?? const Color(0xFFFFB74D);
    } else if (score <= 75) {
      return const Color(0xFFFF9800);
    }
    return appColors?.dangerColor ?? colorScheme.error;
  }

  IconData _factorIcon(String iconName) {
    // Map string names to Material icons.
    switch (iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'flash_on':
        return Icons.flash_on;
      case 'sentiment_satisfied':
        return Icons.sentiment_satisfied;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'warning_amber':
        return Icons.warning_amber;
      case 'schedule':
        return Icons.schedule;
      case 'groups':
        return Icons.groups;
      default:
        return Icons.info_outline;
    }
  }

  // ── Primary suggestion ──────────────────────────────────────────────────

  Widget _buildSuggestion(
    BuildContext context,
    List<String> suggestions,
    AppSpacing? spacing,
  ) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (appColors?.coachColor ?? colorScheme.primary).withOpacity(0.06),
        borderRadius:
            BorderRadius.circular(spacing?.chipRadius ?? 12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: appColors?.coachColor ?? colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              suggestions.first,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Factor breakdown (expanded) ────────────────────────────────────────

  Widget _buildFactorBreakdown(
    BuildContext context,
    List<RiskFactor> factors,
    Color baseRiskColor,
    AppSpacing? spacing,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '风险评估详情',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing?.sm ?? 12),
        ...factors.map((factor) => Padding(
              padding: EdgeInsets.only(
                  bottom: (spacing?.itemGap ?? 12) - 4),
              child: _FactorBarRow(
                factor: factor,
                color: _factorColor(context, factor.score),
              ),
            )),
      ],
    );
  }

  // ── Prediction section (expanded) ─────────────────────────────────────

  Widget _buildPredictionSection(
    BuildContext context,
    CravingPrediction prediction,
    AppSpacing? spacing,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '渴望预测',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing?.sm ?? 12),

        // High-risk windows.
        if (prediction.highRiskWindows.isNotEmpty) ...[
          Text(
            '高危时段',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 6),
          ...prediction.highRiskWindows.take(3).map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 14,
                        color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${CravingPredictor.formatHour(w.startHour)}'
                        '-'
                        '${CravingPredictor.formatHour(w.endHour)}'
                        ' (风险 ${(w.riskLevel * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],

        // Top triggers.
        if (prediction.triggerAnalysis.topTriggers.isNotEmpty) ...[
          SizedBox(height: spacing?.xs ?? 8),
          Text(
            '高风险触发因素',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 6),
          ...prediction.triggerAnalysis.topTriggers.take(3).map((t) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 14,
                        color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${t.trigger}（平均强度 ${t.avgIntensity.toStringAsFixed(1)}，'
                        '解决率 ${(t.resolutionRate * 100).toStringAsFixed(0)}%）',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],

        // Trend.
        SizedBox(height: spacing?.xs ?? 8),
        Text(
          '趋势：${_trendLabel(prediction.trendDirection)}',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        // Summary.
        if (prediction.summary.isNotEmpty) ...[
          SizedBox(height: 6),
          Text(
            prediction.summary,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  String _trendLabel(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.improving:
        return '向好 ↓';
      case TrendDirection.stable:
        return '平稳 →';
      case TrendDirection.worsening:
        return '恶化 ↑';
    }
  }

  // ── Expand / collapse toggle ──────────────────────────────────────────

  Widget _buildExpandToggle(BuildContext context, AppSpacing? spacing) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();

    return Column(
      children: [
        // "查看预测" button.
        if (widget.onViewPrediction != null)
          Padding(
            padding: EdgeInsets.only(bottom: spacing?.xs ?? 8),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton.tonal(
                onPressed: widget.onViewPrediction,
                style: FilledButton.styleFrom(
                  backgroundColor: (appColors?.coachColor ??
                          colorScheme.primary)
                      .withOpacity(0.10),
                  foregroundColor:
                      appColors?.coachColor ?? colorScheme.primary,
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
                child: const Text('查看预测'),
              ),
            ),
          ),

        // Expand detail toggle.
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _expanded ? '收起详情' : '展开详情',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom gauge painter
// ─────────────────────────────────────────────────────────────────────────────

class _RiskGaugePainter extends CustomPainter {
  final double score;
  final double maxScore;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RiskGaugePainter({
    required this.score,
    required this.maxScore,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth * 2) / 2;

    // Arc from 135° to 405° (270° sweep).
    final startAngle = 3 * math.pi / 4;
    final sweepAngle = 3 * math.pi / 2;

    // Track (background).
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Progress arc.
    final fraction = (score / maxScore).clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * fraction,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Factor bar row widget
// ─────────────────────────────────────────────────────────────────────────────

class _FactorBarRow extends StatelessWidget {
  final RiskFactor factor;
  final Color color;

  const _FactorBarRow({required this.factor, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _mapIcon(factor.icon),
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                factor.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '${factor.score.round()}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (factor.score / 100).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          factor.description,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  IconData _mapIcon(String name) {
    switch (name) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'flash_on':
        return Icons.flash_on;
      case 'sentiment_satisfied':
        return Icons.sentiment_satisfied;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'warning_amber':
        return Icons.warning_amber;
      case 'schedule':
        return Icons.schedule;
      case 'groups':
        return Icons.groups;
      default:
        return Icons.info_outline;
    }
  }
}
