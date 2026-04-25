import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/music_result.dart';
import '../../theme/app_theme.dart';
import '../../utils/note_converter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/harmonie_app_bar.dart';
import '../../widgets/notation_toggle.dart';
import '../../providers/settings_provider.dart';
import 'dart:async';

class MelodyDetailScreen extends ConsumerStatefulWidget {
  final List<Note> notes;
  final bool useFrench;
  final String? audioPath;

  const MelodyDetailScreen({
    super.key,
    required this.notes,
    required this.useFrench,
    this.audioPath,
  });

  @override
  ConsumerState<MelodyDetailScreen> createState() => _MelodyDetailScreenState();
}

class _MelodyDetailScreenState extends ConsumerState<MelodyDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  final TransformationController _transformationController = TransformationController();
  final ScrollController _listScrollController = ScrollController();
  bool _showPianoRoll = true;
  double _currentPosition = 0.0;
  StreamSubscription? _positionSubscription;
  int _activeNoteIndex = -1;

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
      debugPrint('Error loading audio in MelodyDetail: $e');
    }
  }

  void _setupSync() {
    _positionSubscription = _player.positionStream.listen((position) {
      final seconds = position.inMilliseconds / 1000.0;
      if (!mounted) return;
      
      // Trouver l'index de la note active
      int newActiveIndex = -1;
      for (int i = 0; i < widget.notes.length; i++) {
        if (seconds >= widget.notes[i].onset && seconds <= (widget.notes[i].onset + widget.notes[i].duration)) {
          newActiveIndex = i;
          break;
        }
      }

      setState(() {
        _currentPosition = seconds;
        _activeNoteIndex = newActiveIndex;
      });

      if (_player.playing) {
        if (_showPianoRoll) {
          _updatePianoRollScroll(seconds);
        } else if (_activeNoteIndex != -1) {
          _updateListScroll(_activeNoteIndex);
        }
      }
    });
  }

  void _updatePianoRollScroll(double seconds) {
    final playheadX = seconds * 100;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = playheadX - (screenWidth / 2) + 60;
    
    final currentMatrix = _transformationController.value;
    final scale = currentMatrix.getMaxScaleOnAxis();
    
    _transformationController.value = Matrix4.identity()
      ..scale(scale)
      ..translate(-targetX.clamp(0.0, double.infinity));
  }

  void _updateListScroll(int index) {
    if (!_listScrollController.hasClients) return;
    // Hauteur moyenne d'un item (8px margin + 52px content approx = 60px)
    const itemHeight = 60.0;
    final targetOffset = index * itemHeight;
    
    _listScrollController.animateTo(
      targetOffset.clamp(0.0, _listScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _player.dispose();
    _transformationController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      appBar: HarmonieAppBar(
        title: 'Analyse Mélodique',
        actions: [
          const NotationToggle(),
          IconButton(
            icon: Icon(
              _showPianoRoll ? Icons.list_rounded : Icons.piano_rounded,
              color: HarmonieColors.gold,
            ),
            onPressed: () => setState(() => _showPianoRoll = !_showPianoRoll),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildActiveNoteBanner(),
          const SizedBox(height: 16),
          Expanded(
            child: widget.notes.isEmpty 
              ? const Center(child: Text('Aucune note détectée', style: TextStyle(color: HarmonieColors.muted)))
              : _showPianoRoll 
                  ? _IntegratedPianoRoll(
                      notes: widget.notes, 
                      currentPosition: _currentPosition,
                      transformationController: _transformationController,
                      useFrench: ref.watch(settingsProvider),
                    )
                  : _NotesDetailList(
                      notes: widget.notes, 
                      useFrench: ref.watch(settingsProvider), 
                      currentPosition: _currentPosition,
                      scrollController: _listScrollController,
                    ),
          ),
          _buildAudioControls(),
        ],
      ),
    );
  }

  Widget _buildActiveNoteBanner() {
    final activeNote = _activeNoteIndex != -1 ? widget.notes[_activeNoteIndex] : null;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HarmonieColors.gold,
            HarmonieColors.gold.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: HarmonieColors.gold.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.music_note_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  activeNote != null 
                    ? NoteConverter.convertNote(activeNote.note, ref.watch(settingsProvider))
                    : '--',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.black,
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (activeNote != null)
                  Text(
                    'Midi: ${activeNote.midi} | Début: ${activeNote.onset.toStringAsFixed(1)}s',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOctaveRange() {
    if (widget.notes.isEmpty) return '0';
    final midis = widget.notes.map((e) => e.midi);
    final min = (midis.reduce((a, b) => a < b ? a : b) / 12).floor();
    final max = (midis.reduce((a, b) => a > b ? a : b) / 12).floor();
    return '${max - min + 1}';
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: HarmonieColors.surface2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              return IconButton(
                icon: Icon(playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, 
                          color: HarmonieColors.gold, size: 48),
                onPressed: playing ? _player.pause : _player.play,
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = _player.duration ?? Duration.zero;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbColor: HarmonieColors.gold,
                        activeTrackColor: HarmonieColors.gold,
                        inactiveTrackColor: Colors.white10,
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
                        max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                        onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return Text(
                _formatDuration(position),
                style: const TextStyle(color: HarmonieColors.muted, fontSize: 12),
              );
            },
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

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: HarmonieColors.muted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: HarmonieColors.cream, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _IntegratedPianoRoll extends StatelessWidget {
  final List<Note> notes;
  final double currentPosition;
  final TransformationController transformationController;
  final bool useFrench;

  const _IntegratedPianoRoll({
    required this.notes, 
    required this.currentPosition, 
    required this.transformationController,
    required this.useFrench,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InteractiveViewer(
          transformationController: transformationController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.1,
          maxScale: 5.0,
          child: CustomPaint(
            size: Size(
              (notes.last.onset + notes.last.duration) * 100 + 500, // Extra space at end
              88 * 14.0, 
            ),
            painter: PianoRollPainter(
              notes: notes, 
              currentPosition: currentPosition,
              useFrench: useFrench,
            ),
          ),
        ),
      ),
    );
  }
}

class PianoRollPainter extends CustomPainter {
  final List<Note> notes;
  final double currentPosition;
  final bool useFrench;

  PianoRollPainter({
    required this.notes, 
    required this.currentPosition,
    required this.useFrench,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintNote = Paint()..color = HarmonieColors.gold.withOpacity(0.4);
    final paintActiveNote = Paint()
      ..color = HarmonieColors.gold
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
    final paintGrid = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 0.5;
    final paintPlayhead = Paint()..color = Colors.red.withOpacity(0.6)..strokeWidth = 1.5;
    final paintKey = Paint()..color = HarmonieColors.surface;
    final paintActiveKey = Paint()..color = HarmonieColors.gold;
    final paintBlackKey = Paint()..color = Colors.black;
    
    const keyHeight = 14.0;
    const keyboardWidth = 40.0;

    // Grid (Time)
    for (var i = keyboardWidth; i < size.width; i += 100) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paintGrid);
    }

    if (notes.isEmpty) return;

    // Find active MIDI notes at current position
    final activeMidis = notes
      .where((n) => currentPosition >= n.onset && currentPosition <= (n.onset + n.duration))
      .map((n) => n.midi)
      .toSet();

    // Notes
    for (final note in notes) {
      final x = keyboardWidth + (note.onset * 100);
      final w = note.duration * 100;
      final y = (88 - (note.midi - 21)) * keyHeight;
      
      final isActive = activeMidis.contains(note.midi);
      
      if (isActive) {
        // Drawing note with glow
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y + 1, w, keyHeight - 2),
            const Radius.circular(2),
          ),
          Paint()..color = HarmonieColors.gold,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y + 1, w, keyHeight - 2),
            const Radius.circular(2),
          ),
          paintActiveNote,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y + 1, w, keyHeight - 2),
            const Radius.circular(2),
          ),
          paintNote,
        );
      }
    }

    // Playhead
    final playheadX = keyboardWidth + (currentPosition * 100);
    canvas.drawLine(Offset(playheadX, 0), Offset(playheadX, size.height), paintPlayhead);

    // Keyboard (Drawn last to be on top of notes if they overlap, though x starts after)
    // We draw keys from 21 (A0) to 108 (C8)
    for (var i = 0; i < 88; i++) {
      final midi = 21 + (87 - i);
      final y = i * keyHeight;
      final isActive = activeMidis.contains(midi);
      
      // Black keys detection
      final isBlack = _isBlackKey(midi);
      
      canvas.drawRect(
        Rect.fromLTWH(0, y, keyboardWidth, keyHeight - 1),
        isActive 
          ? paintActiveKey 
          : (isBlack ? paintBlackKey : paintKey),
      );
      
      // Note name on C
      if (midi % 12 == 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${NoteConverter.convertNote('C', useFrench)}${(midi ~/ 12) - 1}',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(5, y + 2));
      }
    }
  }

  bool _isBlackKey(int midi) {
    final noteInOctave = midi % 12;
    return [1, 3, 6, 8, 10].contains(noteInOctave);
  }

  @override
  bool shouldRepaint(covariant PianoRollPainter oldDelegate) => 
    oldDelegate.currentPosition != currentPosition;
}

class _NotesDetailList extends StatelessWidget {
  final List<Note> notes;
  final bool useFrench;
  final double currentPosition;
  final ScrollController scrollController;
  const _NotesDetailList({
    required this.notes, 
    required this.useFrench, 
    required this.currentPosition,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: notes.length,
      itemBuilder: (context, i) {
        final note = notes[i];
        final isActive = currentPosition >= note.onset && currentPosition <= (note.onset + note.duration);
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? HarmonieColors.gold.withOpacity(0.08) : HarmonieColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? HarmonieColors.gold : Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? HarmonieColors.gold : HarmonieColors.gold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.black : HarmonieColors.gold, 
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NoteConverter.convertNote(note.note, useFrench),
                      style: TextStyle(
                        color: isActive ? HarmonieColors.gold : HarmonieColors.cream, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${note.onset.toStringAsFixed(2)}s | ${note.duration.toStringAsFixed(2)}s',
                      style: const TextStyle(color: HarmonieColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(Icons.graphic_eq_rounded, color: HarmonieColors.gold, size: 16),
              const SizedBox(width: 8),
              Text(
                'M${note.midi}',
                style: const TextStyle(color: HarmonieColors.muted, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }
}
