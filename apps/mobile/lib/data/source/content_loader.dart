import 'dart:convert';
import 'package:flutter/services.dart';

class ContentLoader {
  Future<List<String>> loadCoursesManifest() async {
    try {
      final manifest = await rootBundle.loadString('assets/content/courses/manifest.json');
      final Map<String, dynamic> data = jsonDecode(manifest);
      return List<String>.from(data['courses'] ?? []);
    } catch (e) { return []; }
  }

  Future<Map<String, dynamic>> loadCourseContent(String courseId) async {
    try {
      final content = await rootBundle.loadString('assets/content/courses/$courseId/content.json');
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) { return {}; }
  }

  Future<List<Map<String, dynamic>>> loadAssessmentQuestions(String assessmentId) async {
    try {
      final content = await rootBundle.loadString('assets/content/assessments/$assessmentId.json');
      final Map<String, dynamic> data = jsonDecode(content);
      return List<Map<String, dynamic>>.from(data['questions'] ?? []);
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> loadUrgeAlternatives() async {
    try {
      final content = await rootBundle.loadString('assets/content/urge_toolkit/alternatives.json');
      final Map<String, dynamic> data = jsonDecode(content);
      return List<Map<String, dynamic>>.from(data['alternatives'] ?? []);
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> loadRelapseTemplates() async {
    try {
      final content = await rootBundle.loadString('assets/content/relapse_templates.json');
      final Map<String, dynamic> data = jsonDecode(content);
      return List<Map<String, dynamic>>.from(data['templates'] ?? []);
    } catch (e) { return []; }
  }

  Future<Map<String, dynamic>> loadSkillContent(String skillId) async {
    try {
      final content = await rootBundle.loadString('assets/content/skills/$skillId.json');
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) { return {}; }
  }

  Future<List<Map<String, dynamic>>> loadLifestyleRecommendations() async {
    try {
      final content = await rootBundle.loadString('assets/content/lifestyle/recommendations.json');
      final Map<String, dynamic> data = jsonDecode(content);
      return List<Map<String, dynamic>>.from(data['recommendations'] ?? []);
    } catch (e) { return []; }
  }
}