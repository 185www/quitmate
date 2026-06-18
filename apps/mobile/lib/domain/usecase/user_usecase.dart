import '../entity/user.dart';
import '../../data/repository/user_repository_impl.dart';

class UserUseCase {
  final UserRepository _repository;
  UserUseCase(this._repository);

  Future<User?> getCurrentUser() => _repository.getCurrentUser();

  Future<User> createUser({
    required TargetType targetType,
    DateTime? quitDate,
    int? fagerstromScore,
    int? auditScore,
    double? dailyConsumption,
    int? yearsOfUse,
  }) => _repository.createUser(
    targetType: targetType,
    quitDate: quitDate,
    fagerstromScore: fagerstromScore,
    auditScore: auditScore,
    dailyConsumption: dailyConsumption,
    yearsOfUse: yearsOfUse,
  );

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

  /// Automatically advance stage based on days since quit.
  /// Returns the (possibly updated) user, or null if no user exists.
  Future<User?> checkAndAdvanceStage() async {
    final user = await _repository.getCurrentUser();
    if (user == null) return null;
    if (!user.hasQuitDate) return user;

    final days = user.daysSinceQuit;
    UserStage targetStage;

    if (days >= 30) {
      targetStage = UserStage.maintenance;
    } else if (user.hasQuitDate) {
      targetStage = UserStage.action;
    } else {
      return user;
    }

    if (user.stage.index < targetStage.index) {
      return _repository.updateUser(id: user.id, stage: targetStage);
    }
    return user;
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

  Future<User> updateAssessment({
    int? fagerstromScore,
    int? auditScore,
    double? dailyConsumption,
    int? yearsOfUse,
    required TargetType targetType,
  }) async {
    final user = await _repository.getCurrentUser();
    final id = user?.id;
    if (id == null) {
      final now = DateTime.now();
      final newId = await _repository.createUser(
        targetType: targetType,
        fagerstromScore: fagerstromScore,
        auditScore: auditScore,
        dailyConsumption: dailyConsumption,
        yearsOfUse: yearsOfUse,
      );
      return newId;
    }
    return _repository.updateUser(
      id: id,
      fagerstromScore: fagerstromScore,
      auditScore: auditScore,
      dailyConsumption: dailyConsumption,
      yearsOfUse: yearsOfUse,
    );
  }

  Future<void> savePreferences(Map<String, dynamic> preferences) => _repository.savePreferences(preferences);
  Future<Map<String, dynamic>> getPreferences() => _repository.getPreferences();
}
