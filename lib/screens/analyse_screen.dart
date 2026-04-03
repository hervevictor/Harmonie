// lib/screens/analyse_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../theme/app_theme.dart';
import '../models/instrument.dart';
import '../widgets/instrument_card.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/media_service.dart';
import '../services/supabase_service.dart';

class AnalyseScreen extends StatefulWidget {
  const AnalyseScreen({super.key});
  @override
  State<AnalyseScreen> createState() => _AnalyseScreenState();
}

class _AnalyseScreenState extends State<AnalyseScreen> {
  File? _selectedFile;
  String? _selectedFileName;
  String _selectedFileType = 'audio';
  String _selectedInstrumentId = 'guitar_acoustic';
  bool _isAnalysing = false;
  String? _errorMessage;

  final _fileTypes = [
    {'label': '🎵 Audio', 'type': 'audio', 'formats': 'MP3, WAV, M4A, FLAC'},
    {'label': '🎬 Vidéo', 'type': 'video', 'formats': 'MP4, MOV, MKV'},
    {'label': '🖼 Image', 'type': 'image', 'formats': 'JPG, PNG, HEIC'},
    {'label': '📄 PDF', 'type': 'pdf', 'formats': 'PDF partition'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      appBar: AppBar(
        backgroundColor: HarmonieColors.bg,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: HarmonieColors.cream, size: 20),
        ),
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              fontSize: 20,
              color: HarmonieColors.cream,
            ),
            children: const [
              TextSpan(text: 'Analyser un '),
              TextSpan(
                text: 'chant',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: HarmonieColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Step 1: Type de fichier ──────────────────────────────────
            _StepLabel(number: '1', label: 'Type de fichier'),
            const SizedBox(height: 12),
            Row(
              children: _fileTypes.map((ft) {
                final active = _selectedFileType == ft['type'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedFileType = ft['type']!;
                      _selectedFile = null;
                      _selectedFileName = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: active
                            ? HarmonieColors.gold.withValues(alpha: 0.15)
                            : HarmonieColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                              ? HarmonieColors.gold
                              : const Color(0x12FFFFFF),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(ft['label']!.split(' ')[0],
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            ft['label']!.split(' ').skip(1).join(' '),
                            style: TextStyle(
                              fontSize: 10,
                              color: active
                                  ? HarmonieColors.gold
                                  : HarmonieColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ─── Step 2: Importer le fichier ──────────────────────────────
            _StepLabel(number: '2', label: 'Importer votre fichier'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickFile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: _selectedFile != null
                      ? HarmonieColors.gold.withValues(alpha: 0.08)
                      : HarmonieColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null
                        ? HarmonieColors.gold.withValues(alpha: 0.5)
                        : HarmonieColors.gold.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_rounded,
                      color: _selectedFile != null
                          ? HarmonieColors.gold
                          : HarmonieColors.muted,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFileName ?? 'Appuyer pour importer',
                      style: TextStyle(
                        color: _selectedFile != null
                            ? HarmonieColors.cream
                            : HarmonieColors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fileTypes
                          .firstWhere(
                              (f) => f['type'] == _selectedFileType)['formats']!,
                      style: const TextStyle(
                        color: HarmonieColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Preview ──────────────────────────────────────────────────
            if (_selectedFile != null) ...[
              const SizedBox(height: 16),
              if (_selectedFileType == 'audio')
                _AudioPreviewPlayer(file: _selectedFile!)
              else if (_selectedFileType == 'image')
                _ImagePreview(file: _selectedFile!)
              else
                _FileInfoPreview(
                  file: _selectedFile!,
                  name: _selectedFileName ?? '',
                  type: _selectedFileType,
                ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OU',
                    style: const TextStyle(
                      color: HarmonieColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/enregistrer'),
                icon: const Icon(Icons.mic_rounded,
                    color: HarmonieColors.gold, size: 18),
                label: const Text(
                  'Enregistrer maintenant',
                  style: TextStyle(color: HarmonieColors.gold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: HarmonieColors.gold, width: 0.8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ─── Step 3: Choisir l'instrument ─────────────────────────────
            _StepLabel(number: '3', label: 'Instrument de sortie'),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: InstrumentCatalog.all.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final instr = InstrumentCatalog.all[i];
                  return InstrumentCard(
                    instrument: instr,
                    isSelected: _selectedInstrumentId == instr.id,
                    onTap: () =>
                        setState(() => _selectedInstrumentId = instr.id),
                  );
                },
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: HarmonieColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: HarmonieColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: HarmonieColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: HarmonieColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ─── Bouton Analyser ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedFile == null
                    ? null
                    : _isAnalysing
                        ? null
                        : _startAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HarmonieColors.gold,
                  disabledBackgroundColor: HarmonieColors.surface2,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isAnalysing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              color: Colors.black, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Analyser avec l\'IA',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      MediaFile? media;
      switch (_selectedFileType) {
        case 'audio':
          media = await MediaService.pickAudio();
          break;
        case 'video':
          media = await MediaService.pickVideo();
          break;
        case 'image':
          media = await MediaService.pickImage();
          break;
        case 'pdf':
          media = await MediaService.pickPdf();
          break;
        default:
          media = await MediaService.pickAny();
      }
      if (media != null) {
        setState(() {
          _selectedFile = media!.file;
          _selectedFileName = media.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors de la sélection : $e');
    }
  }

  Future<void> _startAnalysis() async {
    if (_selectedFile == null) return;
    setState(() {
      _isAnalysing = true;
      _errorMessage = null;
    });

    try {
      // Upload vers Supabase Storage (optionnel — on ignore l'erreur)
      String fileUrl = '';
      try {
        final bucket = _selectedFileType == 'audio'
            ? 'audio'
            : _selectedFileType == 'video'
                ? 'videos'
                : 'partitions';
        fileUrl = await SupabaseService.uploadFile(
          file: _selectedFile!,
          bucket: bucket,
        );
      } catch (_) {}

      // 1. Essaie le backend Python
      // 2. Si indisponible → Claude (vision pour images, contextuel pour audio)
      // 3. Dernier recours → démo statique
      AnalysisResult result;
      try {
        if (_selectedFileType == 'pdf' || _selectedFileType == 'image') {
          result = await ApiService.analysePartition(
            file: _selectedFile!,
            instrumentId: _selectedInstrumentId,
          );
        } else {
          result = await ApiService.analyseFile(
            file: _selectedFile!,
            instrumentId: _selectedInstrumentId,
            fileType: _selectedFileType,
          );
        }
      } catch (_) {
        // Backend indisponible — essaie Claude
        try {
          result = await AiService.analyseFile(
            file: _selectedFile!,
            instrumentId: _selectedInstrumentId,
            fileType: _selectedFileType,
            fileName: _selectedFileName,
          );
        } catch (_) {
          result = AnalysisResult.demo();
        }
      }

      // Sauvegarde de la session
      try {
        await SupabaseService.saveSession(
          title: _selectedFileName ?? 'Analyse',
          instrumentId: _selectedInstrumentId,
          fileUrl: fileUrl,
          fileType: _selectedFileType,
          analysisResult: result.toJson(),
        );
      } catch (_) {}

      if (mounted) {
        setState(() => _isAnalysing = false);
        context.push('/analyser/resultat', extra: {
          ...result.toJson(),
          'fileName': _selectedFileName,
          'instrumentId': _selectedInstrumentId,
          'localFilePath': _selectedFile?.path,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalysing = false;
          _errorMessage = 'Analyse échouée : $e';
        });
      }
    }
  }
}

class _StepLabel extends StatelessWidget {
  final String number;
  final String label;
  const _StepLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: HarmonieColors.gold.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border:
                Border.all(color: HarmonieColors.gold.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: HarmonieColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontFamily: GoogleFonts.playfairDisplay().fontFamily,
            fontSize: 16,
            color: HarmonieColors.cream,
          ),
        ),
      ],
    );
  }
}

// ─── Audio Preview Player ─────────────────────────────────────────────────────

class _AudioPreviewPlayer extends StatefulWidget {
  final File file;
  const _AudioPreviewPlayer({required this.file});

  @override
  State<_AudioPreviewPlayer> createState() => _AudioPreviewPlayerState();
}

class _AudioPreviewPlayerState extends State<_AudioPreviewPlayer> {
  final _player = AudioPlayer();
  bool _loaded = false;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(_AudioPreviewPlayer old) {
    super.didUpdateWidget(old);
    if (old.file.path != widget.file.path) {
      _player.stop();
      _loaded = false;
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final dur = await _player.setFilePath(widget.file.path);
      if (mounted) setState(() { _duration = dur ?? Duration.zero; _loaded = true; });
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) => AudioService.formatDuration(d);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HarmonieColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HarmonieColors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.audiotrack_rounded,
                  color: HarmonieColors.gold, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Aperçu audio',
                style: TextStyle(
                  color: HarmonieColors.cream,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_loaded)
                Text(
                  _fmt(_duration),
                  style: const TextStyle(
                    color: HarmonieColors.muted,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snap) {
              final playing = snap.data?.playing ?? false;
              final proc = snap.data?.processingState;
              final loading = !_loaded || proc == ProcessingState.loading || proc == ProcessingState.buffering;
              return Row(
                children: [
                  GestureDetector(
                    onTap: loading ? null : () {
                      if (playing) { _player.pause(); } else { _player.play(); }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: HarmonieColors.gold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: loading
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          : Icon(
                              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 22,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final maxMs = _duration.inMilliseconds.toDouble();
                        final curMs = pos.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0);
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                activeTrackColor: HarmonieColors.gold,
                                inactiveTrackColor: HarmonieColors.surface,
                                thumbColor: HarmonieColors.gold,
                                overlayColor: HarmonieColors.gold.withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: curMs,
                                min: 0,
                                max: maxMs > 0 ? maxMs : 1,
                                onChanged: maxMs > 0
                                    ? (v) => _player.seek(Duration(milliseconds: v.toInt()))
                                    : null,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(pos),
                                    style: const TextStyle(color: HarmonieColors.muted, fontSize: 10)),
                                Text(_fmt(_duration),
                                    style: const TextStyle(color: HarmonieColors.muted, fontSize: 10)),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Image Preview ────────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  final File file;
  const _ImagePreview({required this.file});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(
        file,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 80,
          decoration: BoxDecoration(
            color: HarmonieColors.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Icon(Icons.broken_image_rounded,
                color: HarmonieColors.muted, size: 32),
          ),
        ),
      ),
    );
  }
}

// ─── File Info Preview (vidéo / PDF) ─────────────────────────────────────────

class _FileInfoPreview extends StatelessWidget {
  final File file;
  final String name;
  final String type;
  const _FileInfoPreview({required this.file, required this.name, required this.type});

  @override
  Widget build(BuildContext context) {
    final icon = type == 'video' ? Icons.videocam_rounded : Icons.picture_as_pdf_rounded;
    final label = type == 'video' ? 'Fichier vidéo' : 'Fichier PDF';
    final size = file.existsSync()
        ? AudioService.formatFileSize(file.lengthSync())
        : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HarmonieColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HarmonieColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: HarmonieColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: HarmonieColors.gold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: HarmonieColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    color: HarmonieColors.cream,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (size.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    size,
                    style: const TextStyle(
                      color: HarmonieColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: HarmonieColors.gold, size: 18),
        ],
      ),
    );
  }
}
