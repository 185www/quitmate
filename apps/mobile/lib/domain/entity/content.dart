class Course {
  final String id;
  final String title;
  final String description;
  final int stage;
  final List<CourseDay> days;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.stage,
    required this.days,
  });
}

class CourseDay {
  final int day;
  final String title;
  final String? audioAsset;
  final String? markdownContent;
  final List<String>? imageAssets;

  const CourseDay({
    required this.day,
    required this.title,
    this.audioAsset,
    this.markdownContent,
    this.imageAssets,
  });
}

class AssessmentQuestion {
  final String id;
  final String text;
  final List<AssessmentOption> options;

  const AssessmentQuestion({
    required this.id,
    required this.text,
    required this.options,
  });
}

class AssessmentOption {
  final String text;
  final int score;

  const AssessmentOption({
    required this.text,
    required this.score,
  });
}

class UrgeAlternative {
  final String id;
  final String title;
  final String description;
  final String category;

  const UrgeAlternative({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
  });
}

class RelapseTemplate {
  final String id;
  final String situation;
  final String trigger;
  final String copingPlan;

  const RelapseTemplate({
    required this.id,
    required this.situation,
    required this.trigger,
    required this.copingPlan,
  });
}

class LifestyleRecommendation {
  final String id;
  final String title;
  final String description;
  final String category;
  final int duration;

  const LifestyleRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
  });
}

class SkillContent {
  final String id;
  final String title;
  final String description;
  final String content;
  final String category;

  const SkillContent({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.category,
  });
}