import 'package:flutter/material.dart';

/// SOS breathing button and optional AI coach link.
///
/// Renders a prominent breathing button that triggers the
/// [onSos] callback (typically opens the breathing bottom-sheet)
/// and a smaller "跟AI教练聊聊" link that triggers [onCoach].
class SosButtonSection extends StatelessWidget {
  const SosButtonSection({
    super.key,
    required this.onSos,
    required this.onCoach,
  });

  /// Called when the user taps the breathing button.
  final VoidCallback onSos;

  /// Called when the user taps the "跟AI教练聊聊" link.
  final VoidCallback onCoach;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onSos,
              icon: const Icon(Icons.air_rounded, size: 20),
              label: const Text(
                '渴望来了？呼吸一下',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onCoach,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '或者跟AI教练聊聊',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
