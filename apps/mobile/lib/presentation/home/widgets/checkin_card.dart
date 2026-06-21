import 'package:flutter/material.dart';
import '../../../domain/entity/daily_log.dart';

/// Daily check-in card with mood emoji selectors and urge-level pills.
///
/// When a [DailyLogEntry] already exists for today the card shows a
/// read-only summary ("今日已记录").  Otherwise it renders the interactive
/// mood / urge selectors and a "保存打卡" button.
///
/// Internal state for [_selectedMood] and [_selectedUrge] is owned by
/// this widget.  The [onSave] callback receives the final mood and urge
/// values chosen by the user.
class CheckinCard extends StatefulWidget {
  const CheckinCard({
    super.key,
    required this.todayLogFuture,
    required this.onSave,
  });

  /// Resolves to today's log entry, or `null` if not yet logged.
  final Future<DailyLogEntry?> todayLogFuture;

  /// Called when the user taps "保存打卡" with the selected mood and urge.
  final Future<void> Function(int mood, int urge) onSave;

  @override
  State<CheckinCard> createState() => _CheckinCardState();
}

class _CheckinCardState extends State<CheckinCard> {
  int _selectedMood = 3;
  int _selectedUrge = 1;

  // ── Helpers ────────────────────────────────────────────────────────

  String _moodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😊';
      default:
        return '😐';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DailyLogEntry?>(
      future: widget.todayLogFuture,
      builder: (context, snap) {
        final log = snap.data;
        final logged = log != null;
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (logged) ...[
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '今日已记录',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('心情 ', style: Theme.of(context).textTheme.bodySmall),
                      Text(_moodEmoji(log.mood),
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 20),
                      Text('渴望 ', style: Theme.of(context).textTheme.bodySmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (log.urgeLevel != null && log.urgeLevel! > 5)
                              ? colorScheme.errorContainer.withOpacity(0.6)
                              : colorScheme.primaryContainer.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          log.urgeLevel != null
                              ? (log.urgeLevel! <= 3
                                  ? '无渴望'
                                  : log.urgeLevel! <= 6
                                      ? '有点想'
                                      : '非常想')
                              : '无',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: (log.urgeLevel != null && log.urgeLevel! > 5)
                                ? colorScheme.onErrorContainer
                                : colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '今天感觉怎么样？',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 14),
                  // Mood emojis
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _moodButton('😢', 1),
                      _moodButton('😕', 2),
                      _moodButton('😐', 3),
                      _moodButton('🙂', 4),
                      _moodButton('😊', 5),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Urge pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _urgePill('无渴望', 1),
                      _urgePill('轻微', 3),
                      _urgePill('中等', 5),
                      _urgePill('较强', 7),
                      _urgePill('强烈', 10),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 36,
                      child: FilledButton.tonal(
                        onPressed: () => widget.onSave(_selectedMood, _selectedUrge),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('保存打卡'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────

  Widget _moodButton(String emoji, int value) {
    final selected = _selectedMood == value;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedMood = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withOpacity(0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          shape: BoxShape.rectangle,
        ),
        child: AnimatedOpacity(
          opacity: selected ? 1.0 : 0.35,
          duration: const Duration(milliseconds: 200),
          child: Text(emoji, style: TextStyle(fontSize: selected ? 34 : 28)),
        ),
      ),
    );
  }

  Widget _urgePill(String label, int value) {
    final selected = _selectedUrge == value;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedUrge = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
