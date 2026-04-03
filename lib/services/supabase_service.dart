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
      'key_signature': analysisResult['key'],
      'bpm': analysisResult['bpm'],
      'chords': analysisResult['chords'],
      'notes': analysisResult['notes'],
      'audio_result_url': analysisResult['audioUrl'],
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
}

