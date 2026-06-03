// lib/services/learning_intelligence_service.dart
//
// Central service for the Harmonie Continuous Learning System.
//
// ┌─────────────────────────────────────────────────────────┐
// │  FLOW                                                   │
// │  User action → trackSignal() → Supabase learning_signals│
// │    → SQL trigger updates user_learning_profiles         │
// │    → Next AI chat call fetches fn_get_user_ai_context() │
// │    → Richer, personalized AI response                   │
// └─────────────────────────────────────────────────────────┘

import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Signal types enum (mirrors SQL comment list) ─────────────────────────────

enum LearningSignalType {
  courseStarted,
  courseCompleted,
  sectionCompleted,
  quizPassed,
  quizFailed,
  quizAbandoned,
  analysisDone,
  playbackStarted,
  playbackCompleted,
  aiChatMessage,
  lessonRevisited,
  contentSkipped;

  String get value => switch (this) {
        LearningSignalType.courseStarted     => 'course_started',
        LearningSignalType.courseCompleted   => 'course_completed',
        LearningSignalType.sectionCompleted  => 'section_completed',
        LearningSignalType.quizPassed        => 'quiz_passed',
        LearningSignalType.quizFailed        => 'quiz_failed',
        LearningSignalType.quizAbandoned     => 'quiz_abandoned',
        LearningSignalType.analysisDone      => 'analysis_done',
        LearningSignalType.playbackStarted   => 'playback_started',
        LearningSignalType.playbackCompleted => 'playback_completed',
        LearningSignalType.aiChatMessage     => 'ai_chat_message',
        LearningSignalType.lessonRevisited   => 'lesson_revisited',
        LearningSignalType.contentSkipped    => 'content_skipped',
      };
}

// ─── User learning profile model ─────────────────────────────────────────────

class UserLearningProfile {
  final String userId;
  final String primaryInstrument;
  final String currentLevel;
  final double learningVelocity;
  final List<String> weakTopics;
  final List<String> strongTopics;
  final String preferredStyle;
  final int totalPracticeMs;
  final int streakDays;
  final double completionRate;
  final double avgQuizScore;
  final int totalSignals;
  final DateTime lastActivityAt;

  const UserLearningProfile({
    required this.userId,
    required this.primaryInstrument,
    required this.currentLevel,
    required this.learningVelocity,
    required this.weakTopics,
    required this.strongTopics,
    required this.preferredStyle,
    required this.totalPracticeMs,
    required this.streakDays,
    required this.completionRate,
    required this.avgQuizScore,
    required this.totalSignals,
    required this.lastActivityAt,
  });

