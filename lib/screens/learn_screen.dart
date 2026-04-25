// lib/screens/learn_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/course_model.dart';
import '../models/instrument.dart';
import '../data/course_catalog.dart';
import '../services/progress_service.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _instrumentId = 'guitar_acoustic';
  CourseLevel _level = CourseLevel.beginner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    await ProgressService.load();
    if (mounted) {
      setState(() {
        _instrumentId = ProgressService.lastInstrument;
        _level = ProgressService.levelForInstrument(_instrumentId);
        _loaded = true;
      });
    }
  }

  void _selectInstrument(String id) {
    setState(() {
      _instrumentId = id;
      _level = ProgressService.levelForInstrument(id);
    });
    ProgressService.saveLastInstrument(id);
  }

  void _selectLevel(CourseLevel level) {
    if (level == CourseLevel.beginner) {
      setState(() => _level = level);
      ProgressService.saveLevelForInstrument(_instrumentId, level);
    } else {
      // Propose quiz (optional)
      _showLevelDialog(level);
    }
  }

  void _showLevelDialog(CourseLevel level) {
    showModalBottomSheet(
      context: context,
      backgroundColor: HarmonieColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: HarmonieColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${level.emoji} Niveau ${level.label}',
              style: TextStyle(
                fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                fontSize: 20,
                color: HarmonieColors.cream,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu peux évaluer ton niveau avec un quiz rapide, ou commencer directement les cours.',
              style: const TextStyle(
                  color: HarmonieColors.muted, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/apprendre/quiz',
                      extra: {'level': level, 'instrumentId': _instrumentId});
                },
                icon: const Icon(Icons.quiz_rounded,
                    color: Colors.black, size: 18),
                label: const Text(
                  'Faire le quiz d\'évaluation',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HarmonieColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _level = level);
                  ProgressService.saveLevelForInstrument(
                      _instrumentId, level);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: HarmonieColors.gold),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Commencer directement',
                  style: TextStyle(color: HarmonieColors.gold),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Course> get _courses => kCourses
      .where((c) =>
          c.instrumentId == _instrumentId && c.level == _level)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/chat'),
        backgroundColor: HarmonieColors.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: const Text('Chat IA',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: HarmonieColors.bg,
            floating: true,
            pinned: true,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
            elevation: 0,
            centerTitle: false,
            title: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note_rounded, color: HarmonieColors.gold),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Harmonie',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                      fontSize: 18,
                      color: HarmonieColors.cream,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ACADÉMIE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: HarmonieColors.gold.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choisis ton instrument et ton niveau pour commencer.',
                    style: TextStyle(
                      color: HarmonieColors.muted,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Instrument selector ──────────────────────────────────
                  Text(
                    'Instrument',
                    style: TextStyle(
                      fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                      fontSize: 16,
                      color: HarmonieColors.cream,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Instrument horizontal scroll
          SliverToBoxAdapter(
            child: SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: _learnInstruments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final instr = _learnInstruments[i];
                  final active = _instrumentId == instr.id;
                  return GestureDetector(
                    onTap: () => _selectInstrument(instr.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 76,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active
                            ? HarmonieColors.gold.withValues(alpha: 0.15)
                            : HarmonieColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active
                              ? HarmonieColors.gold
                              : const Color(0x12FFFFFF),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(instr.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            instr.name,
                            style: TextStyle(
                              fontSize: 9,
                              color: active
                                  ? HarmonieColors.gold
                                  : HarmonieColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Level selector ───────────────────────────────────────
                  Text(
                    'Niveau',
                    style: TextStyle(
                      fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                      fontSize: 16,
                      color: HarmonieColors.cream,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: CourseLevel.values.map((l) {
                      final active = _level == l;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _selectLevel(l),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: active
                                  ? HarmonieColors.gold.withValues(alpha: 0.15)
                                  : HarmonieColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: active
                                    ? HarmonieColors.gold
                                    : const Color(0x12FFFFFF),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(l.emoji,
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 3),
                                Text(
                                  l.label,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: active
                                        ? HarmonieColors.gold
                                        : HarmonieColors.muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 6),
                  Text(
                    _level.description,
                    style: const TextStyle(
                      color: HarmonieColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Courses ──────────────────────────────────────────────
                  if (_loaded) ...[
                    if (_courses.isEmpty)
                      _EmptyState(
                          instrumentId: _instrumentId, level: _level)
                    else ...[
                      Text(
                        'Cours disponibles',
                        style: TextStyle(
                          fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                          fontSize: 16,
                          color: HarmonieColors.cream,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Course cards
          if (_loaded && _courses.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CourseCard(
                      course: _courses[i],
                      onTap: () => context.push(
                        '/apprendre/cours/${_courses[i].id}',
                        extra: _courses[i],
                      ),
                    ),
                  ),
                  childCount: _courses.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─── Subset of instruments that have course content ──────────────────────────

final _learnInstruments = InstrumentCatalog.all
    .where((i) => ['guitar_acoustic', 'piano', 'violin', 'voice']
        .contains(i.id))
    .toList();

// ─── Course card ─────────────────────────────────────────────────────────────

class _CourseCard extends StatefulWidget {
  final Course course;
  final VoidCallback onTap;
  const _CourseCard({required this.course, required this.onTap});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  int _completed = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await ProgressService.completedSections(
        widget.course.id, widget.course.sectionCount);
    if (mounted) setState(() => _completed = n);
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.course.sectionCount > 0
        ? _completed / widget.course.sectionCount
        : 0.0;
    return GestureDetector(
      onTap: widget.onTap,
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
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: HarmonieColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(widget.course.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.course.title,
                        style: TextStyle(
                          fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                          fontSize: 15,
                          color: HarmonieColors.cream,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.course.description,
                        style: const TextStyle(
                          color: HarmonieColors.muted,
                          fontSize: 11,
                          height: 1.3,
                          fontWeight: FontWeight.w300,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: HarmonieColors.muted, size: 14),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${widget.course.sectionCount} sections',
                  style: const TextStyle(
                    color: HarmonieColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const Spacer(),
                if (_completed > 0)
                  Text(
                    '$_completed/${widget.course.sectionCount} terminées',
                    style: const TextStyle(
                      color: HarmonieColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: HarmonieColors.surface2,
              color: progress == 1.0 ? HarmonieColors.success : HarmonieColors.gold,
              borderRadius: BorderRadius.circular(2),
              minHeight: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String instrumentId;
  final CourseLevel level;
  const _EmptyState({required this.instrumentId, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        children: [
          const Text('🚧', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            'Cours en préparation',
            style: TextStyle(
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              fontSize: 16,
              color: HarmonieColors.cream,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Les cours pour ce niveau et cet instrument\narrivent bientôt.',
            style: TextStyle(
              color: HarmonieColors.muted, fontSize: 12, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.go('/chat',
                extra: {'initialMessage': 'Je veux apprendre la musique avec l\'instrument ${instrumentId.replaceAll('_', ' ')} au niveau ${level.label}. Par où commencer ?'}),
            icon: const Icon(Icons.auto_awesome_rounded,
                color: HarmonieColors.gold, size: 16),
            label: const Text('Demander à l\'IA',
                style: TextStyle(color: HarmonieColors.gold, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: HarmonieColors.gold, width: 0.8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
