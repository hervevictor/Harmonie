// lib/services/supabase_service.dart
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;
  static const _uuid = Uuid();

  // ─── AUTH ────────────────────────────────────────────────────────────────

  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Future<AuthResponse> signUp(String email, String password) =>
      _client.auth.signUp(email: email, password: password);

  static Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  static Future<void> signOut() => _client.auth.signOut();

  static Stream<AuthState> get authStream => _client.auth.onAuthStateChange;

  // ─── STORAGE — Upload fichiers ────────────────────────────────────────────

  /// Upload un fichier audio/vidéo/image/pdf dans Supabase Storage
  /// Retourne l'URL publique du fichier
  static Future<String> uploadFile({
    required File file,
    required String bucket, // 'audio', 'videos', 'partitions'
    String? folder,
  }) async {
    final userId = currentUser?.id ?? 'anonymous';
    final ext = p.extension(file.path);
    final filename = '${_uuid.v4()}$ext';
    final path = folder != null
        ? '$userId/$folder/$filename'
        : '$userId/$filename';

    await _client.storage.from(bucket).upload(
      path,
      file,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Upload depuis des bytes (pour l'enregistrement direct)
  static Future<String> uploadBytes({
    required List<int> bytes,
    required String bucket,
    required String filename,
    String? folder,
  }) async {
    final userId = currentUser?.id ?? 'anonymous';
    final path = folder != null
        ? '$userId/$folder/$filename'
        : '$userId/$filename';

    await _client.storage.from(bucket).uploadBinary(
      path,
      bytes as Uint8List,
      fileOptions: const FileOptions(cacheControl: '3600'),
    );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  // ─── SESSIONS — Historique d'analyse ─────────────────────────────────────

  /// Sauvegarde une session d'analyse complète
  static Future<Map<String, dynamic>> saveSession({
    required String title,
    required String instrumentId,
    required String fileUrl,
    required String fileType, // audio | video | image | pdf
    required Map<String, dynamic> analysisResult,
  }) async {
    final userId = currentUser?.id;
    final data = {
      'user_id': userId,
      'title': title,
      'instrument_id': instrumentId,
      'file_url': fileUrl,
      'file_type': fileType,
      'key_signature': analysisResult['audio_features']?['key_signature'] ?? analysisResult['harmony']?['key_signature'],
      'bpm': analysisResult['audio_features']?['bpm'],
      'chords': analysisResult['harmony']?['chord_progression'],
      'notes': analysisResult['notes'],
      'audio_result_url': analysisResult['audio_result_url'], // Si présent
      'job_id': analysisResult['job_id'],
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('sessions')
        .insert(data)
        .select()
        .single();

    return response;
  }

  /// Récupère les sessions de l'utilisateur
  static Future<List<Map<String, dynamic>>> getSessions({int limit = 20}) async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('sessions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Récupère une session par ID
  static Future<Map<String, dynamic>?> getSession(String id) async {
    final response = await _client
        .from('sessions')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  /// Supprime une session
  static Future<void> deleteSession(String id) async {
    await _client.from('sessions').delete().eq('id', id);
  }

  // ─── INSTRUMENTS favoris de l'utilisateur ────────────────────────────────

  static Future<List<String>> getFavoriteInstruments() async {
    final userId = currentUser?.id;
    if (userId == null) return ['guitar_acoustic'];

    final response = await _client
        .from('user_instruments')
        .select('instrument_id')
        .eq('user_id', userId);

    return (response as List)
        .map((r) => r['instrument_id'] as String)
        .toList();
  }

  static Future<void> saveFavoriteInstruments(List<String> ids) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    // Supprimer les anciens, insérer les nouveaux
    await _client.from('user_instruments').delete().eq('user_id', userId);
    if (ids.isEmpty) return;

    await _client.from('user_instruments').insert(
      ids.map((id) => {'user_id': userId, 'instrument_id': id}).toList(),
    );
  }

  // ─── LEARNING SYSTEM ─────────────────────────────────────────────────────

  /// Manually insert a learning signal. In practice, use
  /// [LearningIntelligenceService.trackSignal()] which is fire-and-forget
  /// and never throws.
  static Future<void> saveLearningSignal({
    required String signalType,
    String? instrumentId,
    String? topic,
    String? level,
    String? courseId,
    String? sectionId,
    double? score,
    int? durationMs,
    bool? success,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from('learning_signals').insert({
      'user_id':       userId,
      'signal_type':   signalType,
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
  }

  /// Fetch recent learning signals for the current user.
  static Future<List<Map<String, dynamic>>> getRecentSignals({
    int limit = 50,
    String? signalType,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    var query = _client
        .from('learning_signals')
        .select()
        .eq('user_id', userId);

    if (signalType != null) {
      query = query.eq('signal_type', signalType);
    }

    final result = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(result);
  }

  /// Fetch the current user's computed learning profile.
  static Future<Map<String, dynamic>?> getLearningProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    return await _client
        .from('user_learning_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  /// Call the Supabase RPC to get the full AI personalization context.
  static Future<Map<String, dynamic>?> getAiLearningContext() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final result = await _client.rpc(
      'fn_get_user_ai_context',
      params: {'p_user_id': userId},
    );
    if (result == null) return null;
    return result as Map<String, dynamic>;
  }

  /// Get personalized course recommendations via RPC.
  static Future<List<Map<String, dynamic>>> getRecommendedCourses({
    required String instrumentId,
    required String level,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final result = await _client.rpc(
      'fn_get_recommended_courses',
      params: {
        'p_user_id':    userId,
        'p_instrument': instrumentId,
        'p_level':      level,
      },
    );
    if (result == null) return [];
    return List<Map<String, dynamic>>.from(result as List);
  }

  /// Save or update the AI conversation memory for the current user.
  static Future<void> saveConversationMemory({
    required String summary,
    required List<String> keyFacts,
    String? instrumentId,
    String mood = 'neutral',
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final existing = await _client
        .from('ai_conversation_memory')
        .select('id, session_count')
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _client
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
      await _client.from('ai_conversation_memory').insert({
        'user_id':       userId,
        'instrument_id': instrumentId,
        'summary':       summary,
        'key_facts':     keyFacts,
        'mood':          mood,
      });
    }
  }

  /// Fetch the most recent AI conversation memory for the current user.
  static Future<Map<String, dynamic>?> getConversationMemory() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    return await _client
        .from('ai_conversation_memory')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  /// Fetch global learning insights for an instrument and level.
  /// Useful for showing aggregate stats ("85% des guitaristes débutants
  /// ont du mal avec X") in the learn screen.
  static Future<List<Map<String, dynamic>>> getGlobalInsights({
    required String instrumentId,
    required String level,
  }) async {
    return List<Map<String, dynamic>>.from(
      await _client
          .from('global_learning_insights')
          .select()
          .eq('instrument_id', instrumentId)
          .eq('level', level)
          .order('difficulty_score', ascending: true),
    );
  }
}

