import '../entity/content.dart';
import '../repository/content_repository.dart';

class ContentUseCase {
  final ContentRepository _contentRepository;

  ContentUseCase(this._contentRepository);

  Future<List<Course>> getCourses() {
    return _contentRepository.getCourses();
  }

  Future<Course?> getCourse(String courseId) {
    return _contentRepository.getCourse(courseId);
  }

  Future<List<AssessmentQuestion>> getAssessmentQuestions(String type) {
    return _contentRepository.getAssessmentQuestions(type);
  }

  Future<List<UrgeAlternative>> getUrgeAlternatives() {
    return _contentRepository.getUrgeAlternatives();
  }

  Future<List<RelapseTemplate>> getRelapseTemplates() {
    return _contentRepository.getRelapseTemplates();
  }

  Future<List<LifestyleRecommendation>> getLifestyleRecommendations() {
    return _contentRepository.getLifestyleRecommendations();
  }

  Future<List<SkillContent>> getSkillContents() {
    return _contentRepository.getSkillContents();
  }

  Future<SkillContent?> getSkillContent(String skillId) {
    return _contentRepository.getSkillContent(skillId);
  }
}