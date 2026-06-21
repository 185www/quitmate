/// Tracks LLM API usage for cost monitoring.
/// All values are in-memory; persist to SQLite via AppDatabase if needed.
class LlmUsageTracker {
  static final LlmUsageTracker instance = LlmUsageTracker._();
  LlmUsageTracker._();

  int _totalInputTokens = 0;
  int _totalOutputTokens = 0;
  int _totalCalls = 0;
  DateTime _trackingStart = DateTime.now();

  int get totalInputTokens => _totalInputTokens;
  int get totalOutputTokens => _totalOutputTokens;
  int get totalCalls => _totalCalls;
  DateTime get trackingStart => _trackingStart;

  void record({required int inputTokens, required int outputTokens}) {
    _totalInputTokens += inputTokens;
    _totalOutputTokens += outputTokens;
    _totalCalls++;
  }

  /// Estimate monthly cost based on GPT-4o Mini pricing
  double estimateMonthlyCost() {
    final daysActive = DateTime.now().difference(_trackingStart).inDays.clamp(1, 365);
    final dailyInput = _totalInputTokens / daysActive;
    final dailyOutput = _totalOutputTokens / daysActive;

    // GPT-4o Mini: input $0.15/1M, output $0.60/1M
    final monthlyInputCost = (dailyInput * 30) * 0.15 / 1000000;
    final monthlyOutputCost = (dailyOutput * 30) * 0.60 / 1000000;
    return monthlyInputCost + monthlyOutputCost;
  }

  void reset() {
    _totalInputTokens = 0;
    _totalOutputTokens = 0;
    _totalCalls = 0;
    _trackingStart = DateTime.now();
  }
}