// lib/services/api_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  // ⚠️ Remplace par ton URL backend en production
  // En développement local : 'http://10.0.2.2:8000' (Android émulateur)
  // En développement physique : 'http://TON_IP_LOCAL:8000'
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.178.4:8000', // IP de ton ordi en local
  );

  static final _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120), // analyse peut prendre du temps
    headers: {'Accept': 'application/json'},
  ));

  // ─── ANALYSE AUDIO/VIDÉO ─────────────────────────────────────────────────

  /// Envoie un fichier audio/vidéo pour analyse
  /// Retourne notes, accords, BPM, tonalité, URL audio généré
  static Future<AnalysisResult> analyseFile({
    required File file,
    required String instrumentId,
    String fileType = 'audio',
  }) async {
    final mimeType = lookupMimeType(file.path) ?? 'audio/mpeg';
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        contentType: MediaType.parse(mimeType),
      ),
      'instrument': instrumentId,
      'file_type': fileType,
    });

    final response = await _dio.post('/analyse', data: formData);
    return AnalysisResult.fromJson(response.data);
  }

  /// Envoie des bytes audio (depuis enregistrement direct)
  static Future<AnalysisResult> analyseBytes({
    required List<int> audioBytes,
    required String instrumentId,
    String filename = 'recording.wav',
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        audioBytes,
        filename: filename,
        contentType: MediaType('audio', 'wav'),
      ),
      'instrument': instrumentId,
      'file_type': 'audio',
    });

    final response = await _dio.post('/analyse', data: formData);
    return AnalysisResult.fromJson(response.data);
  }

  // ─── ANALYSE PARTITION (PDF / Image) ─────────────────────────────────────

  /// Envoie une partition PDF ou image pour lecture par l'IA
  static Future<AnalysisResult> analysePartition({
    required File file,
    required String instrumentId,
  }) async {
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        contentType: MediaType.parse(mimeType),
      ),
      'instrument': instrumentId,
    });

    final response = await _dio.post('/partition', data: formData);
    return AnalysisResult.fromJson(response.data);
  }

  // ─── SYNTHÈSE AUDIO ───────────────────────────────────────────────────────

  /// Génère un fichier audio à partir de notes MIDI + instrument
  static Future<String> synthesize({
    required List<String> notes,
    required String instrumentId,
    int bpm = 120,
  }) async {
    final response = await _dio.post('/synthesize', data: {
      'notes': notes,
      'instrument': instrumentId,
      'bpm': bpm,
    });
    return response.data['audio_url'] as String;
  }

  // ─── SANTÉ DU BACKEND ─────────────────────────────────────────────────────

  static Future<bool> isBackendOnline() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// ─── Modèle de résultat d'analyse ────────────────────────────────────────────

class AnalysisResult {
  final String key;
  final int bpm;
  final List<String> notes;
  final List<String> chords;
  final String? audioUrl;
  final String? midiUrl;
  final String? partitionUrl; // URL image/PDF de la partition générée
  final String? error;

  const AnalysisResult({
    required this.key,
    required this.bpm,
    required this.notes,
    required this.chords,
    this.audioUrl,
    this.midiUrl,
    this.partitionUrl,
    this.error,
  });

  bool get hasError => error != null;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      key: json['key'] as String? ?? 'C',
      bpm: json['bpm'] as int? ?? 120,
      notes: List<String>.from(json['notes'] as List? ?? []),
      chords: List<String>.from(json['chords'] as List? ?? []),
      audioUrl: json['audio_url'] as String?,
      midiUrl: json['midi_url'] as String?,
      partitionUrl: json['partition_url'] as String?,
      error: json['error'] as String?,
    );
  }

  factory AnalysisResult.demo() {
    return const AnalysisResult(
      key: 'Am',
      bpm: 120,
      notes: ['A3', 'C4', 'E4', 'G4', 'A4', 'B4', 'C5', 'E5'],
      chords: ['Am', 'F', 'C', 'G', 'Am', 'E', 'Am'],
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'bpm': bpm,
    'notes': notes,
    'chords': chords,
    'audio_url': audioUrl,
    'midi_url': midiUrl,
    'partition_url': partitionUrl,
  };
}

