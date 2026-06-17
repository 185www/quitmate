import '../entity/user.dart';
import '../../data/repository/user_repository_impl.dart';

class UserUseCase {
  final UserRepository _repository;
  UserUseCase(this._repository);

  Future<User?> getCurrentUser() => _repository.getCurrentUser();
  Future<User> createUser({required TargetType targetType, DateTime? quitDate}) => _repository.createUser(targetType: targetType, quitDate: quitDate);
  Future<User> setQuitDate(DateTime quitDate) async {
    final user = await _repository.getCurrentUser();
    if (user == null) throw StateError('No user found');
    return _repository.updateUser(id: user.id, quitDate: quitDate, stage: UserStage.preparation);
  }
  Future<User> advanceStage() async {
    final user = await _repository.getCurrentUser();
    if (user == null) throw StateError('No user found');
    final nextStage = _getNextStage(user.stage);
    return _repository.updateUser(id: user.id, stage: nextStage);
  }
  UserStage _getNextStage(UserStage current) {
    switch (current) {
      case UserStage.preContemplation: return UserStage.contemplation;
      case UserStage.contemplation: return UserStage.preparation;
      case UserStage.preparation: return UserStage.action;
      case UserStage.action: return UserStage.maintenance;
      case UserStage.maintenance: return UserStage.maintenance;
    }
  }
  Future<void> savePreferences(Map<String, dynamic> preferences) => _repository.savePreferences(preferences);
  Future<Map<String, dynamic>> getPreferences() => _repository.getPreferences();
}