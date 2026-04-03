// lib/screens/analyse_result_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../models/instrument.dart';
import '../services/preferences_service.dart';
import '../services/ai_service.dart';
import '../utils/note_converter.dart';

class AnalyseResultScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const AnalyseResultScreen({super.key, required this.data});

  @override
  State<AnalyseResultScreen> createState() => _AnalyseResultScreenState();
}

class _AnalyseResultScreenState extends State<AnalyseResultScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaved = false;

  // ── Audio player ──────────────────────────────────────────────────────────
  final _player = AudioPlayer();
  bool _playerReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initAudio();
  }

  Future<void> _initAudio() async {
    final audioUrl = widget.data['audio_url'] as String?;
    final localPath = widget.data['localFilePath'] as String?;
    final source = audioUrl ?? localPath;
    if (source == null) return;
    try {
      if (source.startsWith('http')) {
        await _player.setUrl(source);
      } else {
        await _player.setFilePath(source);
      }
      if (mounted) setState(() => _playerReady = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _player.dispose();
    super.dispose();
  }

  bool get _useFr => PreferencesService.useFrenchNotation;

  List<String> get _chords {
    final raw = (widget.data['chords'] as List?)?.cast<String>() ?? [];
    return NoteConverter.convertChords(raw, _useFr);
  }

  List<String> get _notes {
    final raw = (widget.data['notes'] as List?)?.cast<String>() ?? [];
    return NoteConverter.convertNotes(raw, _useFr);
  }

  String get _key {
    final raw = widget.data['key'] as String? ?? 'Am';
    return NoteConverter.convertChord(raw, _useFr);
  }

  String get _analysisContext {
    final chords = (widget.data['chords'] as List?)?.cast<String>() ?? [];
    final notes = (widget.data['notes'] as List?)?.cast<String>() ?? [];
    return AiService.buildAnalysisContext(
      fileName: widget.data['fileName'] as String? ?? '',
      instrumentId: widget.data['instrumentId'] as String? ?? '',
      key: widget.data['key'] as String? ?? '',
      bpm: widget.data['bpm'] as int? ?? 0,
      chords: chords,
      notes: notes,
    );
  }

  void _shareResults() {
    final text = '🎵 Analyse Harmonie — ${widget.data['fileName'] ?? ''}\n'
        'Tonalité : $_key  |  BPM : ${widget.data['bpm'] ?? 0}\n'
        'Accords : ${_chords.join(' → ')}\n'
        'Notes : ${_notes.join(', ')}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Résultats copiés dans le presse-papier'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instr = InstrumentCatalog.findById(
      widget.data['instrumentId'] as String? ?? 'guitar_acoustic',
    );
    final bpm = widget.data['bpm'] as int? ?? 120;

    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      appBar: AppBar(
        backgroundColor: HarmonieColors.bg,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: HarmonieColors.cream, size: 20),
        ),
        title: Text(
          widget.data['fileName'] as String? ?? 'Résultat',
          style: const TextStyle(
              color: HarmonieColors.cream,
              fontSize: 16,
              fontWeight: FontWeight.w400),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined,
                color: HarmonieColors.muted, size: 20),
            onPressed: _shareResults,
          ),
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isSaved ? HarmonieColors.gold : HarmonieColors.muted,
              size: 20,
            ),
            onPressed: () {
              setState(() => _isSaved = !_isSaved);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    _isSaved ? 'Sauvegardé dans vos favoris' : 'Retiré des favoris'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Méta-infos ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                _MetaBadge(
                    label: '${instr?.emoji ?? '🎸'} ${instr?.name ?? 'Guitare'}'),
                const SizedBox(width: 8),
                _MetaBadge(label: '🎵 $_key'),
                const SizedBox(width: 8),
                _MetaBadge(label: '♩ $bpm BPM'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Lecteur audio réel ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _RealAudioPlayer(player: _player, ready: _playerReady),
          ),

          const SizedBox(height: 12),

          // ── Bouton Ask AI ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/assistant',
                    extra: {'analysisContext': _analysisContext}),
                icon: const Icon(Icons.auto_awesome_rounded,
                    color: HarmonieColors.gold, size: 16),
                label: const Text(
                  'Poser une question à l\'IA sur cette analyse',
                  style:
                      TextStyle(color: HarmonieColors.gold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: HarmonieColors.gold, width: 0.8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Tabs ──────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: HarmonieColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x12FFFFFF)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: HarmonieColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: HarmonieColors.gold.withValues(alpha: 0.4)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: HarmonieColors.gold,
              unselectedLabelColor: HarmonieColors.muted,
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Accords'),
                Tab(text: 'Notes'),
                Tab(text: 'Partition'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Contenu onglets ───────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ChordsTab(chords: _chords),
                _NotesTab(notes: _notes, useFrench: _useFr),
                _PartitionTab(
                  partitionUrl: widget.data['partition_url'] as String?,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lecteur audio connecté à just_audio ─────────────────────────────────────

class _RealAudioPlayer extends StatefulWidget {
  final AudioPlayer player;
  final bool ready;
  const _RealAudioPlayer({required this.player, required this.ready});

  @override
  State<_RealAudioPlayer> createState() => _RealAudioPlayerState();
}

class _RealAudioPlayerState extends State<_RealAudioPlayer> {
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    // Rebuild quand l'état du lecteur change
    _stateSub = widget.player.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggle() async {
    if (!widget.ready) return;
    if (widget.player.playing) {
      await widget.player.pause();
    } else {
      // Si terminé, remettre au début
      if (widget.player.processingState == ProcessingState.completed) {
        await widget.player.seek(Duration.zero);
      }
      await widget.player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.player.playing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HarmonieColors.accent.withValues(alpha: 0.2),
            HarmonieColors.gold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: HarmonieColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Bouton play/pause
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.ready
                    ? HarmonieColors.gold
                    : HarmonieColors.surface2,
                shape: BoxShape.circle,
                boxShadow: widget.ready
                    ? [
                        BoxShadow(
                          color: HarmonieColors.gold.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.ready ? Colors.black : HarmonieColors.muted,
                size: 26,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Barre de progression + durée
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ready ? 'Audio' : 'Aucun audio disponible',
                  style: const TextStyle(
                    color: HarmonieColors.cream,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.ready)
                  StreamBuilder<Duration>(
                    stream: widget.player.positionStream,
                    builder: (context, posSnap) {
                      final position = posSnap.data ?? Duration.zero;
                      return StreamBuilder<Duration?>(
                        stream: widget.player.durationStream,
                        builder: (context, durSnap) {
                          final duration = durSnap.data ?? Duration.zero;
                          final progress = duration.inMilliseconds > 0
                              ? (position.inMilliseconds /
                                      duration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                              : 0.0;

                          return Column(
                            children: [
                              // Barre de progression cliquable
                              GestureDetector(
                                onTapDown: (details) {
                                  final box = context.findRenderObject()
                                      as RenderBox?;
                                  if (box == null) return;
                                  final x = details.localPosition.dx;
                                  final ratio =
                                      (x / box.size.width).clamp(0.0, 1.0);
                                  widget.player.seek(Duration(
                                    milliseconds:
                                        (duration.inMilliseconds * ratio)
                                            .round(),
                                  ));
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: HarmonieColors.gold
                                        .withValues(alpha: 0.2),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            HarmonieColors.gold),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_fmt(position),
                                      style: const TextStyle(
                                          color: HarmonieColors.gold,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500)),
                                  Text(_fmt(duration),
                                      style: const TextStyle(
                                          color: HarmonieColors.muted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w300)),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                else
                  // Waveform décorative quand pas d'audio
                  Row(
                    children: List.generate(40, (i) {
                      final h = (4 + (i % 7) * 4).toDouble();
                      return Container(
                        width: 3,
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 0.8),
                        decoration: BoxDecoration(
                          color: HarmonieColors.muted.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _MetaBadge extends StatelessWidget {
  final String label;
  const _MetaBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: HarmonieColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x12FFFFFF)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: HarmonieColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      );
}

class _ChordsTab extends StatelessWidget {
  final List<String> chords;
  const _ChordsTab({required this.chords});

  // Couleurs dynamiques par index (pas besoin de mapper les noms traduits)
  static const _palette = [
    HarmonieColors.accent,
    HarmonieColors.gold,
    HarmonieColors.success,
    HarmonieColors.accent2,
    HarmonieColors.error,
    HarmonieColors.gold2,
    HarmonieColors.teal,
    HarmonieColors.rose,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression d\'accords',
            style: TextStyle(
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              fontSize: 16,
              color: HarmonieColors.cream,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(chords.length, (i) {
              final color = _palette[i % _palette.length];
              return Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      chords[i],
                      style: TextStyle(
                        color: color,
                        fontSize: chords[i].length > 4 ? 14 : 20,
                        fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Accord',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Text(
            'Doigtés suggérés',
            style: TextStyle(
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              fontSize: 16,
              color: HarmonieColors.cream,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HarmonieColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x12FFFFFF)),
            ),
            child: const Center(
              child: Text(
                '🎸 Diagrammes de doigtés\n(intégration à venir)',
                style: TextStyle(color: HarmonieColors.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  final List<String> notes;
  final bool useFrench;
  const _NotesTab({required this.notes, required this.useFrench});

  // Couleur basée sur la note de base (Do/C, Ré/D, etc.)
  static const _noteColorMap = {
    // Anglais
    'C': Color(0xFFE05555),
    'D': Color(0xFFE8A84C),
    'E': Color(0xFFE8C97A),
    'F': Color(0xFF4CAF82),
    'G': Color(0xFF4CA9AF),
    'A': Color(0xFF7C5CBF),
    'B': Color(0xFFA87DE0),
    // Français
    'Do': Color(0xFFE05555),
    'Ré': Color(0xFFE8A84C),
    'Mi': Color(0xFFE8C97A),
    'Fa': Color(0xFF4CAF82),
    'Sol': Color(0xFF4CA9AF),
    'La': Color(0xFF7C5CBF),
    'Si': Color(0xFFA87DE0),
  };

  Color _colorFor(String note) {
    // Extraire la base (ex: "Do4" → "Do", "A#3" → "A", "Sol" → "Sol")
    final match = RegExp(r'^([A-Za-zÉéè]+)').firstMatch(note);
    final base = match?.group(1) ?? note;
    return _noteColorMap[base] ?? HarmonieColors.muted;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Séquence de notes',
            style: TextStyle(
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              fontSize: 16,
              color: HarmonieColors.cream,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            useFrench
                ? 'Notation française (Do, Ré, Mi…)'
                : 'English notation (C, D, E…)',
            style: const TextStyle(
              color: HarmonieColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(notes.length, (i) {
              final color = _colorFor(notes[i]);
              return Container(
                constraints: const BoxConstraints(minWidth: 52),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Center(
                  child: Text(
                    notes[i],
                    style: TextStyle(
                      color: color,
                      fontSize: notes[i].length > 4 ? 11 : 15,
                      fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PartitionTab extends StatefulWidget {
  final String? partitionUrl;
  const _PartitionTab({this.partitionUrl});

  @override
  State<_PartitionTab> createState() => _PartitionTabState();
}

class _PartitionTabState extends State<_PartitionTab> {
  bool _downloading = false;
  double _progress = 0;
  String? _savedPath;
  String? _error;

  Future<void> _download() async {
    if (widget.partitionUrl == null) return;
    setState(() { _downloading = true; _progress = 0; _error = null; });
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'partition_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savePath = '${dir.path}/$fileName';
      await Dio().download(
        widget.partitionUrl!,
        savePath,
        onReceiveProgress: (recv, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = recv / total);
          }
        },
      );
      if (mounted) setState(() { _downloading = false; _savedPath = savePath; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Téléchargé : $fileName'),
            backgroundColor: HarmonieColors.surface2,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _downloading = false; _error = 'Échec : $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = widget.partitionUrl != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // ── Preview image ────────────────────────────────────────────────
          if (hasUrl)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                widget.partitionUrl!,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                loadingBuilder: (_, child, prog) {
                  if (prog == null) return child;
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: HarmonieColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: HarmonieColors.gold, strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
            )
          else
            _placeholder(),

          const SizedBox(height: 20),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  style: const TextStyle(
                      color: HarmonieColors.error, fontSize: 12)),
            ),

          // ── Download button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (!hasUrl || _downloading || _savedPath != null)
                  ? null
                  : _download,
              icon: _downloading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        strokeWidth: 2,
                        color: HarmonieColors.gold,
                      ),
                    )
                  : Icon(
                      _savedPath != null
                          ? Icons.check_circle_rounded
                          : Icons.download_rounded,
                      color: HarmonieColors.gold,
                      size: 16,
                    ),
              label: Text(
                _savedPath != null
                    ? 'Téléchargé ✓'
                    : _downloading
                        ? 'Téléchargement…'
                        : 'Télécharger PDF',
                style: const TextStyle(
                    color: HarmonieColors.gold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: HarmonieColors.gold, width: 0.8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          if (!hasUrl) ...[
            const SizedBox(height: 12),
            const Text(
              'La partition sera disponible après analyse\npar le backend.',
              style: TextStyle(
                  color: HarmonieColors.muted, fontSize: 11, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        children: [
          const Text('🎼', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Partition générée',
            style: TextStyle(
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              fontSize: 18,
              color: HarmonieColors.cream,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'La partition au format image et PDF\nsera générée ici après analyse.',
            style: TextStyle(
                color: HarmonieColors.muted, fontSize: 12, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
