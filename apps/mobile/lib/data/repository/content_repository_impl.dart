import 'dart:convert';
import '../../domain/entity/content.dart';
import '../../data/source/content_loader.dart';

class ContentRepositoryImpl {
  final ContentLoader _contentLoader;
  ContentRepositoryImpl(this._contentLoader);

  Future<List<Course>> getCourses() async {
    final ids = await _contentLoader.loadCoursesManifest();
    final courses = <Course>[];
    for (final id in ids) {
      final c = await getCourse(id);
      if (c != null) courses.add(c);
    }
    return courses;
  }

  Future<Course?> getCourse(String courseId) async {
    final data = await _contentLoader.loadCourseContent(courseId);
    if (data.isEmpty) return null;
    final days = (data['days'] as List<dynamic>? ?? []).map((d) => CourseDay(
      day: d['day'] ?? 0, title: d['title'] ?? '', audioAsset: d['audio'], markdownContent: d['markdown'], imageAssets: d['images'] != null ? List<String>.from(d['images']) : null,
    )).toList();
    return Course(id: courseId, title: data['title'] ?? '', description: data['description'] ?? '', stage: data['stage'] ?? 0, days: days);
  }

  Future<List<AssessmentQuestion>> getAssessmentQuestions(String assessmentId) async {
    final qs = await _contentLoader.loadAssessmentQuestions(assessmentId);
    return qs.map((q) => AssessmentQuestion(
      id: q['id'] ?? '', text: q['text'] ?? '',
      options: (q['options'] as List<dynamic>? ?? []).map((o) => AssessmentOption(text: o['text'] ?? '', score: o['score'] ?? 0)).toList(),
    )).toList();
  }

  Future<List<UrgeAlternative>> getUrgeAlternatives() async {
    final data = await _contentLoader.loadUrgeAlternatives();
    return data.map((a) => UrgeAlternative(id: a['id'] ?? '', title: a['title'] ?? '', description: a['description'] ?? '', category: a['category'] ?? '')).toList();
  }

  Future<List<RelapseTemplate>> getRelapseTemplates() async {
    final data = await _contentLoader.loadRelapseTemplates();
    return data.map((t) => RelapseTemplate(id: t['id'] ?? '', situation: t['situation'] ?? '', trigger: t['trigger'] ?? '', copingPlan: t['coping_plan'] ?? '')).toList();
  }

  Future<List<LifestyleRecommendation>> getLifestyleRecommendations() async {
    final data = await _contentLoader.loadLifestyleRecommendations();
    return data.map((r) => LifestyleRecommendation(id: r['id'] ?? '', title: r['title'] ?? '', description: r['description'] ?? '', category: r['category'] ?? '', duration: r['duration'] ?? 0)).toList();
  }
}