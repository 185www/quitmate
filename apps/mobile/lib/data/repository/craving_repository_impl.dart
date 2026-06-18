import '../../domain/entity/user.dart';
import '../database/app_database.dart';

class CravingRepository {
  final AppDatabase _database;
  CravingRepository(this._database);

  Future<int> logCraving(int userId, int intensity, {String? trigger, String? context, String? copingUsed, bool resolved = false}) async {
    return _database.insertCravingLog({
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'intensity': intensity,
      'trigger': trigger,
      'context': context,
      'coping_used': copingUsed,
      'resolved': resolved ? 1 : 0,
    });
  }

  Future<int> getCravingCount(int userId, {DateTime? since}) async {
    final logs = await _database.getCravingLogsForUser(userId);
    if (since != null) {
      logs.removeWhere((l) => DateTime.parse(l['timestamp'] as String).isBefore(since));
    }
    return logs.length;
  }

  Future<double> getAverageIntensity(int userId, {DateTime? since}) async {
    final logs = await _database.getCravingLogsForUser(userId);
    if (since != null) logs.removeWhere((l) => DateTime.parse(l['timestamp'] as String).isBefore(since));
    if (logs.isEmpty) return 0;
    final total = logs.fold(0, (sum, l) => sum + (l['intensity'] as int));
    return total / logs.length;
  }

  /// Most common craving triggers
  Future<List<MapEntry<String, int>>> getTopTriggers(int userId, {int limit = 5}) async {
    final logs = await _database.getCravingLogsForUser(userId);
    final counts = <String, int>{};
    for (final l in logs) {
      final t = l['trigger'] as String?;
      if (t != null && t.isNotEmpty) counts[t] = (counts[t] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }
}
