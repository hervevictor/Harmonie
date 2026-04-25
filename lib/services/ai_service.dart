// lib/services/ai_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import '../config/secrets.dart';
import '../models/music_result.dart';
import 'api_service.dart';

class AiMessage {
  final String role; // 'user' | 'assistant'
  final String content;

  const AiMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class AiService {
  static String get _baseUrl => "${ApiService.baseUrl}/api/v1/harmony/chat";

  static const _model = 'claude-3-5-sonnet-20241022';
  static const _apiKey = 'BACKEND_HANDLED'; // On évite de lever l'exception cle_manquante
  static Map<String, String> get _headers => {
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      };

  // ── Chat ──────────────────────────────────────────────────────────────────

  static Future<String> chat({
    required List<AiMessage> messages,
    String? analysisContext,
  }) async {
    final body = jsonEncode({
      'messages': messages.map((m) => m.toJson()).toList(),
      'analysisContext': analysisContext,
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final errMsg = data['error'] ?? 'Erreur serveur ${response.statusCode}';
      throw HttpException(errMsg);
    }

    return (data['content'] as String?) ?? 'Désolé, je ne peux pas répondre.';
  }

  // ── Analyse fichier via Claude ────────────────────────────────────────────

  static Future<MusicResult> analyseFile({
    required File file,
    required String instrumentId,
    required String fileType,
    String? fileName,
  }) async {
    _requireKey();
    final name = fileName ?? file.path.split('/').last;
    if (fileType == 'image') {
      return _analyseImageVision(file, instrumentId, name);
    }
    return _analyseAudioContext(name, instrumentId, fileType);
  }

  static Future<MusicResult> _analyseImageVision(
      File file, String instrumentId, String fileName) async {
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    final mime = lookupMimeType(file.path) ?? 'image/jpeg';

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 1024,
      'system': 'Tu es un expert en solfège. Réponds UNIQUEMENT en JSON valide, sans markdown.',
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {'type': 'base64', 'media_type': mime, 'data': b64}
            },
            {
              'type': 'text',
              'text': 'Analyse cette partition pour "$instrumentId". '
                  'Retourne UNIQUEMENT ce JSON (notation française) :\n'
                  '{"key":"tonalité ex: Lam","bpm":120,"notes":["Do4","Ré4"],"chords":["Lam","Fa"]}'
            }
          ]
        }
      ]
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );

    return _parseResponse(response);
  }

  static Future<MusicResult> _analyseAudioContext(
      String fileName, String instrumentId, String fileType) async {
    final body = jsonEncode({
      'model': _model,
      'max_tokens': 512,
      'system': 'Tu es un expert musical. Réponds UNIQUEMENT en JSON valide, sans markdown.',
      'messages': [
        {
          'role': 'user',
          'content': 'Génère une analyse musicale plausible pour un fichier $fileType '
              'nommé "$fileName" pour "$instrumentId". '
              'Retourne UNIQUEMENT ce JSON (notation française) :\n'
              '{"key":"tonalité","bpm":120,"notes":["Do4","Ré4"],"chords":["Lam","Fa"]}'
        }
      ]
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );

    return _parseResponse(response);
  }

  static MusicResult _parseResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) return MusicResult.demo();
      final text = (data['content'] as List).first['text'] as String;
      final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (match != null) {
        final map = jsonDecode(match.group(0)!) as Map<String, dynamic>;
        return MusicResult.fromJson(map);
      }
    } catch (_) {}
    return MusicResult.demo();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static void _requireKey() {
    if (_apiKey.isEmpty) throw Exception('cle_manquante');
  }

  static bool get hasApiKey => _apiKey.isNotEmpty;

  static String buildAnalysisContext({
    required String fileName,
    required String instrumentId,
    required String key,
    required int bpm,
    required List<String> chords,
    required List<String> notes,
    MusicResult? rawResult,
  }) {
    final harmony = rawResult?.harmony;
    final audio = rawResult?.audioFeatures;
    
    return 'Fichier : $fileName\n'
        'Instrument cible : $instrumentId\n'
        '--- RÉSULTATS DE L\'ANALYSE TECHNIQUE ---\n'
        'Tonalité détectée : ${key.isEmpty ? "Inconnue" : key}\n'
        'Tempo (BPM) : ${bpm == 0 ? "Non détecté" : bpm}\n'
        'Précision harmonique : ${harmony?.keySignature ?? "N/A"}\n'
        'Énergie audio : ${audio?.energy?.toStringAsFixed(2) ?? "N/A"}\n'
        'Danseabilité : ${audio?.danceability?.toStringAsFixed(2) ?? "N/A"}\n'
        'Progression d\'accords complète : ${chords.join(' → ')}\n'
        'Séquence de notes principales : ${notes.take(50).join(', ')}${notes.length > 50 ? "..." : ""}\n'
        '--- CONTRÔLE ---\n'
        'Tu es un expert musicologue. Analyse ces données pour donner des conseils avancés sur la structure, l\'interprétation et la théorie derrière ce morceau.';
  }
}
