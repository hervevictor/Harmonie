// lib/services/ai_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import '../config/secrets.dart';
import 'api_service.dart';

class AiMessage {
  final String role; // 'user' | 'assistant'
  final String content;

  const AiMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class AiService {
  static const _dartDefineKey =
      String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');
  static final _apiKey =
      anthropicApiKey.startsWith('REMPLACE') ? _dartDefineKey : anthropicApiKey;

  static const _model = 'claude-3-5-sonnet-20241022';

  static const _baseUrl = 'https://api.anthropic.com/v1/messages';

  static Map<String, String> get _headers => {
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      };

  static const _systemPrompt =
      'Tu es Harmonie, un assistant musical expert et pédagogue. '
      'Tu aides les musiciens à comprendre les notes, accords, gammes et théorie musicale, '
      'analyser des morceaux, apprendre à jouer d\'un instrument, lire des partitions '
      'et progresser dans leur pratique. '
      'Réponds toujours en français, de façon claire, chaleureuse et pédagogique. '
      'Utilise des exemples concrets et des analogies musicales. '
      'Si on te donne des données d\'analyse (notes, accords, tonalité, BPM), '
      'intègre-les dans tes réponses pour contextualiser tes explications.';

  // ── Chat ──────────────────────────────────────────────────────────────────

  static Future<String> chat({
    required List<AiMessage> messages,
    String? analysisContext,
  }) async {
    _requireKey();

    final systemContent = (analysisContext != null && analysisContext.isNotEmpty)
        ? '$_systemPrompt\n\nContexte musical analysé :\n$analysisContext'
        : _systemPrompt;

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 1024,
      'system': systemContent,
      'messages': messages.map((m) => m.toJson()).toList(),
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final errMsg = (data['error'] as Map?)?['message'] as String?
          ?? 'Erreur ${response.statusCode}';
      throw HttpException('${response.statusCode}: $errMsg');
    }

    final content = data['content'] as List?;
    if (content == null || content.isEmpty) throw Exception('Réponse vide');
    return content.first['text'] as String;
  }

  // ── Analyse fichier via Claude ────────────────────────────────────────────

  static Future<AnalysisResult> analyseFile({
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

  static Future<AnalysisResult> _analyseImageVision(
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

  static Future<AnalysisResult> _analyseAudioContext(
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

  static AnalysisResult _parseResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) return AnalysisResult.demo();
      final text = (data['content'] as List).first['text'] as String;
      final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (match != null) {
        final map = jsonDecode(match.group(0)!) as Map<String, dynamic>;
        return AnalysisResult.fromJson(map);
      }
    } catch (_) {}
    return AnalysisResult.demo();
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
  }) {
    return 'Fichier : $fileName\n'
        'Instrument cible : $instrumentId\n'
        'Tonalité : $key\n'
        'BPM : $bpm\n'
        'Progression d\'accords : ${chords.join(' → ')}\n'
        'Séquence de notes : ${notes.join(', ')}';
  }
}