  factory UserLearningProfile.fromJson(Map<String, dynamic> json) {
    return UserLearningProfile(
      userId:            json['user_id'] as String,
      primaryInstrument: json['primary_instrument'] as String? ?? 'guitar_acoustic',
      currentLevel:      json['current_level'] as String? ?? 'débutant',
      learningVelocity:  (json['learning_velocity'] as num?)?.toDouble() ?? 1.0,
      weakTopics:        _parseJsonList(json['weak_topics']),
      strongTopics:      _parseJsonList(json['strong_topics']),
      preferredStyle:    json['preferred_style'] as String? ?? 'mixed',
      totalPracticeMs:   (json['total_practice_ms'] as num?)?.toInt() ?? 0,
      streakDays:        (json['streak_days'] as num?)?.toInt() ?? 0,
      completionRate:    (json['completion_rate'] as num?)?.toDouble() ?? 0,
      avgQuizScore:      (json['avg_quiz_score'] as num?)?.toDouble() ?? 0,
      totalSignals:      (json['total_signals'] as num?)?.toInt() ?? 0,
      lastActivityAt:    DateTime.tryParse(json['last_activity_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static List<String> _parseJsonList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  /// Total practice hours as a formatted string.
  String get practiceTimeLabel {
    final totalMin = totalPracticeMs ~/ 60000;
    if (totalMin < 60) return '${totalMin}min';
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return m == 0 ? '${h}h' : '${h}h${m}min';
  }

  bool get hasWeakTopics => weakTopics.isNotEmpty;
  bool get isNewLearner  => totalSignals < 5;
}

// ─── Course recommendation model ─────────────────────────────────────────────

class CourseRecommendation {
  final String topic;
  final double difficultyScore;
  final double avgQuizScore;
  final bool isWeakTopic;
  final int totalLearners;
  final List<String> recommendedNext;
  final int priorityRank;

  const CourseRecommendation({
    required this.topic,
    required this.difficultyScore,
    required this.avgQuizScore,
    required this.isWeakTopic,
    required this.totalLearners,
    required this.recommendedNext,
    required this.priorityRank,
  });

  factory CourseRecommendation.fromJson(Map<String, dynamic> json) {
    return CourseRecommendation(
      topic:           json['topic'] as String,
      difficultyScore: (json['difficulty_score'] as num?)?.toDouble() ?? 0,
      avgQuizScore:    (json['avg_quiz_score'] as num?)?.toDouble() ?? 0,
      isWeakTopic:     json['is_weak_topic'] as bool? ?? false,
      totalLearners:   (json['total_learners'] as num?)?.toInt() ?? 0,
      recommendedNext: UserLearningProfile._parseJsonList(json['recommended_next']),
      priorityRank:    (json['priority_rank'] as num?)?.toInt() ?? 999,
    );
  }
}

// ─── AI context model (returned by fn_get_user_ai_context RPC) ───────────────

class UserAiContext {
  final bool hasProfile;
  final String primaryInstrument;
  final String currentLevel;
  final double avgQuizScore;
  final double completionRate;
  final List<String> weakTopics;
  final List<String> strongTopics;
  final int streakDays;
  final int totalPracticeMs;
  final String memorySummary;
  final List<String> memoryKeyFacts;
  final String memoryMood;

  const UserAiContext({
    required this.hasProfile,
    required this.primaryInstrument,
    required this.currentLevel,
    required this.avgQuizScore,
    required this.completionRate,
    required this.weakTopics,
    required this.strongTopics,
    required this.streakDays,
    required this.totalPracticeMs,
    required this.memorySummary,
    required this.memoryKeyFacts,
    required this.memoryMood,
  });

  factory UserAiContext.fromJson(Map<String, dynamic> json) {
    return UserAiContext(
      hasProfile:        json['has_profile'] as bool? ?? false,
      primaryInstrument: json['primary_instrument'] as String? ?? 'inconnu',
      currentLevel:      json['current_level'] as String? ?? 'débutant',
      avgQuizScore:      (json['avg_quiz_score'] as num?)?.toDouble() ?? 0,
      completionRate:    (json['completion_rate'] as num?)?.toDouble() ?? 0,
      weakTopics:        UserLearningProfile._parseJsonList(json['weak_topics']),
      strongTopics:      UserLearningProfile._parseJsonList(json['strong_topics']),
      streakDays:        (json['streak_days'] as num?)?.toInt() ?? 0,
      totalPracticeMs:   (json['total_practice_ms'] as num?)?.toInt() ?? 0,
      memorySummary:     json['memory_summary'] as String? ?? '',
      memoryKeyFacts:    UserLearningProfile._parseJsonList(json['memory_key_facts']),
      memoryMood:        json['memory_mood'] as String? ?? 'neutral',
    );
  }

  /// Builds the system-prompt context block injected into every AI request.
  /// The AI uses this to personalize advice and remembers past conversations.
  String toAiSystemBlock() {
    final sb = StringBuffer();
    sb.writeln('═══ PROFIL APPRENANT ═══');

    if (!hasProfile) {
      sb.writeln('Nouvel utilisateur — adapte ton niveau au débutant absolu.');
    } else {
      sb.writeln('Instrument principal : $primaryInstrument');
      sb.writeln('Niveau actuel       : $currentLevel');
      sb.writeln('Score moyen quiz    : ${avgQuizScore.toStringAsFixed(1)}%');
      sb.writeln('Taux de complétion  : ${completionRate.toStringAsFixed(1)}%');
      sb.writeln('Streak actuel       : $streakDays jour(s)');

      if (weakTopics.isNotEmpty) {
        sb.writeln('Points faibles      : ${weakTopics.join(', ')}');
        sb.writeln('→ Privilégie des explications détaillées sur ces points.');
      }
      if (strongTopics.isNotEmpty) {
        sb.writeln('Points forts        : ${strongTopics.join(', ')}');
        sb.writeln('→ Tu peux aller plus vite sur ces sujets.');
      }
    }

    if (memorySummary.isNotEmpty) {
      sb.writeln('');
      sb.writeln('═══ MÉMOIRE DES SESSIONS PRÉCÉDENTES ═══');
      sb.writeln(memorySummary);
      if (memoryKeyFacts.isNotEmpty) {
        sb.writeln('Faits clés : ${memoryKeyFacts.join(' | ')}');
      }
      if (memoryMood != 'neutral') {
        sb.writeln('État émotionnel lors de la dernière session : $memoryMood');
      }
    }

    sb.writeln('═══════════════════════');
    return sb.toString();
  }
}

// ─── Main service ─────────────────────────────────────────────────────────────

class LearningIntelligenceService {
  static final _db = Supabase.instance.client;

  static String? get _uid => _db.auth.currentUser?.id;

  // ── Signal tracking ────────────────────────────────────────────────────────

  /// Track a single learning event. Fire-and-forget — never throws.
  /// The SQL trigger will asynchronously update user_learning_profiles.
  static Future<void> trackSignal({
    required LearningSignalType type,
    String? instrumentId,
    String? topic,
    String? level,
    String? courseId,
    String? sectionId,
    double? score,           // 0–100
    int? durationMs,
    bool? success,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db.from('learning_signals').insert({
        'user_id':       uid,
        'signal_type':   type.value,
        'instrument_id': instrumentId,
        'topic':         topic,
        'level':         level,
        'course_id':     courseId,
        'section_id':    sectionId,
        'score':         score,
        'duration_ms':   durationMs,
        'success':       success,
        'metadata':      metadata,
      });
    } catch (e) {
      // Never crash the app because of analytics
      debugLog('LearningIntelligenceService.trackSignal error: $e');
    }
  }

  /// Convenience: track when a section is completed with duration.
  static Future<void> trackSectionCompleted({
    required String courseId,
    required String sectionId,
    required String instrumentId,
    required String topic,
    required String level,
    required int durationMs,
  }) => trackSignal(
        type:         LearningSignalType.sectionCompleted,
        courseId:     courseId,
        sectionId:    sectionId,
        instrumentId: instrumentId,
        topic:        topic,
        level:        level,
        durationMs:   durationMs,
        success:      true,
      );

  /// Convenience: track a quiz result.
  static Future<void> trackQuizResult({
    required String topic,
    required String level,
    required String instrumentId,
    required double score,
    required int totalQuestions,
    required int durationMs,
  }) => trackSignal(
        type:         score >= 60
                        ? LearningSignalType.quizPassed
                        : LearningSignalType.quizFailed,
        instrumentId: instrumentId,
        topic:        topic,
        level:        level,
        score:        score,
        durationMs:   durationMs,
        success:      score >= 60,
        metadata:     {'total_questions': totalQuestions},
      );

  /// Convenience: track an analysis session.
  static Future<void> trackAnalysis({
    required String instrumentId,
    required String detectedKey,
    required int bpm,
    required int processingMs,
  }) => trackSignal(
        type:         LearningSignalType.analysisDone,
        instrumentId: instrumentId,
        durationMs:   processingMs,
        success:      true,
        metadata:     {'key': detectedKey, 'bpm': bpm},
      );

  // ── Profile & AI context ───────────────────────────────────────────────────

  /// Fetch the current user's learning profile from Supabase.
  static Future<UserLearningProfile?> getProfile() async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final row = await _db
          .from('user_learning_profiles')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (row == null) return null;
      return UserLearningProfile.fromJson(row);
    } catch (e) {
      debugLog('LearningIntelligenceService.getProfile error: $e');
      return null;
    }
  }

  /// Calls the Supabase RPC `fn_get_user_ai_context` to get the full
  /// personalized AI context to inject into chat prompts.
  static Future<UserAiContext?> getAiContext() async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final result = await _db.rpc(
        'fn_get_user_ai_context',
        params: {'p_user_id': uid},
      );
      if (result == null) return null;
      return UserAiContext.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      debugLog('LearningIntelligenceService.getAiContext error: $e');
      return null;
    }
  }

