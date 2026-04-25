import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/music_result.dart';
import '../models/instrument.dart';
import '../services/api_service.dart';
import '../utils/note_converter.dart';
import '../widgets/harmonie_app_bar.dart';
import '../widgets/notation_toggle.dart';
import '../providers/settings_provider.dart';

class AnalyseResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const AnalyseResultScreen({super.key, required this.data});

  @override
  ConsumerState<AnalyseResultScreen> createState() => _AnalyseResultScreenState();
}

class _AnalyseResultScreenState extends ConsumerState<AnalyseResultScreen> {
  bool _isSaved = false;
  final _player = AudioPlayer();
  bool _playerReady = false;

  MusicResult? get _result => widget.data['result'] as MusicResult?;
  String get _key => _result?.audioFeatures?.keySignature ?? 'Inconnue';
  List<String> get _chords => _result?.harmony?.chordProgression ?? [];
  bool get _useFr => ref.watch(settingsProvider);

  @override
  void initState() {
    super.initState();
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
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result == null) {
      return Scaffold(
        backgroundColor: HarmonieColors.bg,
        appBar: const HarmonieAppBar(title: 'Erreur'),
        body: const Center(
          child: Text(
            'Erreur : Données d\'analyse manquantes',
            style: TextStyle(color: HarmonieColors.cream),
          ),
        ),
      );
    }

