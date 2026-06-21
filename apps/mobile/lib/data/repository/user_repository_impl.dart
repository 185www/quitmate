import '../../domain/entity/user.dart';
import '../database/app_database.dart';
import '../../core/security/encryption_service.dart';

class UserRepository {
  final AppDatabase _database;
  final EncryptionService _encryptionService;
  UserRepository(this._database, this._encryptionService);

  Future<User?> getCurrentUser() async {
    final profile = await _database.getFirstUserProfile();
    if (profile == null) return null;
    return User(
      id: profile['id'] as int,
      targetType: TargetType.values.byName(profile['target_type'] as String),
      quitDate: profile['quit_date'] != null
          ? DateTime.parse(profile['quit_date'] as String)
          : null,
      stage: UserStage.values[profile['stage'] as int? ?? 0],
      fagerstromScore: profile['fagerstrom_score'] as int?,
      auditScore: profile['audit_score'] as int?,
      dailyConsumption: profile['daily_consumption'] != null
          ? (profile['daily_consumption'] as num).toDouble()
          : null,
      yearsOfUse: profile['years_of_use'] as int?,
      age: profile['age'] as int?,
      dailyCostAmount: profile['daily_cost_amount'] != null
          ? (profile['daily_cost_amount'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(profile['created_at'] as String),
      updatedAt: DateTime.parse(profile['updated_at'] as String),
    );
  }

  Future<User> createUser(
      {required TargetType targetType,
      DateTime? quitDate,
      int? fagerstromScore,
      int? auditScore,
      double? dailyConsumption,
      int? yearsOfUse,
      int? age,
      double? dailyCostAmount}) async {
    final now = DateTime.now();
    final id = await _database.createUserProfile({
      'target_type': targetType.name,
      'quit_date': quitDate?.toIso8601String(),
      'stage': UserStage.preContemplation.index,
      'fagerstrom_score': fagerstromScore,
      'audit_score': auditScore,
      'daily_consumption': dailyConsumption,
      'years_of_use': yearsOfUse,
      'age': age,
      'daily_cost_amount': dailyCostAmount,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    return User(
        id: id,
        targetType: targetType,
        quitDate: quitDate,
        stage: UserStage.preContemplation,
        fagerstromScore: fagerstromScore,
        auditScore: auditScore,
        dailyConsumption: dailyConsumption,
        yearsOfUse: yearsOfUse,
        age: age,
        dailyCostAmount: dailyCostAmount,
        createdAt: now,
        updatedAt: now);
  }

  Future<User> updateUser(
      {required int id,
      TargetType? targetType,
      DateTime? quitDate,
      UserStage? stage,
      int? fagerstromScore,
      int? auditScore,
      double? dailyConsumption,
      int? yearsOfUse,
      int? age,
      double? dailyCostAmount}) async {
    final values = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String()
    };
    if (targetType != null) values['target_type'] = targetType.name;
    if (quitDate != null) values['quit_date'] = quitDate.toIso8601String();
    if (stage != null) values['stage'] = stage.index;
    if (fagerstromScore != null) values['fagerstrom_score'] = fagerstromScore;
    if (auditScore != null) values['audit_score'] = auditScore;
    if (dailyConsumption != null)
      values['daily_consumption'] = dailyConsumption;
    if (yearsOfUse != null) values['years_of_use'] = yearsOfUse;
    if (age != null) values['age'] = age;
    if (dailyCostAmount != null) values['daily_cost_amount'] = dailyCostAmount;
    await _database.updateUserProfile(id, values);
    final user = await getCurrentUser();
    return user!;
  }

  Future<void> savePreferences(Map<String, dynamic> preferences) async {
    final encrypted = await _encryptionService.encryptJson(preferences);
    final user = await getCurrentUser();
    if (user != null) {
      await _database.updateUserProfile(
          user.id, {'preferences_encrypted': encrypted['encrypted']});
    }
  }

  Future<Map<String, dynamic>> getPreferences() async {
    final profile = await _database.getFirstUserProfile();
    if (profile == null || profile['preferences_encrypted'] == null) return {};
    return await _encryptionService
        .decryptJson({'encrypted': profile['preferences_encrypted'] as String});
  }
}
