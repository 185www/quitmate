/// Quick actions row — a horizontally scrollable row of action buttons,
/// each rendered as a rounded card with an icon and label.
///
/// Extracted from `dashboard_screen.dart`'s action shortcuts section.
/// Pure widget — all actions are passed in via [ActionItem] data objects.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A data object representing a single action in the row.
///
/// Each action has a required icon, label, and tap callback,
/// with an optional colour override.
class ActionItem {
  /// Icon displayed above the label text.
  final IconData icon;

  /// Descriptive label below the icon.
  final String label;

  /// Callback invoked when this action is tapped.
  final VoidCallback onTap;

  /// Optional colour override for the card background / icon tint.
  /// Falls back to [Theme.of(context).colorScheme.primary] when omitted.
  final Color? color;

  const ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

/// A horizontal scrollable row of action buttons.
///
/// Each action is rendered as a rounded card with the icon on top
/// and label text below. The row scrolls horizontally when actions
/// overflow the available width.
///
/// Example:
/// ```dart
/// QuickActionsRow(
///   actions: [
///     ActionItem(icon: Icons.psychology, label: '渴望冲浪', onTap: () { ... }),
///     ActionItem(icon: Icons.chat, label: 'AI教练', onTap: () { ... }),
///     ActionItem(icon: Icons.fitness_center, label: '技能练习', onTap: () { ... }),
///   ],
/// )
/// ```
class QuickActionsRow extends StatelessWidget {
  /// The list of actions to display. Order is preserved.
  final List<ActionItem> actions;

  /// Optional height for each action card. Defaults to 76.
  final double cardHeight;

  /// Optional width for each action card. Defaults to 80.
  final double cardWidth;

  const QuickActionsRow({
    super.key,
    required this.actions,
    this.cardHeight = 76,
    this.cardWidth = 80,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = Theme.of(context).extension<AppSpacing>();
    final r = spacing?.cardRadius ?? 16;

    if (actions.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: spacing?.screenPadding ?? 20),
      child: Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            _ActionCard(
              action: actions[i],
              colorScheme: colorScheme,
              spacing: spacing,
              radius: r,
              height: cardHeight,
              width: cardWidth,
            ),
            if (i < actions.length - 1)
              SizedBox(width: spacing?.itemGap ?? 10),
          ],
        ],
      ),
    );
  }
}

/// Internal card widget for a single action item.
class _ActionCard extends StatelessWidget {
  final ActionItem action;
  final ColorScheme colorScheme;
  final AppSpacing? spacing;
  final double radius;
  final double height;
  final double width;

  const _ActionCard({
    required this.action,
    required this.colorScheme,
    this.spacing,
    required this.radius,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = action.color ?? colorScheme.primary;

    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: effectiveColor.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(
                    spacing?.iconRadius ?? 10),
              ),
              child: Icon(
                action.icon,
                color: effectiveColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            // Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                action.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
