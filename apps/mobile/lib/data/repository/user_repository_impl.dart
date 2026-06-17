import '../../domain/entity/user.dart';
import '../../domain/repository/user_repository.dart';
import '../database/app_database.dart';
import '../../core/security/encryption_service.dart';

class UserRepositoryImpl implements UserRepository {
  final AppDatabase _database;
  final EncryptionService _encryptionService;
  UserRepositoryImpl(this._database, this._encryptionService);

  @override
  Future<User?> getCurrentUser() async {
    final profile = await _database.getFirstUserProfile();
    if (profile == null) return null;
    return User(id: profile.id, targetType: TargetType.values.byName(profile.targetType), quitDate: profile.quitDate, stage: UserStage.values[profile.stage], createdAt: profile.createdAt, updatedAt: profile.updatedAt);
  }

  @override
  Future<User> createUser({required TargetType targetType, DateTime? quitDate}) async {
    final now = DateTime.now();
    final id = await _database.createUserProfile(UserProfileCompanion.insert(targetType: targetType.name, quitDate: quitDate, createdAt: now, updatedAt: now));
    return User(id: id, targetType: targetType, quitDate: quitDate, stage: UserStage.preContemplation, createdAt: now, updatedAt: now);
  }

  @override
  Future<User> updateUser({required int id, TargetType? targetType, DateTime? quitDate, UserStage? stage}) async {
    final now = DateTime.now();
    await _database.updateUserProfile(UserProfileCompanion(id: Value(id), targetType: targetType != null ? Value(targetType.name) : const Value.absent(), quitDate: Value(quitDate), stage: stage != null ? Value(stage.index) : const Value.absent(), updatedAt: Value(now)));
    final profile = await _database.getFirstUserProfile();
    return User(id: profile!.id, targetType: TargetType.values.byName(profile.targetType), quitDate: profile.quitDate, stage: UserStage.values[profile.stage], createdAt: profile.createdAt, updatedAt: profile.updatedAt);
  }

  @override
  Future<void> savePreferences(Map<String, dynamic> preferences) async {
    final encrypted = await _encryptionService.encryptJson(preferences);
    final user = await getCurrentUser();
    if (user != null) {
      await _database.updateUserProfile(UserProfileCompanion(id: Value(user.id), preferencesEncrypted: Value(encrypted['encrypted'])));
    }
  }

  @override
  Future<Map<String, dynamic>> getPreferences() async {
    final profile = await _database.getFirstUserProfile();
    if (profile?.preferencesEncrypted == null) return {};
    return await _encryptionService.decryptJson({'encrypted': profile!.preferencesEncrypted});
  }
}