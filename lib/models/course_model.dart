// lib/models/course_model.dart

enum CourseLevel {
  beginner,
  junior,
  intermediate,
  advanced;

  String get label => switch (this) {
        CourseLevel.beginner => 'Débutant',
        CourseLevel.junior => 'Junior',
        CourseLevel.intermediate => 'Intermédiaire',
        CourseLevel.advanced => 'Avancé',
      };

  String get emoji => switch (this) {
        CourseLevel.beginner => '🌱',
        CourseLevel.junior => '🌿',
        CourseLevel.intermediate => '🌳',
        CourseLevel.advanced => '🏆',
      };

  String get description => switch (this) {
        CourseLevel.beginner => 'Aucune expérience requise',
        CourseLevel.junior => 'Quelques mois de pratique',
        CourseLevel.intermediate => '1–2 ans de pratique',
        CourseLevel.advanced => '3+ ans de pratique',
      };
}

class Course {
  final String id;
  final String instrumentId;
  final CourseLevel level;
  final String title;
  final String description;
  final String emoji;
  final List<CourseSection> sections;

  const Course({
    required this.id,
    required this.instrumentId,
    required this.level,
    required this.title,
    required this.description,
    required this.emoji,
    required this.sections,
  });

  int get sectionCount => sections.length;
}

class CourseSection {
  final String id;
  final int number;
  final String title;
  final String content;
  final List<String> keyPoints;
  final String? videoUrl;
  final String? videoTitle;
  final List<String> exercises;
  final String aiExercisePrompt;

  const CourseSection({
    required this.id,
    required this.number,
    required this.title,
    required this.content,
    required this.keyPoints,
    this.videoUrl,
    this.videoTitle,
    required this.exercises,
    required this.aiExercisePrompt,
  });
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

enum SectionStatus { completed, skipped, notStarted }
