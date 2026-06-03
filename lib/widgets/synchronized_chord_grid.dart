import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/music_result.dart';
import '../utils/note_converter.dart';
import '../theme/app_theme.dart';

class SynchronizedChordGrid extends StatefulWidget {
  final List<ChordEvent> timeline;
  final AudioPlayer player;
  final int activeIndex;
  final bool useFrench;

  const SynchronizedChordGrid({
    super.key,
    required this.timeline,
    required this.player,
    this.activeIndex = -1,
    this.useFrench = false,
  });

  @override
  State<SynchronizedChordGrid> createState() => _SynchronizedChordGridState();
}

class _SynchronizedChordGridState extends State<SynchronizedChordGrid> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<Duration>? _posSub;
  double _activeChordProgress = 0.0;
  static const double _cellWidth = 100.0;
  static const double _cellSpacing = 12.0;

  @override
  void initState() {
    super.initState();
    _listenPosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.activeIndex != -1) {
        _scrollToIndex(widget.activeIndex, animate: false);
      }
    });
  }

  void _listenPosition() {
    _posSub = widget.player.positionStream.listen((pos) {
      if (!mounted || widget.activeIndex == -1 || widget.activeIndex >= widget.timeline.length) return;
      final event = widget.timeline[widget.activeIndex];
      final currentSec = pos.inMilliseconds / 1000.0;
      final dur = event.end - event.start;
      if (dur > 0) {
        setState(() {
          _activeChordProgress = ((currentSec - event.start) / dur).clamp(0.0, 1.0);
        });
      }
    });
  }

  @override
  void didUpdateWidget(SynchronizedChordGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != oldWidget.activeIndex) {
      if (widget.activeIndex != -1) {
        _scrollToIndex(widget.activeIndex);
      }
      setState(() {
        _activeChordProgress = 0.0;
      });
    }
  }

  void _scrollToIndex(int index, {bool animate = true}) {
    if (!_scrollController.hasClients) return;
    
    // Calculer la largeur totale de l'écran pour centrer l'élément
    final viewportWidth = _scrollController.position.viewportDimension;
    final itemOffset = index * (_cellWidth + _cellSpacing) + (_cellSpacing / 2);
    final targetOffset = itemOffset + (_cellWidth / 2) - (viewportWidth / 2);
    final maxScroll = _scrollController.position.maxScrollExtent;
    final finalOffset = targetOffset.clamp(0.0, maxScroll);

    if (animate) {
      _scrollController.animateTo(
        finalOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _scrollController.jumpTo(finalOffset);
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.timeline.isEmpty) {
      return const Center(
        child: Text('Aucun accord détecté', style: TextStyle(color: HarmonieColors.muted)),
      );
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: HarmonieColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.timeline.length,
        itemBuilder: (context, index) {
          final event = widget.timeline[index];
          final isActive = index == widget.activeIndex;
          final chordDisplay = NoteConverter.convertChord(event.chord, widget.useFrench);

          return GestureDetector(
            onTap: () => widget.player.seek(Duration(milliseconds: (event.start * 1000).toInt())),
            child: Container(
              width: _cellWidth,
              margin: const EdgeInsets.only(right: _cellSpacing),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isActive 
                      ? HarmonieColors.gold.withOpacity(0.12) 
                      : HarmonieColors.bg.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? HarmonieColors.gold : Colors.white.withOpacity(0.08),
                    width: isActive ? 2 : 1.2,
                  ),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: HarmonieColors.gold.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ] : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rendu de l'accord
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            chordDisplay,
                            style: TextStyle(
                              color: isActive ? HarmonieColors.cream : HarmonieColors.muted,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(event.start),
                            style: TextStyle(
                              color: isActive 
                                  ? HarmonieColors.gold.withOpacity(0.8) 
                                  : HarmonieColors.muted.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      // Indicateur de progression Chordify à l'intérieur du bloc actif
                      if (isActive)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 4,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _activeChordProgress,
                            child: Container(
                              color: HarmonieColors.gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(double sec) {
    final m = (sec / 60).floor();
    final s = (sec % 60).floor().toString().padLeft(2, '0');
    return '$m:$s';
  }
}

