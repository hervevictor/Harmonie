// lib/services/audio_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static final AudioRecorder _recorder = AudioRecorder();
  static bool _isRecording = false;
  static String? _currentRecordingPath;

  // ─── LECTURE ──────────────────────────────────────────────────────────────

  static Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  static Stream<Duration?> get durationStream => _player.durationStream;
  static Stream<Duration> get positionStream => _player.positionStream;
  static bool get isPlaying => _player.playing;

  static Future<void> play(String source) async {
    await _player.stop();
    if (source.startsWith('http')) {
      await _player.setUrl(source);
    } else {
      await _player.setFilePath(source);
    }
    await _player.play();
  }

  static Future<void> pause() => _player.pause();
  static Future<void> resume() => _player.play();
  static Future<void> stop() => _player.stop();
  static Future<void> seek(Duration position) => _player.seek(position);

  static void disposePlayer() => _player.dispose();

  // ─── ENREGISTREMENT ───────────────────────────────────────────────────────

  static bool get isRecording => _isRecording;
  static String? get currentRecordingPath => _currentRecordingPath;

  static Future<bool> requestPermissions({bool withCamera = false}) async {
    final mic = await Permission.microphone.request();
    if (withCamera) {
      final cam = await Permission.camera.request();
      return mic.isGranted && cam.isGranted;
    }
    return mic.isGranted;
  }

  static Future<String?> startRecording() async {
    final granted = await requestPermissions();
    if (!granted) return null;

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/recording_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,  // compatible Android + iOS
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: path,
    );

    _isRecording = true;
    _currentRecordingPath = path;
    return path;
  }

  static Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    _currentRecordingPath = null;
    return path;
  }

  static Future<void> pauseRecording() async {
    if (!_isRecording) return;
    await _recorder.pause();
  }

  static Future<void> resumeRecording() async {
    await _recorder.resume();
  }

  static Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.cancel();
      _isRecording = false;
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) await file.delete();
        _currentRecordingPath = null;
      }
    }
  }

  // ─── AMPLITUDE ────────────────────────────────────────────────────────────

  static Stream<Amplitude> get amplitudeStream =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  // ─── UTILITAIRES ─────────────────────────────────────────────────────────

  static String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ignore: unused_element
  static Uint8List _toUint8List(List<int> bytes) => Uint8List.fromList(bytes);
}