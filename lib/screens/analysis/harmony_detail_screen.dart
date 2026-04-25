import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/music_result.dart';
import '../../theme/app_theme.dart';
import '../../utils/note_converter.dart';
import '../../widgets/harmonie_app_bar.dart';
import '../../widgets/notation_toggle.dart';
import '../../providers/settings_provider.dart';
import 'dart:async';

class HarmonyDetailScreen extends ConsumerStatefulWidget {
  final HarmonyResult harmony;
  final String? audioPath;

  const HarmonyDetailScreen({
    super.key,
    required this.harmony,
    this.audioPath,
  });

  @override
  ConsumerState<HarmonyDetailScreen> createState() => _HarmonyDetailScreenState();
}

class _HarmonyDetailScreenState extends ConsumerState<HarmonyDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _positionSubscription;
  double _currentPosition = 0.0;
  int _activeChordIndex = -1;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _setupSync();
  }

  Future<void> _initAudio() async {
    if (widget.audioPath == null) return;
    try {
      if (widget.audioPath!.startsWith('http')) {
        await _player.setUrl(widget.audioPath!);
      } else {
        await _player.setFilePath(widget.audioPath!);
      }
    } catch (e) {
      debugPrint('Error loading audio in HarmonyDetail: $e');
    }
  }

  void _setupSync() {
    _positionSubscription = _player.positionStream.listen((position) {
      final seconds = position.inMilliseconds / 1000.0;
      setState(() {
        _currentPosition = seconds;
        _updateActiveChord(seconds);
      });
    });
  }

  void _updateActiveChord(double seconds) {
    int index = -1;
    for (int i = 0; i < widget.harmony.chordsTimeline.length; i++) {
      final event = widget.harmony.chordsTimeline[i];
      if (seconds >= event.start && seconds <= event.end) {
        index = i;
        break;
      }
    }

    if (index != _activeChordIndex && index != -1) {
      _activeChordIndex = index;
      _scrollToChord(index);
    }
  }

  void _scrollToChord(int index) {
    if (!_scrollController.hasClients) return;
    // Estimation de la position : chaque carte fait environ 120px de large
    // On veut centrer l'accord actif
    final targetOffset = (index * 140.0) - (MediaQuery.of(context).size.width / 2) + 70;
    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _player.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      appBar: HarmonieAppBar(
        title: 'Analyse Harmonique',
        actions: [
          const NotationToggle(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildActiveChordBanner(),
          Expanded(
            child: widget.harmony.chordsTimeline.isEmpty 
              ? _buildStaticChords()
              : _buildSynchronizedChords(),
          ),
          _buildAudioControls(),
        ],
      ),
    );
  }

  Widget _buildActiveChordBanner() {
    final activeChord = _activeChordIndex != -1 ? widget.harmony.chordsTimeline[_activeChordIndex] : null;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            activeChord != null ? HarmonieColors.gold : HarmonieColors.surface,
            activeChord != null ? HarmonieColors.gold.withOpacity(0.8) : HarmonieColors.surface.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (activeChord != null ? HarmonieColors.gold : Colors.black).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Icon(
                Icons.album_rounded,
                size: 150,
                color: (activeChord != null ? Colors.white : HarmonieColors.gold).withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeChord != null ? 'Accord Actuel' : 'Tonalité',
                          style: TextStyle(
                            color: activeChord != null ? Colors.black54 : HarmonieColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeChord != null 
                            ? NoteConverter.convertChord(activeChord.chord, ref.watch(settingsProvider)) 
                            : NoteConverter.convertNote(widget.harmony.keySignature, ref.watch(settingsProvider)),
                          style: GoogleFonts.playfairDisplay(
                            color: activeChord != null ? Colors.black : HarmonieColors.cream,
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activeChord == null) _buildConfidenceIndicator(),
                  if (activeChord != null)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          NoteConverter.getChordDegree(activeChord.chord, widget.harmony.keySignature),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Degré',
                          style: TextStyle(color: Colors.black38, fontSize: 10),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            value: widget.harmony.keyConfidence,
            backgroundColor: HarmonieColors.gold.withOpacity(0.1),
            color: HarmonieColors.gold,
            strokeWidth: 4,
          ),
        ),
        Text(
          '${(widget.harmony.keyConfidence * 100).toInt()}%',
          style: const TextStyle(color: HarmonieColors.gold, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSynchronizedChords() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Accords en temps réel',
                  style: GoogleFonts.playfairDisplay(
                    color: HarmonieColors.cream,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.sync_rounded, color: HarmonieColors.gold, size: 20),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 100),
              itemCount: widget.harmony.chordsTimeline.length,
              itemBuilder: (context, index) {
                final event = widget.harmony.chordsTimeline[index];
                final isActive = _activeChordIndex == index;
                
                return GestureDetector(
                  onTap: () => _player.seek(Duration(milliseconds: (event.start * 1000).toInt())),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
                    decoration: BoxDecoration(
                      color: isActive ? HarmonieColors.gold : HarmonieColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? Colors.white : HarmonieColors.gold.withOpacity(0.3),
                        width: isActive ? 2.5 : 1,
                      ),
                      boxShadow: isActive ? [
                        BoxShadow(
                          color: HarmonieColors.gold.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          NoteConverter.convertChord(event.chord, ref.watch(settingsProvider)),
                          style: TextStyle(
                            color: isActive ? Colors.black : HarmonieColors.gold,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NoteConverter.getChordDegree(event.chord, widget.harmony.keySignature),
                          style: TextStyle(
                            color: isActive ? Colors.black54 : HarmonieColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _TheorySection(
            chords: widget.harmony.chordProgression, 
            currentKey: widget.harmony.keySignature
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStaticChords() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.harmony.chordProgression.length,
      itemBuilder: (context, i) => _StaticChordCard(
        chord: NoteConverter.convertChord(widget.harmony.chordProgression[i], ref.watch(settingsProvider)),
        degree: NoteConverter.getChordDegree(widget.harmony.chordProgression[i], widget.harmony.keySignature),
        index: i + 1,
      ),
    );
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: HarmonieColors.surface2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _player.duration ?? Duration.zero;
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbColor: HarmonieColors.gold,
                      activeTrackColor: HarmonieColors.gold,
                      inactiveTrackColor: Colors.white10,
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
                      max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                      onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: const TextStyle(color: HarmonieColors.muted, fontSize: 12)),
                        Text(_formatDuration(duration), style: const TextStyle(color: HarmonieColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded, color: HarmonieColors.cream),
                onPressed: () => _player.seek(_player.position - const Duration(seconds: 10)),
              ),
              const SizedBox(width: 20),
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return GestureDetector(
                    onTap: playing ? _player.pause : _player.play,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: HarmonieColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded, color: HarmonieColors.cream),
                onPressed: () => _player.seek(_player.position + const Duration(seconds: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _StaticChordCard extends StatelessWidget {
  final String chord;
  final String degree;
  final int index;

  const _StaticChordCard({required this.chord, required this.degree, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HarmonieColors.gold.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(chord, style: const TextStyle(color: HarmonieColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(degree, style: const TextStyle(color: HarmonieColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TheorySection extends StatelessWidget {
  final List<String> chords;
  final String currentKey;

  const _TheorySection({required this.chords, required this.currentKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HarmonieColors.surface2,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: HarmonieColors.gold, size: 20),
              const SizedBox(width: 10),
              Text(
                'Conseils d\'improvisation',
                style: GoogleFonts.playfairDisplay(
                  color: HarmonieColors.cream,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pour cette progression en $currentKey, privilégiez la gamme de ${currentKey.replaceAll('m', '')} Pentatonique pour un son plus "bluesy" ou ${currentKey} Ionien pour un son plus classique.',
            style: const TextStyle(color: HarmonieColors.muted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