  // ── Recommendations ────────────────────────────────────────────────────────

  /// Get personalized course recommendations via RPC.
  /// For new users (no history), this calls the cold-start path in SQL
  /// which ranks topics by global difficulty + popularity.
  static Future<List<CourseRecommendation>> getRecommendations({
    required String instrumentId,
    required String level,
  }) async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final rows = await _db.rpc(
        'fn_get_recommended_courses',
        params: {
          'p_user_id':    uid,
          'p_instrument': instrumentId,
          'p_level':      level,
        },
      );

      if (rows == null) return [];
      return (rows as List)
          .map((r) => CourseRecommendation.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugLog('LearningIntelligenceService.getRecommendations error: $e');
      return [];
    }
  }

  // ── AI Conversation Memory ─────────────────────────────────────────────────

  /// Save a compressed conversation memory after an AI chat session ends.
  /// [summary] should be a Claude/Gemini-generated 2-3 sentence recap.
  /// [keyFacts] extracted entities: strengths, struggles, goals.
  static Future<void> saveConversationMemory({
    required String summary,
    required List<String> keyFacts,
    String? instrumentId,
    String mood = 'neutral',
  }) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      // Try to update existing memory first (upsert)
      final existing = await _db
          .from('ai_conversation_memory')
          .select('id, session_count')
          .eq('user_id', uid)
          .maybeSingle();

      if (existing != null) {
        await _db
            .from('ai_conversation_memory')
            .update({
              'summary':       summary,
              'key_facts':     keyFacts,
              'mood':          mood,
              'session_count': (existing['session_count'] as int? ?? 0) + 1,
              'updated_at':    DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id'] as String);
      } else {
        await _db.from('ai_conversation_memory').insert({
          'user_id':       uid,
          'instrument_id': instrumentId,
          'summary':       summary,
          'key_facts':     keyFacts,
          'mood':          mood,
          'session_count': 1,
        });
      }
    } catch (e) {
      debugLog('LearningIntelligenceService.saveConversationMemory error: $e');
    }
  }

  /// Load the latest conversation memory for display in the chat header.
  static Future<Map<String, dynamic>?> getConversationMemory() async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      return await _db
          .from('ai_conversation_memory')
          .select()
          .eq('user_id', uid)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      debugLog('LearningIntelligenceService.getConversationMemory error: $e');
      return null;
    }
  }

  // ── Stats helpers ──────────────────────────────────────────────────────────

  /// Quick stats for the profile screen / learning dashboard.
  static Future<Map<String, dynamic>> getQuickStats() async {
    final profile = await getProfile();
    if (profile == null) {
      return {
        'streak': 0,
        'practice_label': '0min',
        'avg_score': 0.0,
        'completion_rate': 0.0,
        'weak_count': 0,
        'is_new': true,
      };
    }
    return {
      'streak':           profile.streakDays,
      'practice_label':   profile.practiceTimeLabel,
      'avg_score':        profile.avgQuizScore,
      'completion_rate':  profile.completionRate,
      'weak_count':       profile.weakTopics.length,
      'is_new':           profile.isNewLearner,
      'weak_topics':      profile.weakTopics,
      'strong_topics':    profile.strongTopics,
    };
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  static void debugLog(String msg) {
    // Replace with your logger if desired
    // ignore: avoid_print
    assert(() { print('[LIS] $msg'); return true; }());
  }
}
