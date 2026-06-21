/// Shared breathing rhythm constants used across all breathing UIs.
///
/// Based on the 4-7-8 breathing technique (Dr. Andrew Weil):
/// - Inhale: 4 seconds
/// - Hold: 7 seconds
/// - Exhale: 8 seconds
/// - Total cycle: 19 seconds
library;

class BreathTiming {
  BreathTiming._();

  /// Inhale duration in seconds
  static const int inhaleSeconds = 4;

  /// Hold breath duration in seconds
  static const int holdSeconds = 7;

  /// Exhale duration in seconds
  static const int exhaleSeconds = 8;

  /// Total breathing cycle duration in seconds
  static const int cycleSeconds = inhaleSeconds + holdSeconds + exhaleSeconds; // 19

  /// SOS session total duration in seconds (3 minutes)
  static const int sosSessionDuration = 180;

  /// Urges typically subside within this window (minutes)
  static const int urgesSubsideMinutes = 5;
}
