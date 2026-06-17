import '../entity/content.dart';

abstract class ContentRepository {
  Future<List<Course>> getCourses();
  Future<Course?> getCourse(String courseId);
  Future<List<AssessmentQuestion>> getAssessmentQuestions(String assessmentId);
  Future<List<UrgeAlternative>> getUrgeAlternatives();
  Future<List<RelapseTemplate>> getRelapseTemplates();
  Future<List<LifestyleRecommendation>> getLifestyleRecommendations();
  Future<List<SkillContent>> getSkillContents();
  Future<SkillContent?> getSkillContent(String skillId);
}