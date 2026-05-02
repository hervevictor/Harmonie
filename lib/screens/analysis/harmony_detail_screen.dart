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

    if (index != _activeChordIndex) {
      _activeChordIndex = index;
      if (index != -1) _scrollToChord(index);
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
          if (_activeChordIndex != -1)
            _buildChordTeachingPanel(),
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
      constraints: const BoxConstraints(minHeight: 120),
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            activeChord != null
                              ? NoteConverter.convertChord(activeChord.chord, ref.watch(settingsProvider))
                              : NoteConverter.convertNote(widget.harmony.keySignature, ref.watch(settingsProvider)),
                            style: GoogleFonts.playfairDisplay(
                              color: activeChord != null ? Colors.black : HarmonieColors.cream,
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                            ),
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
    if (widget.audioPath == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: HarmonieColors.surface2,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: const Center(
          child: Text(
            'Aucun audio disponible',
            style: TextStyle(color: HarmonieColors.muted, fontSize: 13),
          ),
        ),
      );
    }
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
                    onTap: () async {
                      if (playing) {
                        _player.pause();
                      } else {
                        if (_player.duration == null) {
                          await _initAudio();
                        }
                        if (_player.processingState == ProcessingState.completed) {
                          await _player.seek(Duration.zero);
                        }
                        _player.play();
                      }
                    },
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

  Widget _buildChordTeachingPanel() {
    final event = widget.harmony.chordsTimeline[_activeChordIndex];
    final rawChord = event.chord;
    final info = _ChordDatabase.get(rawChord);
    final useFr = ref.watch(settingsProvider);
    final displayName = NoteConverter.convertChord(rawChord, useFr);
    final total = _player.duration?.inMilliseconds ?? 1;
    final pct = total > 0
        ? ((event.start * 1000) / total * 100).clamp(0.0, 100.0).toStringAsFixed(0)
        : '—';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(rawChord),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HarmonieColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HarmonieColors.gold.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diagramme de doigté
            _FretboardWidget(frets: info?.frets),
            const SizedBox(width: 16),
            // Infos pédagogiques
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.playfairDisplay(
                      color: HarmonieColors.gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info?.type ?? _ChordDatabase.guessType(rawChord),
                    style: const TextStyle(
                      color: HarmonieColors.cream,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    info?.tip ?? 'Jouez cet accord à ~$pct% de la chanson.',
                    style: const TextStyle(
                      color: HarmonieColors.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: HarmonieColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: HarmonieColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '⏱ À ~$pct% de la chanson',
                      style: const TextStyle(
                        color: HarmonieColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        border: Border.all(color: HarmonieColors.gold.withValues(alpha: 0.1)),
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
            'Pour cette progression en $currentKey, privilégiez la gamme de ${currentKey.replaceAll('m', '')} Pentatonique pour un son plus "bluesy" ou $currentKey Ionien pour un son plus classique.',
            style: const TextStyle(color: HarmonieColors.muted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Données d'accord ─────────────────────────────────────────────────────────

class _ChordInfo {
  final List<int> frets; // [E A D G B e] — -1=muet, 0=open, 1-5=case
  final String type;
  final String tip;
  const _ChordInfo({required this.frets, required this.type, required this.tip});
}

class _ChordDatabase {
  static const Map<String, _ChordInfo> _data = {
    // Majeurs
    'C':    _ChordInfo(frets: [-1,3,2,0,1,0], type: 'Accord Majeur — son joyeux',        tip: 'Posez l\'annulaire sur le La (3ème case), majeur sur le Ré, index sur le Si.'),
    'D':    _ChordInfo(frets: [-1,-1,0,2,3,2], type: 'Accord Majeur — son brillant',      tip: 'Formez un triangle avec index, majeur et annulaire sur les 3 premières cordes aiguës.'),
    'E':    _ChordInfo(frets: [0,2,2,1,0,0],  type: 'Accord Majeur — puissant à vide',   tip: 'Index sur Sol 1ère case, majeur+annulaire sur La-Ré 2ème case. Cordes Mi ouvertes.'),
    'F':    _ChordInfo(frets: [1,1,2,3,3,1],  type: 'Accord Majeur — barré 1ère case',   tip: 'Barrez toutes les cordes à la 1ère case avec l\'index, puis formez un E décalé.'),
    'G':    _ChordInfo(frets: [3,2,0,0,0,3],  type: 'Accord Majeur — son plein',         tip: 'Majeur sur La 2ème case, annulaire sur Mi grave 3ème, auriculaire sur Mi aigu 3ème.'),
    'A':    _ChordInfo(frets: [-1,0,2,2,2,0], type: 'Accord Majeur — cordes à vide',     tip: 'Index, majeur, annulaire sur Ré-Sol-Si 2ème case. Laissez Mi aigu et La ouverts.'),
    'B':    _ChordInfo(frets: [-1,2,4,4,4,2], type: 'Accord Majeur — barré 2ème case',   tip: 'Barrez les 5 cordes aiguës à la 2ème case, puis posez 3 doigts sur la 4ème case.'),
    // Mineurs
    'Am':   _ChordInfo(frets: [-1,0,2,2,1,0], type: 'Accord Mineur — son mélancolique',  tip: 'Majeur sur Ré 2ème case, annulaire sur Sol 2ème, index sur Si 1ère case.'),
    'Bm':   _ChordInfo(frets: [-1,2,4,4,3,2], type: 'Accord Mineur — barré 2ème case',   tip: 'Barrez les 5 cordes aiguës à la 2ème case, puis ajoutez les doigts sur la 3ème-4ème.'),
    'Cm':   _ChordInfo(frets: [-1,3,5,5,4,3], type: 'Accord Mineur — barré 3ème case',   tip: 'Barré complet 3ème case, structure identique à Am mais déplacée.'),
    'Dm':   _ChordInfo(frets: [-1,-1,0,2,3,1], type: 'Accord Mineur — doux et triste',   tip: 'Index sur Mi aigu 1ère case, majeur sur Sol 2ème, annulaire sur Si 3ème.'),
    'Em':   _ChordInfo(frets: [0,2,2,0,0,0],  type: 'Accord Mineur — le plus simple',   tip: 'Majeur+annulaire sur La-Ré 2ème case. Toutes les autres cordes à vide.'),
    'Fm':   _ChordInfo(frets: [1,3,3,1,1,1],  type: 'Accord Mineur — barré 1ère case',   tip: 'Barré 1ère case, majeur+annulaire sur La-Ré 3ème case.'),
    'Gm':   _ChordInfo(frets: [3,5,5,3,3,3],  type: 'Accord Mineur — barré 3ème case',   tip: 'Barré 3ème case, structure Em déplacée de 3 cases.'),
    // Septièmes de dominante
    'G7':   _ChordInfo(frets: [3,2,0,0,0,1],  type: 'Accord 7e — tension blues',         tip: 'Comme G majeur mais auriculaire remplacé par index sur Mi aigu 1ère case.'),
    'A7':   _ChordInfo(frets: [-1,0,2,0,2,0], type: 'Accord 7e — son country',           tip: 'Index sur Si 2ème case, annulaire sur Ré 2ème. Sol et Mi à vide.'),
    'B7':   _ChordInfo(frets: [-1,2,1,2,0,2], type: 'Accord 7e — transition forte',      tip: 'Doigts alternés sur La-Ré-Mi aigu 2ème case, majeur sur Sol 1ère case.'),
    'C7':   _ChordInfo(frets: [-1,3,2,3,1,0], type: 'Accord 7e — son jazzy',             tip: 'Comme C majeur + annulaire sur Sol 3ème case.'),
    'D7':   _ChordInfo(frets: [-1,-1,0,2,1,2], type: 'Accord 7e — résolution forte',     tip: 'Index sur Si 1ère case, majeur sur Sol+Mi aigu 2ème case.'),
    'E7':   _ChordInfo(frets: [0,2,0,1,0,0],  type: 'Accord 7e — blues classique',       tip: 'Comme Em mais index seulement sur Sol 1ère case. Sol 4ème corde ouverte.'),
    'F7':   _ChordInfo(frets: [1,1,2,1,1,1],  type: 'Accord 7e — barré 1ère case',       tip: 'Barré 1ère case avec index. Majeur sur Ré 2ème case seulement.'),
    // Mineurs septièmes
    'Am7':  _ChordInfo(frets: [-1,0,2,0,1,0], type: 'Accord m7 — jazz doux',             tip: 'Juste l\'index sur Si 1ère case. Am avec le Sol à vide pour l\'effet 7e.'),
    'Bm7':  _ChordInfo(frets: [-1,2,4,2,3,2], type: 'Accord m7 — sophistiqué',           tip: 'Barré 2ème case, annulaire sur Sol 4ème case.'),
    'Dm7':  _ChordInfo(frets: [-1,-1,0,2,1,1], type: 'Accord m7 — doux et riche',        tip: 'Index barre Mi aigu+Si 1ère case, majeur sur Sol 2ème, annulaire sur Ré 2ème... non, Sol 2nd.'),
    'Em7':  _ChordInfo(frets: [0,2,2,0,3,0],  type: 'Accord m7 — ouvert et aérien',     tip: 'Comme Em + annulaire sur Si 3ème case. Son riche et ouvert.'),
    // Majeurs septièmes
    'Cmaj7':_ChordInfo(frets: [-1,3,2,0,0,0], type: 'Accord maj7 — son rêveur',          tip: 'Comme C mais sans l\'index : laissez Si et Mi à vide pour l\'effet maj7.'),
    'Gmaj7':_ChordInfo(frets: [3,2,0,0,0,2],  type: 'Accord maj7 — lumineux',            tip: 'Comme G mais index sur Mi aigu 2ème case au lieu de 3ème.'),
    'Amaj7':_ChordInfo(frets: [-1,0,2,1,2,0], type: 'Accord maj7 — brillant',            tip: 'Index sur Sol 1ère case, majeur sur Ré 2ème, annulaire sur Si 2ème.'),
    'Fmaj7':_ChordInfo(frets: [-1,-1,3,2,1,0], type: 'Accord maj7 — jazz lumineux',      tip: 'Annulaire sur Ré 3ème, majeur sur Sol 2ème, index sur Si 1ère. Mi aigu ouvert.'),
    // Power chords
    'C5':   _ChordInfo(frets: [-1,3,5,-1,-1,-1], type: 'Power chord — son percutant',    tip: 'Index sur La 3ème case, annulaire sur Ré 5ème case. Son rock/punk direct.'),
    'D5':   _ChordInfo(frets: [-1,-1,0,2,-1,-1], type: 'Power chord — puissant',         tip: 'Ré à vide + index sur Sol 2ème case. Simple et efficace.'),
    'E5':   _ChordInfo(frets: [0,2,-1,-1,-1,-1], type: 'Power chord — grave et fort',    tip: 'Mi grave à vide + index sur La 2ème case seulement.'),
    'G5':   _ChordInfo(frets: [3,5,-1,-1,-1,-1], type: 'Power chord — grave',            tip: 'Annulaire sur Mi grave 3ème case, auriculaire sur La 5ème case.'),
    'A5':   _ChordInfo(frets: [-1,0,2,-1,-1,-1], type: 'Power chord — medium',           tip: 'La à vide + index sur Ré 2ème case. Base de nombreux riffs.'),
  };

  static _ChordInfo? get(String rawChord) {
    final key = _normalize(rawChord);
    return _data[key];
  }

  static String _normalize(String chord) {
    return chord
      .replaceAll('maj', 'maj')
      .replaceAll('min', 'm')
      .replaceAll('M7', 'maj7')
      .trim();
  }

  static String guessType(String chord) {
    final c = chord.toLowerCase();
    if (c.contains('maj7')) return 'Accord Majeur Septième — doux et jazzy';
    if (c.contains('m7') || c.contains('min7')) return 'Accord Mineur Septième — mélancolique et sophistiqué';
    if (c.contains('7')) return 'Accord de Dominante — tendu et bluesy';
    if (c.contains('dim')) return 'Accord Diminué — son sombre et instable';
    if (c.contains('aug')) return 'Accord Augmenté — son mystérieux';
    if (c.contains('sus')) return 'Accord Suspendu — son ouvert et flottant';
    if (c.contains('5')) return 'Power Chord — son direct et percutant';
    if (c.contains('m') || c.contains('min')) return 'Accord Mineur — son mélancolique';
    return 'Accord Majeur — son joyeux et stable';
  }
}

// ─── Diagramme de doigté guitare ─────────────────────────────────────────────

class _FretboardWidget extends StatelessWidget {
  final List<int>? frets; // [E A D G B e] — -1=muet, 0=open, 1-5=case

  const _FretboardWidget({this.frets});

  @override
  Widget build(BuildContext context) {
    if (frets == null) {
      return Container(
        width: 72,
        height: 90,
        alignment: Alignment.center,
        child: const Icon(Icons.music_note_rounded, color: HarmonieColors.gold, size: 36),
      );
    }

    final minFret = frets!.where((f) => f > 0).fold(10, (a, b) => a < b ? a : b);
    final startFret = minFret == 10 ? 1 : minFret;

    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateurs cordes ouvertes / muettes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: frets!.map((f) => SizedBox(
              width: 10,
              child: Text(
                f == -1 ? 'x' : f == 0 ? 'o' : '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: f == -1 ? HarmonieColors.muted : HarmonieColors.gold,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 2),
          // Grille 5 frettes × 6 cordes
          ...List.generate(5, (fretIdx) {
            final fretNum = startFret + fretIdx;
            return Container(
              height: 14,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: fretIdx == 0 && startFret == 1
                        ? HarmonieColors.cream
                        : HarmonieColors.muted.withValues(alpha: 0.3),
                    width: fretIdx == 0 && startFret == 1 ? 2 : 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (strIdx) {
                  final hasDot = frets![strIdx] == fretNum;
                  return SizedBox(
                    width: 10,
                    child: Center(
                      child: hasDot
                          ? Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: HarmonieColors.gold,
                                shape: BoxShape.circle,
                              ),
                            )
                          : Container(
                              width: 1,
                              height: 14,
                              color: HarmonieColors.muted.withValues(alpha: 0.2),
                            ),
                    ),
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 4),
          if (startFret > 1)
            Text(
              '${startFret}fr',
              style: const TextStyle(color: HarmonieColors.muted, fontSize: 9),
            ),
        ],
      ),
    );
  }
}
