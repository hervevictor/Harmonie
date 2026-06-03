// lib/services/api_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import '../models/music_result.dart';

class ApiService {
  // 💡 Pour tester l'API locale sur Android Emulateur, utiliser http://10.0.2.2:8000
  // Pour iOS ou PC, utiliser http://localhost:8000
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.3.3.50:8000', 
  );

  static final _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
    headers: {'Accept': 'application/json'},
  ))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
        } catch (_) {}
        return handler.next(options);
      },
    ))
    ..interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
    ));

  /// POINT D'ENTRÉE UNIVERSEL
  /// Envoie n'importe quel fichier (Audio, Vidéo, Partition)
  /// Le serveur détecte automatiquement le pipeline à utiliser.
  static Future<MusicResult> analyze({
    required File file,
    String? targetKey,
    String? openaiApiKey,
  }) async {
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
        contentType: MediaType.parse(mimeType),
      ),
      if (targetKey != null) 'target_key': targetKey,
      if (openaiApiKey != null) 'openai_api_key': openaiApiKey,
    });

    final response = await _dio.post('/api/analyze', data: formData);
    
    if (response.statusCode == 200) {
      return MusicResult.fromJson(response.data);
    } else {
      throw Exception('Erreur API: ${response.statusMessage}');
    }
  }

  /// ANALYSE MICROPHONE (Live Recording)
  static Future<MusicResult> analyzeMic({
    required List<int> audioBytes,
    String filename = 'live_recording.wav',
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        audioBytes,
        filename: filename,
        contentType: MediaType('audio', 'wav'),
      ),
    });

    final response = await _dio.post('/api/analyze/mic', data: formData);
    return MusicResult.fromJson(response.data);
  }

  /// RÉCUPÉRER L'ÉTAT D'UN JOB
  static Future<MusicResult> getJobStatus(String jobId) async {
    final response = await _dio.get('/api/jobs/$jobId');
    return MusicResult.fromJson(response.data);
  }

  /// Génère un quiz d'évaluation via l'API IA
  static Future<Map<String, dynamic>> generateQuiz({
    required String instrument,
    required String topic,
    required String level,
    int numQuestions = 5,
    String? analysisId,
  }) async {
    final response = await _dio.post(
      '/api/v1/quiz/generate',
      data: {
        'instrument': instrument,
        'topic': topic,
        'level': level,
        'num_questions': numQuestions,
        if (analysisId != null) 'analysis_id': analysisId,
      },
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Erreur génération quiz: ${response.statusMessage}');
  }

  /// Évalue les réponses du quiz et retourne le score + feedback IA
  static Future<Map<String, dynamic>> evaluateQuiz({
    required Map<String, dynamic> quiz,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await _dio.post(
      '/api/v1/quiz/evaluate',
      data: {
        'quiz': quiz,
        'answers': answers,
      },
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Erreur évaluation quiz: ${response.statusMessage}');
  }

  /// VÉRIFICATION SANTÉ
  static Future<bool> isOnline() async {
    try {
      final response = await _dio.get('/api/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