    final audio = result.audioFeatures;
    final instr = InstrumentCatalog.findById(
      widget.data['instrumentId'] as String? ?? 'guitar_acoustic',
    );

    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: HarmonieColors.bg,
            elevation: 0,
            leading: Center(
              child: GestureDetector(
                onTap: () => GoRouter.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HarmonieColors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: HarmonieColors.cream,
                    size: 16,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderBackground(audio, instr),
              title: Row(
                children: [
                  const SizedBox(width: 48), // Space for back button
                  Image.asset(
                    'assets/images/logo.png',
                    height: 18,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note_rounded, color: HarmonieColors.gold, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Harmonie',
                    style: GoogleFonts.playfairDisplay(
                      color: HarmonieColors.cream,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              const NotationToggle(),
              IconButton(
                icon: Icon(_isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                          color: HarmonieColors.gold),
                onPressed: () => setState(() => _isSaved = !_isSaved),
              ),
            ],
          ),

          // Avertissements API (transparence)
          if (result.hasWarnings)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: result.isPartial
                      ? Colors.orange.withOpacity(0.1)
                      : HarmonieColors.gold.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: result.isPartial
                        ? Colors.orange.withOpacity(0.3)
                        : HarmonieColors.gold.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          result.isPartial ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                          color: result.isPartial ? Colors.orange : HarmonieColors.gold,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          result.isPartial ? 'Analyse partielle' : 'Informations',
                          style: TextStyle(
                            color: result.isPartial ? Colors.orange : HarmonieColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...result.warnings.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $w',
                        style: const TextStyle(color: HarmonieColors.muted, fontSize: 11, height: 1.4),
                      ),
                    )),
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _RealAudioPlayer(player: _player, ready: _playerReady),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _MetricTile(label: 'Tempo', value: '${audio?.bpm.toInt() ?? "???"} BPM', icon: Icons.speed_rounded),
                  const SizedBox(width: 12),
                  _MetricTile(label: 'Tonalité', value: _key, icon: Icons.music_note_rounded),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _DashboardCard(
              title: 'Harmonie & Accords',
              subtitle: '${_chords.length} accords détectés',
              icon: Icons.grid_view_rounded,
              color: HarmonieColors.gold,
              onTap: () => GoRouter.of(context).push('/analyser/resultat/harmonie', extra: {
                'harmony': result.harmony,
                'audioPath': widget.data['audio_url'] ?? widget.data['localFilePath'],
              }),
              child: _buildChordsPreview(),
            ),
          ),

          SliverToBoxAdapter(
            child: _DashboardCard(
              title: 'Mélodie & Transcription',
              subtitle: '${result.notes.length} notes détectées',
              icon: Icons.piano_rounded,
              color: const Color(0xFF4CA9AF),
              onTap: () => GoRouter.of(context).push('/analyser/resultat/melodie', extra: {
                'notes': result.notes,
                'useFrench': _useFr,
                'audioPath': widget.data['audio_url'] ?? widget.data['localFilePath'],
              }),
              child: _buildMelodyPreview(result.notes),
            ),
          ),

          SliverToBoxAdapter(
            child: _DashboardCard(
              title: 'Partition & Export',
              subtitle: 'Prêt pour MuseScore',
              icon: Icons.description_outlined,
              color: const Color(0xFFE05555),
              onTap: () => GoRouter.of(context).push('/analyser/resultat/partition', extra: {
                'partitionUrl': result.sheetMusic?.pdfPath != null
                    ? '${ApiService.baseUrl}${result.sheetMusic!.pdfPath}'
                    : null,
                'svgContent': result.sheetMusic?.svgContent,
              }),
              child: _buildPartitionPreview(result.sheetMusic),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _AiSummaryCard(
                onAsk: (q) => GoRouter.of(context).push('/assistant', extra: {
                  'initialMessage': q,
                  'analysisContext': 'Tonalité: $_key, Accords: ${_chords.join(",")}',
                }),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground(AudioFeatures? audio, Instrument? instr) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [HarmonieColors.gold.withOpacity(0.15), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HarmonieColors.gold.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: HarmonieColors.gold.withOpacity(0.2)),
              ),
              child: Text(
                instr?.emoji ?? '🎸',
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChordsPreview() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _chords.take(4).map((c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: HarmonieColors.bg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HarmonieColors.gold.withOpacity(0.2)),
        ),
        child: Text(
          NoteConverter.convertChord(c, _useFr), 
          style: const TextStyle(color: HarmonieColors.cream, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      )).toList(),
    );
  }

  Widget _buildMelodyPreview(List<Note> notes) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: HarmonieColors.bg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _SimpleWavePainter(notes: notes.take(30).toList()),
        ),
      ),
    );
  }

  Widget _buildPartitionPreview(SheetMusicResult? sheet) {
    return Row(
      children: [
        const Icon(Icons.picture_as_pdf_rounded, color: HarmonieColors.muted, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            sheet != null ? 'Partition disponible (PDF/SVG/XML)' : 'Génération de la partition...',
            style: const TextStyle(color: HarmonieColors.muted, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.player.playing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            color: widget.ready ? HarmonieColors.gold : HarmonieColors.muted,
            onPressed: widget.ready ? () {
              if (isPlaying) widget.player.pause();
              else widget.player.play();
            } : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: widget.player.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final dur = widget.player.duration ?? Duration.zero;
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0,
                      backgroundColor: HarmonieColors.bg,
                      color: HarmonieColors.gold,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(pos), style: const TextStyle(color: HarmonieColors.muted, fontSize: 10)),
                        Text(_fmt(dur), style: const TextStyle(color: HarmonieColors.muted, fontSize: 10)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HarmonieColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x12FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: HarmonieColors.gold, size: 16),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: HarmonieColors.muted, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: HarmonieColors.cream, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HarmonieColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x12FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: HarmonieColors.cream, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(subtitle, style: const TextStyle(color: HarmonieColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: HarmonieColors.muted, size: 14),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  final Function(String) onAsk;
  const _AiSummaryCard({required this.onAsk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: HarmonieColors.surface2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HarmonieColors.gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: HarmonieColors.gold, size: 20),
              const SizedBox(width: 10),
              Text('Assistant Musicologue', style: TextStyle(
                color: HarmonieColors.cream, 
                fontWeight: FontWeight.bold,
                fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              )),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Posez-moi n\'importe quelle question sur ce morceau pour approfondir votre compréhension.',
            style: TextStyle(color: HarmonieColors.muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => onAsk('Peux-tu m\'analyser la structure de ce morceau ?'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HarmonieColors.gold,
              foregroundColor: HarmonieColors.bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Discuter avec l\'IA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SimpleWavePainter extends CustomPainter {
  final List<Note> notes;
  _SimpleWavePainter({required this.notes});

  @override
  void paint(Canvas canvas, Size size) {
    if (notes.isEmpty) return;
    final paint = Paint()
      ..color = HarmonieColors.gold.withOpacity(0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final step = size.width / notes.length;
    for (var i = 0; i < notes.length; i++) {
      final h = (notes[i].midi % 24) / 24 * size.height;
      canvas.drawLine(Offset(i * step, size.height), Offset(i * step, size.height - h), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
