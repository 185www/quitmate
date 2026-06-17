import '../../domain/entity/content.dart';
import '../../domain/repository/content_repository.dart';
import '../../core/content/content_manager.dart';
import '../../data/source/content_loader.dart';

class ContentRepositoryImpl implements ContentRepository {
  final ContentLoader _contentLoader;

  ContentRepositoryImpl(this._contentLoader);

  @override
  Future<List<Course>> getCourses() async {
    final courseIds = await _contentLoader.loadCoursesManifest();
    final courses = <Course>[];

    for (final id in courseIds) {
      final course = await getCourse(id);
      if (course != null) courses.add(course);
    }

    return courses;
  }

  @override
  Future<Course?> getCourse(String courseId) async {
    final data = await _contentLoader.loadCourseContent(courseId);
    if (data.isEmpty) return null;

    final daysData = data['days'] as List<dynamic>? ?? [];
    final days = daysData
        .map((d) => CourseDay(
              day: d['day'] ?? 0,
              title: d['title'] ?? '',
              audioAsset: d['audio'],
              markdownContent: d['markdown'],
              imageAssets: d['images'] != null
                  ? List<String>.from(d['images'])
                  : null,
            ))
        .toList();

    return Course(
      id: courseId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      stage: data['stage'] ?? 0,
      days: days,
    );
  }

  @override
  Future<List<AssessmentQuestion>> getAssessmentQuestions(String assessmentId) async {
    final questionsData = await _contentLoader.loadAssessmentQuestions(assessmentId);
    return questionsData
        .map((q) => AssessmentQuestion(
              id: q['id'] ?? '',
              text: q['text'] ?? '',
              options: (q['options'] as List<dynamic>? ?? [])
                  .map((o) => AssessmentOption(
                        text: o['text'] ?? '',
                        score: o['score'] ?? 0,
                      ))
                  .toList(),
            ))
        .toList();
  }

  @override
  Future<List<UrgeAlternative>> getUrgeAlternatives() async {
    final alternativesData = await _contentLoader.loadUrgeAlternatives();
    return alternativesData
        .map((a) => UrgeAlternative(
              id: a['id'] ?? '',
              title: a['title'] ?? '',
              description: a['description'] ?? '',
              category: a['category'] ?? '',
            ))
        .toList();
  }

  @override
  Future<List<RelapseTemplate>> getRelapseTemplates() async {
    final templatesData = await _contentLoader.loadRelapseTemplates();
    return templatesData
        .map((t) => RelapseTemplate(
              id: t['id'] ?? '',
              situation: t['situation'] ?? '',
              trigger: t['trigger'] ?? '',
              copingPlan: t['coping_plan'] ?? '',
            ))
        .toList();
  }

  @override
  Future<List<LifestyleRecommendation>> getLifestyleRecommendations() async {
    final recsData = await _contentLoader.loadLifestyleRecommendations();
    return recsData
        .map((r) => LifestyleRecommendation(
              id: r['id'] ?? '',
              title: r['title'] ?? '',
              description: r['description'] ?? '',
              category: r['category'] ?? '',
              duration: r['duration'] ?? 0,
            ))
        .toList();
  }

  @override
  Future<List<SkillContent>> getSkillContents() async {
    return [];
  }

  @override
  Future<SkillContent?> getSkillContent(String skillId) async {
    final data = await _contentLoader.loadSkillContent(skillId);
    if (data.isEmpty) return null;
    return SkillContent(
      id: skillId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
    );
  }
}