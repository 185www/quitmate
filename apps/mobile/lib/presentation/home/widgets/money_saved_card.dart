/// Money saved card — shows cumulative savings since the quit date and the
/// user's daily cost rate, with a formatted currency display.
///
/// Extracted from `dashboard_screen.dart`'s `_buildQuickStats` section.
/// Designed as a standalone card that can be embedded in the quick-stats
/// row or displayed independently on the analysis / reports screen.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entity/user.dart';

/// A card displaying the money the user has saved since their quit date.
///
/// Computes savings from [User.dailyCost] × [User.daysSinceQuit] and
/// presents it with a themed piggy-bank / savings icon, a large
/// formatted currency label, and a subtle daily-rate footer.
///
/// Example:
/// ```dart
/// MoneySavedCard(
///   user: myUser,
///   onTap: () => showSavingsBreakdown(context),
/// )
/// ```
class MoneySavedCard extends StatelessWidget {
  /// The user entity — must have a valid [User.quitDate] for meaningful data.
  final User user;

  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;

  /// Currency symbol used for display (defaults to ¥).
  final String currencySymbol;

  /// Whether to show the daily cost rate footer.
  final bool showDailyRate;

  const MoneySavedCard({
    super.key,
    required this.user,
    this.onTap,
    this.currencySymbol = '¥',
    this.showDailyRate = true,
  });

  /// Total money saved since quit date.
  double get _totalSaved => user.dailyCost * user.daysSinceQuit;

  /// Formats [value] using [NumberFormat] for locale-aware display.
  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = Theme.of(context).extension<AppSpacing>();
    final r = spacing?.cardRadius ?? 16;

    if (!user.hasQuitDate) return const SizedBox.shrink();

    final saved = _totalSaved;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: colorScheme.primaryContainer.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: spacing?.md ?? 16,
            horizontal: spacing?.sm ?? 12,
          ),
          child: Column(
            children: [
              // Piggy bank / savings icon
              Icon(
                Icons.savings_outlined,
                color: colorScheme.primary,
                size: 22,
              ),
              SizedBox(height: spacing?.xxs ?? 4),
              // Label
              Text(
                '已节省',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing?.xxs ?? 4),
              // Large formatted number
              Text(
                _formatCurrency(saved),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              // Daily rate subtitle
              if (showDailyRate) ...[
                SizedBox(height: spacing?.xxs ?? 4),
                Text(
                  '每日节省 ${currencySymbol}${user.dailyCost.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
