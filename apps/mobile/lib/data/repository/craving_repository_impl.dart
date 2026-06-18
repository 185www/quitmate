import '../../domain/entity/user.dart';
import '../database/app_database.dart';

class CravingRepository {
  final AppDatabase _database;
  CravingRepository(this._database);

  Future<int> logCraving(int userId, int intensity,
      {String? trigger,
      String? context,
      String? copingUsed,
      bool resolved = false,
      String? location,
      String? socialContext,
      String? activity}) async {
    return _database.insertCravingLog({
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'intensity': intensity,
      'trigger': trigger,
      'context': context,
      'coping_used': copingUsed,
      'resolved': resolved ? 1 : 0,
      'location': location,
      'social_context': socialContext,
      'activity': activity,
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

  Future<Map<String, List<MapEntry<String, int>>>> getSceneAnalysis(int userId) async {
    final logs = await _database.getCravingLogsForUser(userId, limit: 999);
    final locations = <String, int>{};
    final socials = <String, int>{};
    final activities = <String, int>{};

    for (final l in logs) {
      final loc = l['location'] as String?;
      if (loc != null && loc.isNotEmpty) locations[loc] = (locations[loc] ?? 0) + 1;
      final soc = l['social_context'] as String?;
      if (soc != null && soc.isNotEmpty) socials[soc] = (socials[soc] ?? 0) + 1;
      final act = l['activity'] as String?;
      if (act != null && act.isNotEmpty) activities[act] = (activities[act] ?? 0) + 1;
    }

    MapEntry<String, int> sort(MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value);

    return {
      'locations': locations.entries.toList()..sort(sort),
      'socials': socials.entries.toList()..sort(sort),
      'activities': activities.entries.toList()..sort(sort),
    };
  }

  Future<List<Map<String, dynamic>>> getAllRawLogs(int userId) async {
    return _database.getCravingLogsForUser(userId, limit: 999);
  }
}
