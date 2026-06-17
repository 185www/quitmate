import '../entity/user.dart';

abstract class UserRepository {
  Future<User?> getCurrentUser();
  Future<User> createUser({required TargetType targetType, DateTime? quitDate});
  Future<User> updateUser({required int id, TargetType? targetType, DateTime? quitDate, UserStage? stage});
  Future<void> savePreferences(Map<String, dynamic> preferences);
  Future<Map<String, dynamic>> getPreferences();
}