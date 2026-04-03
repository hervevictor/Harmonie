// lib/services/media_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

enum MediaType { audio, video, image, pdf, unknown }

class MediaFile {
  final File file;
  final String name;
  final MediaType type;
  final int sizeBytes;

  const MediaFile({
    required this.file,
    required this.name,
    required this.type,
    required this.sizeBytes,
  });

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get typeLabel {
    switch (type) {
      case MediaType.audio: return 'Audio';
      case MediaType.video: return 'Vidéo';
      case MediaType.image: return 'Image';
      case MediaType.pdf: return 'PDF';
      case MediaType.unknown: return 'Fichier';
    }
  }

  String get typeEmoji {
    switch (type) {
      case MediaType.audio: return '🎵';
      case MediaType.video: return '🎬';
      case MediaType.image: return '🖼';
      case MediaType.pdf: return '📄';
      case MediaType.unknown: return '📎';
    }
  }
}

class MediaService {
  static final _imagePicker = ImagePicker();

  // ─── SÉLECTION DE FICHIERS ────────────────────────────────────────────────

  /// Ouvre le sélecteur de fichiers — tous types
  static Future<MediaFile?> pickAny() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp3', 'wav', 'm4a', 'flac', 'ogg', 'aac',
        'mp4', 'mov', 'mkv', 'avi',
        'jpg', 'jpeg', 'png', 'heic', 'webp',
        'pdf',
      ],
      withData: false,
    );
    return _fromPickerResult(result);
  }

  /// Sélection audio uniquement
  static Future<MediaFile?> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'flac', 'ogg', 'aac'],
    );
    return _fromPickerResult(result);
  }

  /// Sélection vidéo depuis la galerie
  static Future<MediaFile?> pickVideo() async {
    final xfile = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
    if (xfile == null) return null;
    return _fromXFile(xfile);
  }

  /// Sélection image depuis galerie ou caméra
  static Future<MediaFile?> pickImage({bool fromCamera = false}) async {
    final xfile = await _imagePicker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 90,
    );
    if (xfile == null) return null;
    return _fromXFile(xfile);
  }

  /// Sélection PDF
  static Future<MediaFile?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    return _fromPickerResult(result);
  }

  // ─── DÉTECTION DU TYPE ────────────────────────────────────────────────────

  static MediaType detectType(String filePath) {
    final ext = p.extension(filePath).toLowerCase().replaceAll('.', '');
    final mime = lookupMimeType(filePath) ?? '';

    if (['mp3', 'wav', 'm4a', 'flac', 'ogg', 'aac'].contains(ext) ||
        mime.startsWith('audio/')) {
      return MediaType.audio;
    }
    if (['mp4', 'mov', 'mkv', 'avi'].contains(ext) ||
        mime.startsWith('video/')) {
      return MediaType.video;
    }
    if (['jpg', 'jpeg', 'png', 'heic', 'webp', 'gif'].contains(ext) ||
        mime.startsWith('image/')) {
      return MediaType.image;
    }
    if (ext == 'pdf' || mime == 'application/pdf') {
      return MediaType.pdf;
    }
    return MediaType.unknown;
  }

  // ─── HELPERS PRIVÉS ───────────────────────────────────────────────────────

  static MediaFile? _fromPickerResult(FilePickerResult? result) {
    if (result == null || result.files.isEmpty) return null;
    final pf = result.files.first;
    if (pf.path == null) return null;

    final file = File(pf.path!);
    return MediaFile(
      file: file,
      name: pf.name,
      type: detectType(pf.path!),
      sizeBytes: pf.size,
    );
  }

  static Future<MediaFile?> _fromXFile(XFile xfile) async {
    final file = File(xfile.path);
    final stat = await file.stat();
    return MediaFile(
      file: file,
      name: p.basename(xfile.path),
      type: detectType(xfile.path),
      sizeBytes: stat.size,
    );
  }
}

