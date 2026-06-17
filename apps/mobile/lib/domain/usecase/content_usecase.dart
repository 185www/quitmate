import '../entity/content.dart';
import '../../data/repository/content_repository_impl.dart';

class ContentUseCase {
  final ContentRepositoryImpl _repository;
  ContentUseCase(this._repository);

  Future<List<Course>> getCourses() => _repository.getCourses();
  Future<Course?> getCourse(String courseId) => _repository.getCourse(courseId);
  Future<List<AssessmentQuestion>> getAssessmentQuestions(String type) => _repository.getAssessmentQuestions(type);
  Future<List<UrgeAlternative>> getUrgeAlternatives() => _repository.getUrgeAlternatives();
  Future<List<RelapseTemplate>> getRelapseTemplates() => _repository.getRelapseTemplates();
  Future<List<LifestyleRecommendation>> getLifestyleRecommendations() => _repository.getLifestyleRecommendations();
}