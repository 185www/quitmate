// ═══════════════════════════════════════════════════════════════════════════════
// P1.2.4 — Health Platform Data Integration
//
// Abstract interface + self-reported implementation.
// Zero Google dependencies — compatible with all Chinese ROMs.
// Future: swap in Huawei Health Kit / Health Connect implementations
// behind this same interface.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/database/app_database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HealthSnapshot — immutable data model
// ─────────────────────────────────────────────────────────────────────────────

/// A point-in-time snapshot of the user's health metrics.
///
/// All fields are nullable — the self-reported flow may only populate a
/// subset.  Platform integrations (Huawei Health Kit, etc.) can fill more.
class HealthSnapshot {
  final DateTime timestamp;
  final double? heartRateBpm;
  final double? sleepHours;
  final int? stressLevel; // 1-10
  final int? stepsCount;
  final String source; // 'self_report', 'huawei', 'health_connect', etc.

  const HealthSnapshot({
    required this.timestamp,
    this.heartRateBpm,
    this.sleepHours,
    this.stressLevel,
    this.stepsCount,
    this.source = 'self_report',
  });

  /// Convenience: is the stress level high? (≥ 7)
  bool get isHighStress => (stressLevel ?? 0) >= 7;

  /// Convenience: is sleep poor? (< 5 hours)
  bool get isPoorSleep => (sleepHours ?? double.infinity) < 5;

  /// Convenience: is the snapshot considered "healthy"?
  bool get isGoodState =>
      (stressLevel ?? 10) <= 4 &&
      (sleepHours ?? 0) >= 6 &&
      !isHighStress &&
      !isPoorSleep;

  Map<String, dynamic> toDbMap(int userId) => {
        'user_id': userId,
        'timestamp': timestamp.toIso8601String(),
        'heart_rate': heartRateBpm,
        'sleep_hours': sleepHours,
        'stress_level': stressLevel,
        'steps_count': stepsCount,
        'source': source,
      };

  factory HealthSnapshot.fromDbMap(Map<String, dynamic> row) =>
      HealthSnapshot(
        timestamp: DateTime.parse(row['timestamp'] as String),
        heartRateBpm: row['heart_rate'] as double?,
        sleepHours: row['sleep_hours'] as double?,
        stressLevel: row['stress_level'] as int?,
        stepsCount: row['steps_count'] as int?,
        source: (row['source'] as String?) ?? 'self_report',
      );

  @override
  String toString() =>
      'HealthSnapshot(sleep=$sleepHours h, stress=$stressLevel, '
      'hr=$heartRateBpm, steps=$stepsCount, src=$source)';
}

// ─────────────────────────────────────────────────────────────────────────────
// HealthDataService — abstract interface
// ─────────────────────────────────────────────────────────────────────────────

/// Abstract contract for health data access.
///
/// The default [SelfReportHealthService] works everywhere.
/// Future implementations can wrap Huawei Health Kit, Android Health
/// Connect, or Apple HealthKit behind this same interface.
abstract class HealthDataService {
  /// Stream of health snapshots (emits on each new recording).
  Stream<HealthSnapshot?> get healthStream;

  /// Get the most recent health snapshot, or `null` if none exists.
  Future<HealthSnapshot?> getLatestSnapshot();

  /// Record a self-reported (or platform-sourced) health data point.
  Future<void> recordSelfReport(HealthSnapshot snapshot);

  /// Whether a platform health SDK is available on this device.
  bool get hasPlatformIntegration;

  /// Try to initialise a platform health SDK.
  ///
  /// Returns `true` if a platform SDK was successfully connected,
  /// `false` if unavailable (graceful fallback to self-report).
  Future<bool> initializePlatform();
}

// ─────────────────────────────────────────────────────────────────────────────
// SelfReportHealthService — default implementation (SQLite, zero deps)
// ─────────────────────────────────────────────────────────────────────────────

/// Self-reported health data stored locally in SQLite.
///
/// This is the default implementation that works on **all** devices —
/// Huawei, Xiaomi, Honor, OPPO, vivo — with zero platform SDK dependency.
class SelfReportHealthService implements HealthDataService {
  final AppDatabase _db;
  final _controller = StreamController<HealthSnapshot?>.broadcast();

  SelfReportHealthService(this._db);

  // ── Stream ────────────────────────────────────────────────────────────

  @override
  Stream<HealthSnapshot?> get healthStream => _controller.stream;

  // ── CRUD ──────────────────────────────────────────────────────────────

  @override
  Future<HealthSnapshot?> getLatestSnapshot() async {
    final userId = await _currentUserId();
    if (userId == null) return null;

    final db = await _db.database;
    final rows = await db.query(
      'health_data',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return HealthSnapshot.fromDbMap(rows.first);
  }

  @override
  Future<void> recordSelfReport(HealthSnapshot snapshot) async {
    final userId = await _currentUserId();
    if (userId == null) {
      debugPrint('SelfReportHealthService: no user profile — skip');
      return;
    }

    final db = await _db.database;
    await db.insert('health_data', snapshot.toDbMap(userId));
    _controller.add(snapshot);
  }

  // ── Platform integration stubs ────────────────────────────────────────

  @override
  bool get hasPlatformIntegration => false;

  @override
  Future<bool> initializePlatform() async => false;

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Resolve the current user id from `user_profile`.
  Future<int?> _currentUserId() async {
    final profile = await _db.getFirstUserProfile();
    return profile?['id'] as int?;
  }

  /// Clean up the stream controller.
  void dispose() {
    _controller.close();
  }
}