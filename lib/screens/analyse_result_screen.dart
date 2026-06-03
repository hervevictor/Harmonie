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
import '../services/history_service.dart';
import '../utils/note_converter.dart';
import '../widgets/harmonie_app_bar.dart';
import '../widgets/notation_toggle.dart';
import '../providers/settings_provider.dart';
import '../widgets/synchronized_chord_grid.dart';
import '../widgets/chord_diagram_painter.dart';
import '../widgets/audio_waveform.dart';

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
  String _selectedView = 'grid'; // 'grid' or 'diagrams'
  String _instrumentMode = 'guitar'; // 'guitar', 'piano', 'ukulele'
  int _activeIndex = 0; // Ajout de la variable pour le Hero Diagram

  MusicResult? get _result => widget.data['result'] as MusicResult?;
  String get _key => _result?.audioFeatures?.keySignature ?? 'Inconnue';
  List<String> get _chords => _result?.harmony?.chordProgression ?? [];
  bool get _useFr => ref.watch(settingsProvider);
  String? get _audioPath =>
      widget.data['audio_url'] as String? ?? widget.data['localFilePath'] as String?;

  @override
  void initState() {
    super.initState();
    _initAudio();
    if (_result != null) {
      _isSaved = HistoryService.isSaved(_result!.jobId);
    }
    
    // Écouter la position pour mettre à jour l'accord actif globalement
    _player.positionStream.listen((pos) {
      if (!mounted) return;
      final res = _result;
      if (res == null) return;
      
      final sec = pos.inMilliseconds / 1000.0;
      final timeline = res.harmony?.chordsTimeline ?? [];
      final index = timeline.indexWhere((e) => sec >= e.start && sec <= e.end);
      
      if (index != -1 && index != _activeIndex) {
        setState(() => _activeIndex = index);
      }
    });
  }

  Future<void> _toggleSave() async {
    final result = _result;
    if (result == null) return;
    if (_isSaved) {
      await HistoryService.removeByJobId(result.jobId);
      setState(() => _isSaved = false);
    } else {
      final filename = (widget.data['localFilePath'] as String?)
              ?.split(RegExp(r'[/\\]'))
              .last ??
          'Enregistrement';
      await HistoryService.add(
        title: filename.replaceAll(RegExp(r'\.\w+$'), ''),
        instrumentId:
            widget.data['instrumentId'] as String? ?? 'guitar_acoustic',
        audioPath: _audioPath,
        result: result,
      );
      setState(() => _isSaved = true);
    }
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
    
    debugPrint('🛠️ Construction de AnalyseResultScreen');
    debugPrint('📦 Données reçues: ${widget.data.keys.toList()}');
    debugPrint('🎵 Resultat: ${result != null ? "Présent (JobId: ${result.jobId})" : "NULL"}');

    if (result == null) {
      return Scaffold(
        backgroundColor: HarmonieColors.bg,
        appBar: const HarmonieAppBar(title: 'Analyse'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, color: HarmonieColors.muted, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Aucune donnée d\'analyse trouvée',
                style: TextStyle(color: HarmonieColors.cream, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Veuillez relancer une analyse.',
                style: TextStyle(color: HarmonieColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(backgroundColor: HarmonieColors.gold),
                child: const Text('Retour', style: TextStyle(color: Colors.black)),
              ),
            ],
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
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20, 
          right: 20, 
          bottom: MediaQuery.of(context).padding.bottom + 10,
          top: 10
        ),
        decoration: BoxDecoration(
          color: HarmonieColors.bg,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: _RealAudioPlayer(
          player: _player,
          ready: _playerReady,
          timeline: result.harmony?.chordsTimeline ?? [],
          activeIndex: _activeIndex,
          useFrench: _useFr,
          instrumentId: _instrumentMode,
        ),
      ),
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
                    color: HarmonieColors.surface.withValues(alpha: 0.5),
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
                onPressed: _toggleSave,
              ),
            ],
          ),

          if (result.hasWarnings)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: result.isPartial
                      ? Colors.orange.withValues(alpha: 0.1)
                      : HarmonieColors.gold.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: result.isPartial
                        ? Colors.orange.withValues(alpha: 0.3)
                        : HarmonieColors.gold.withValues(alpha: 0.15),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  _MetricTile(label: 'Tempo', value: '${audio?.bpm.toInt() ?? "???"} BPM', icon: Icons.speed_rounded),
                  const SizedBox(width: 12),
                  _MetricTile(label: 'Tonalité', value: _key, icon: Icons.music_note_rounded),
                  const SizedBox(width: 12),
                  _MetricTile(
                    label: 'Mesure',
                    value: audio?.timeSignature ?? '4/4',
                    icon: Icons.hourglass_empty_rounded,
                  ),
                ],
              ),
            ),
          ),

          _buildHeroChordSection(result),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Visualisation & Progression',
                    style: TextStyle(
                      color: HarmonieColors.cream,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AudioWaveform(
                    player: _player,
                    audioFeatures: audio,
                    chordTimeline: result.harmony?.chordsTimeline ?? [],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _buildViewSwitcher(),
          ),

          SliverToBoxAdapter(
            child: _selectedView == 'grid' 
              ? _buildGridView(result) 
              : _buildDiagramsView(result),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _DashboardCard(
                title: 'Mélodie & Transcription',
                subtitle: '${result.notes.length} notes détectées',
                icon: Icons.piano_rounded,
                color: const Color(0xFF4CA9AF),
                onTap: () => GoRouter.of(context).push('/analyser/resultat/melodie', extra: {
                  'notes': result.notes,
                  'useFrench': _useFr,
                  'audioPath': _audioPath,
                }),
                child: _buildMelodyPreview(result.notes),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

  Widget _buildViewSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: HarmonieColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            _SwitcherButton(
              label: 'Grille d\'accords',
              icon: Icons.grid_on_rounded,
              isSelected: _selectedView == 'grid',
              onTap: () => setState(() => _selectedView = 'grid'),
            ),
            _SwitcherButton(
              label: 'Diagrammes',
              icon: Icons.auto_awesome_mosaic_rounded,
              isSelected: _selectedView == 'diagrams',
              onTap: () => setState(() => _selectedView = 'diagrams'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(MusicResult result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SynchronizedChordGrid(
        timeline: result.harmony?.chordsTimeline ?? [],
        player: _player,
        useFrench: _useFr,
        activeIndex: _activeIndex,
      ),
    );
  }

  Widget _buildHeroChordSection(MusicResult result) {
    final events = result.harmony?.chordsTimeline ?? [];
    if (events.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    final currentEvent = events[_activeIndex.clamp(0, events.length - 1)];
    final chordName = NoteConverter.convertChord(currentEvent.chord, _useFr);
    final instrumentId = _instrumentMode;

    final nextEvent = (_activeIndex + 1 < events.length) ? events[_activeIndex + 1] : null;
    final nextChordName = nextEvent != null ? NoteConverter.convertChord(nextEvent.chord, _useFr) : '';

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minHeight: 220),
        decoration: BoxDecoration(
          color: HarmonieColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: HarmonieColors.gold.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: HarmonieColors.gold.withOpacity(0.05),
              blurRadius: 40,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            // Côté Gauche : Nom de l'accord
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Accord actuel', style: TextStyle(color: HarmonieColors.muted, fontSize: 12, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    FittedBox(
                      child: Text(
                        chordName,
                        style: TextStyle(
                          fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: HarmonieColors.gold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (nextChordName.isNotEmpty) ...[
                      Flexible(
                        child: Text(
                          'Suivant : $nextChordName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: HarmonieColors.muted, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: HarmonieColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        instrumentId.toUpperCase(),
                        style: const TextStyle(color: HarmonieColors.gold, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Côté Droit : Diagramme
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: HarmonieColors.bg.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomPaint(
                  painter: ChordDiagramPainter(chord: currentEvent.chord, instrumentId: instrumentId),
                  size: Size.infinite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagramsView(MusicResult result) {
    return Column(
      children: [
        _buildInstrumentSelector(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 350,
            decoration: BoxDecoration(
              color: HarmonieColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: _SynchronizedDiagramGrid(
              timeline: result.harmony?.chordsTimeline ?? [],
              player: _player,
              instrumentId: _instrumentMode,
              useFrench: _useFr,
              activeIndex: _activeIndex,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstrumentSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _InstrumentIcon(
            icon: Icons.format_list_bulleted_rounded, // Guitare
            label: 'Guitare',
            isSelected: _instrumentMode == 'guitar',
            onTap: () => setState(() => _instrumentMode = 'guitar'),
          ),
          const SizedBox(width: 12),
          _InstrumentIcon(
            icon: Icons.keyboard_rounded, // Piano
            label: 'Piano',
            isSelected: _instrumentMode == 'piano',
            onTap: () => setState(() => _instrumentMode = 'piano'),
          ),
          const SizedBox(width: 12),
          _InstrumentIcon(
            icon: Icons.music_note_rounded, // Uku
            label: 'Uku',
            isSelected: _instrumentMode == 'ukulele',
            onTap: () => setState(() => _instrumentMode = 'ukulele'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground(AudioFeatures? audio, Instrument? instr) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [HarmonieColors.gold.withValues(alpha: 0.15), Colors.transparent],
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
                color: HarmonieColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: HarmonieColors.gold.withValues(alpha: 0.2)),
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

  Widget _buildMelodyPreview(List<Note> notes) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: HarmonieColors.bg.withValues(alpha: 0.3),
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
  final List<ChordEvent> timeline;
  final int activeIndex;
  final bool useFrench;
  final String instrumentId;

  const _RealAudioPlayer({
    required this.player,
    required this.ready,
    required this.timeline,
    required this.activeIndex,
    required this.useFrench,
    required this.instrumentId,
  });

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
    final timeline = widget.timeline;
    final activeIndex = widget.activeIndex;

    ChordEvent? currentEvent;
    ChordEvent? nextEvent;
    if (timeline.isNotEmpty && activeIndex >= 0 && activeIndex < timeline.length) {
      currentEvent = timeline[activeIndex];
      if (activeIndex + 1 < timeline.length) {
        nextEvent = timeline[activeIndex + 1];
      }
    }

    final currentChordDisplay = currentEvent != null 
        ? NoteConverter.convertChord(currentEvent.chord, widget.useFrench)
        : null;

    final nextChordDisplay = nextEvent != null 
        ? NoteConverter.convertChord(nextEvent.chord, widget.useFrench)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row accord actuel / suivant
          if (currentEvent != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: HarmonieColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: HarmonieColors.gold.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          currentChordDisplay!,
                          style: const TextStyle(
                            color: HarmonieColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 24,
                          width: 20,
                          child: CustomPaint(
                            painter: ChordDiagramPainter(
                              chord: currentEvent.chord,
                              instrumentId: widget.instrumentId,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (nextChordDisplay != null) ...[
                    Text(
                      'Suivant : $nextChordDisplay',
                      style: TextStyle(
                        color: HarmonieColors.muted.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: HarmonieColors.muted,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          // Slider et Temps
          StreamBuilder<Duration>(
            stream: widget.player.positionStream,
            builder: (context, snapshot) {
              final pos = snapshot.data ?? Duration.zero;
              final dur = widget.player.duration ?? Duration.zero;
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                      activeTrackColor: HarmonieColors.gold,
                      inactiveTrackColor: HarmonieColors.bg,
                      thumbColor: HarmonieColors.gold,
                    ),
                    child: Slider(
                      value: dur.inMilliseconds > 0 
                          ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0) 
                          : 0.0,
                      onChanged: (val) {
                        if (dur.inMilliseconds > 0) {
                          widget.player.seek(Duration(milliseconds: (dur.inMilliseconds * val).toInt()));
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
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
          const SizedBox(height: 8),

          // Boutons de contrôle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded),
                color: widget.ready ? HarmonieColors.cream : HarmonieColors.muted,
                iconSize: 26,
                onPressed: widget.ready ? () {
                  final currentPos = widget.player.position;
                  final target = currentPos - const Duration(seconds: 10);
                  widget.player.seek(target < Duration.zero ? Duration.zero : target);
                } : null,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded),
                color: widget.ready ? HarmonieColors.gold : HarmonieColors.muted,
                iconSize: 52,
                onPressed: widget.ready ? () async {
                  if (isPlaying) {
                    widget.player.pause();
                  } else {
                    if (widget.player.processingState == ProcessingState.completed) {
                      await widget.player.seek(Duration.zero);
                    }
                    widget.player.play();
                  }
                } : null,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded),
                color: widget.ready ? HarmonieColors.cream : HarmonieColors.muted,
                iconSize: 26,
                onPressed: widget.ready ? () {
                  final currentPos = widget.player.position;
                  final dur = widget.player.duration ?? Duration.zero;
                  final target = currentPos + const Duration(seconds: 10);
                  widget.player.seek(target > dur ? dur : target);
                } : null,
              ),
            ],
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
                      color: color.withValues(alpha: 0.1),
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
        border: Border.all(color: HarmonieColors.gold.withValues(alpha: 0.2)),
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
      ..color = HarmonieColors.gold.withValues(alpha: 0.3)
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

class _SwitcherButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SwitcherButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? HarmonieColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? HarmonieColors.bg : HarmonieColors.muted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? HarmonieColors.bg : HarmonieColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstrumentIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InstrumentIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? HarmonieColors.gold.withValues(alpha: 0.1) : HarmonieColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? HarmonieColors.gold : Colors.white.withValues(alpha: 0.05),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? HarmonieColors.gold : HarmonieColors.muted,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? HarmonieColors.gold : HarmonieColors.muted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _SynchronizedDiagramGrid extends StatefulWidget {
  final List<ChordEvent> timeline;
  final AudioPlayer player;
  final String instrumentId;
  final bool useFrench;
  final int activeIndex;

  const _SynchronizedDiagramGrid({
    required this.timeline,
    required this.player,
    required this.instrumentId,
    required this.useFrench,
    required this.activeIndex,
  });

  @override
  State<_SynchronizedDiagramGrid> createState() => _SynchronizedDiagramGridState();
}

class _SynchronizedDiagramGridState extends State<_SynchronizedDiagramGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.activeIndex != -1) {
        _scrollToIndex(widget.activeIndex);
      }
    });
  }

  @override
  void didUpdateWidget(_SynchronizedDiagramGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != oldWidget.activeIndex && widget.activeIndex != -1) {
      _scrollToIndex(widget.activeIndex);
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    final row = index ~/ 3; // 3 colonnes pour les diagrammes
    final offset = row * 120.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      offset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: widget.timeline.length,
      itemBuilder: (context, index) {
        final event = widget.timeline[index];
        final isActive = index == widget.activeIndex;
        final chordDisplay = NoteConverter.convertChord(event.chord, widget.useFrench);

        return GestureDetector(
          onTap: () => widget.player.seek(Duration(milliseconds: (event.start * 1000).toInt())),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isActive ? HarmonieColors.gold.withOpacity(0.1) : HarmonieColors.bg.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isActive ? HarmonieColors.gold : Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(chordDisplay, style: TextStyle(color: isActive ? HarmonieColors.cream : HarmonieColors.muted, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  width: 50,
                  child: CustomPaint(
                    painter: ChordDiagramPainter(
                      chord: event.chord,
                      instrumentId: widget.instrumentId,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
