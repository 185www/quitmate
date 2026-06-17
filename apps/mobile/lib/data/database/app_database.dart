import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class UserProfile extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetType => text()();
  DateTimeColumn get quitDate => dateTime().nullable()();
  IntColumn get stage => integer().withDefault(const Constant(0))();
  TextColumn get preferencesEncrypted => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class DailyLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(UserProfile, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get urgeLevel => integer().nullable()();
  TextColumn get triggers => text().nullable()();
  TextColumn get coping => text().nullable()();
  BoolColumn get relapsed => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
}

class Badge extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get iconAsset => text()();
  DateTimeColumn get earnedAt => dateTime().nullable()();
}

class RelapsePlan extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(UserProfile, #id)();
  TextColumn get situation => text()();
  TextColumn get trigger => text().nullable()();
  TextColumn get copingPlan => text()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))();
}

class NotificationSchedule extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get notificationId => text().unique()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  IntColumn get type => integer()();
  TextColumn get payload => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  TextColumn get cronExpr => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}

@DriftDatabase(tables: [UserProfile, DailyLog, Badge, RelapsePlan, NotificationSchedule])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedBadges();
        },
      );

  Future<void> _seedBadges() async {
    await batch((batch) {
      batch.insertAll(badge, [
        BadgeCompanion.insert(code: 'day_1', name: '第一天', description: '成功坚持1天', iconAsset: 'assets/brand/badges/day1.svg'),
        BadgeCompanion.insert(code: 'day_7', name: '一周达人', description: '成功坚持7天', iconAsset: 'assets/brand/badges/day7.svg'),
        BadgeCompanion.insert(code: 'day_30', name: '月度冠军', description: '成功坚持30天', iconAsset: 'assets/brand/badges/day30.svg'),
        BadgeCompanion.insert(code: 'day_90', name: '季度英雄', description: '成功坚持90天', iconAsset: 'assets/brand/badges/day90.svg'),
        BadgeCompanion.insert(code: 'day_365', name: '年度传奇', description: '成功坚持一年', iconAsset: 'assets/brand/badges/day365.svg'),
      ]);
    });
  }

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'quitmate.sqlite'));
      return NativeDatabase(file);
    });
  }

  Future<int> createUserProfile(UserProfileCompanion profile) => into(userProfile).insert(profile);
  Future<UserProfileData?> getFirstUserProfile() => (select(userProfile)..limit(1)).getSingleOrNull();
  Future<bool> updateUserProfile(UserProfileCompanion profile) => update(userProfile).write(profile).then((rows) => rows > 0);

  Future<int> insertDailyLog(DailyLogCompanion log) => into(dailyLog).insert(log);
  Future<List<DailyLogData>> getDailyLogsForUser(int userId, {int limit = 30}) =>
      (select(dailyLog)..where((t) => t.userId.equals(userId))..orderBy([(t) => OrderingTerm.desc(t.date)])..limit(limit)).get();

  Future<DailyLogData?> getTodayLog(int userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return (select(dailyLog)..where((t) => t.userId.equals(userId) & t.date.isBiggerOrEqualValue(startOfDay) & t.date.isSmallerOrEqualValue(endOfDay))..limit(1)).getSingleOrNull();
  }

  Future<List<BadgeData>> getAllBadges() => select(badge).get();
  Future<List<BadgeData>> getEarnedBadges() => (select(badge)..where((t) => t.earnedAt.isNotNull())).get();
  Future<bool> earnBadge(String code) => (update(badge)..where((t) => t.code.equals(code))).write(BadgeCompanion(earnedAt: Value(DateTime.now()))).then((rows) => rows > 0);

  Future<int> insertRelapsePlan(RelapsePlanCompanion plan) => into(relapsePlan).insert(plan);
  Future<List<RelapsePlanData>> getRelapsePlansForUser(int userId) =>
      (select(relapsePlan)..where((t) => t.userId.equals(userId))..orderBy([(t) => OrderingTerm.desc(t.priority)])).get();
  Future<List<RelapsePlanData>> getTemplatePlans() => (select(relapsePlan)..where((t) => t.isTemplate.equals(true))).get();
  Future<bool> deleteRelapsePlan(int id) => (delete(relapsePlan)..where((t) => t.id.equals(id))).go().then((rows) => rows > 0);

  Future<int> insertNotificationSchedule(NotificationScheduleCompanion schedule) => into(notificationSchedule).insert(schedule);
  Future<List<NotificationScheduleData>> getEnabledNotifications() => (select(notificationSchedule)..where((t) => t.enabled.equals(true))).get();
  Future<bool> toggleNotification(String notificationId, bool enabled) =>
      (update(notificationSchedule)..where((t) => t.notificationId.equals(notificationId))).write(NotificationScheduleCompanion(enabled: Value(enabled))).then((rows) => rows > 0);
}