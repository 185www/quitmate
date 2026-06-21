import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/ai_providers.dart';
import '../../../domain/entity/analysis.dart';

/// AI Insight Card — interactive card driven by [dailyInsightProvider].
///
/// Displays the daily AI-generated insight with:
/// - Gradient background that reflects insight type (critical → red,
///   warning → amber, achievement → green, etc.)
/// - Expand/collapse animation for the full body text
/// - Tap to refresh on collapse
/// - Loading spinner and error state with retry
class AiInsightCard extends ConsumerStatefulWidget {
  const AiInsightCard({super.key});

  @override
  ConsumerState<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends ConsumerState<AiInsightCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // Trigger initial insight generation on first build
    Future.microtask(() {
      if (mounted) ref.invalidate(dailyInsightProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final insightAsync = ref.watch(dailyInsightProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Determine gradient colors based on insight type
    final gradientColors = insightAsync.whenOrNull<List<Color>>(
      data: (insight) => _gradientForType(insight?.type, colorScheme),
    ) ?? [
      colorScheme.primary.withAlpha(200),
      colorScheme.primaryContainer.withAlpha(180),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          if (insightAsync.hasError || !insightAsync.hasValue) {
            // Retry on error or empty state
            ref.read(dailyInsightProvider.notifier).refresh();
            return;
          }
          setState(() => _expanded = !_expanded);
          if (!_expanded) {
            // Refresh when collapsing (user has seen the full insight)
            ref.read(dailyInsightProvider.notifier).refresh();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withAlpha(50),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '今日AI洞察',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          insightAsync.whenOrNull<Widget>(
                            data: (insight) => Text(
                              insight?.headline ?? '分析中…',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ) ??
                              const SizedBox.shrink(),
                        ],
                      ),
                    ),
                    if (insightAsync.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      )
                    else
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: Colors.white.withAlpha(180),
                        size: 20,
                      ),
                  ],
                ),

                // ── Body ──
                const SizedBox(height: 8),
                insightAsync.when<Widget>(
                  data: (insight) {
                    if (insight == null) {
                      return const Text(
                        '正在分析你的数据…',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          alignment: Alignment.topCenter,
                          child: Text(
                            insight.body,
                            style: const TextStyle(
                              color: Color(0xE6FFFFFF), // white90
                              fontSize: 14,
                              height: 1.5,
                            ),
                            maxLines: _expanded ? 10 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Action button
                        if (insight.actionRoute != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white.withAlpha(200),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  insight.actionText,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(200),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                        // Hint text
                        Text(
                          _expanded ? '点击收起 · 下拉刷新' : '点击展开详情',
                          style: TextStyle(
                            color: Colors.white.withAlpha(100),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Text(
                    '正在分析你的数据…',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  error: (e, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '洞察生成失败',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击重试',
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns gradient colors based on insight type.
  List<Color> _gradientForType(InsightType? type, ColorScheme colorScheme) {
    switch (type) {
      case InsightType.critical:
        return [
          Colors.red.shade700.withAlpha(220),
          Colors.red.shade900.withAlpha(200),
        ];
      case InsightType.warning:
        return [
          Colors.orange.shade700.withAlpha(220),
          Colors.amber.shade900.withAlpha(200),
        ];
      case InsightType.achievement:
        return [
          Colors.green.shade600.withAlpha(220),
          Colors.teal.shade800.withAlpha(200),
        ];
      case InsightType.motivational:
        return [
          colorScheme.primary.withAlpha(220),
          colorScheme.tertiary.withAlpha(200),
        ];
      case InsightType.neutral:
      default:
        return [
          colorScheme.primary.withAlpha(200),
          colorScheme.primaryContainer.withAlpha(180),
        ];
    }
  }
}
