import '../../data/repository/craving_repository_impl.dart';
import '../../data/repository/user_repository_impl.dart';

class CravingUseCase {
  final CravingRepository _repository;
  final UserRepository _userRepository;
  CravingUseCase(this._repository, this._userRepository);

  Future<int> logCraving(int intensity,
      {String? trigger,
      String? context,
      String? copingUsed,
      bool resolved = false,
      String? location,
      String? socialContext,
      String? activity}) async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) throw StateError('No user found');
    return _repository.logCraving(user.id, intensity,
        trigger: trigger,
        context: context,
        copingUsed: copingUsed,
        resolved: resolved,
        location: location,
        socialContext: socialContext,
        activity: activity);
  }

  Future<int> getCravingCount({DateTime? since}) async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) return 0;
    return _repository.getCravingCount(user.id, since: since);
  }

  Future<double> getAverageIntensity({DateTime? since}) async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) return 0;
    return _repository.getAverageIntensity(user.id, since: since);
  }

  Future<List<MapEntry<String, int>>> getTopTriggers({int limit = 5}) async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) return [];
    return _repository.getTopTriggers(user.id, limit: limit);
  }

  Future<Map<String, List<MapEntry<String, int>>>> getSceneAnalysis() async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) return {};
    return _repository.getSceneAnalysis(user.id);
  }

  Future<List<Map<String, dynamic>>> getAllRawLogs() async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) return [];
    return _repository.getAllRawLogs(user.id);
  }
}
