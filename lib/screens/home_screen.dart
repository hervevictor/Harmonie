// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/instrument.dart';
import '../widgets/instrument_card.dart';
import '../widgets/upload_zone.dart';
import '../widgets/mode_card.dart';
import '../widgets/session_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/notation_dialog.dart';
import '../services/preferences_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _selectedInstruments = {'guitar_acoustic'};

  @override
  void initState() {
    super.initState();
    if (!PreferencesService.hasSelectedNotation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showNotationDialog(context);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Premium Header Section ───────────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: HarmonieColors.bg,
            elevation: 0,
            leadingWidth: 0,
            automaticallyImplyLeading: false,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  backgroundColor: HarmonieColors.surface,
                  radius: 18,
                  child: Icon(Icons.notifications_none_rounded, color: HarmonieColors.cream, size: 20),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 20),
                child: CircleAvatar(
                  backgroundColor: HarmonieColors.gold.withOpacity(0.2),
                  radius: 18,
                  child: const Text('HV', style: TextStyle(color: HarmonieColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            centerTitle: false,
            title: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note_rounded, color: HarmonieColors.gold),
                ),
                const SizedBox(width: 10),
                Text(
                  'Harmonie',
                  style: TextStyle(
                    fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                    fontSize: 20,
                    color: HarmonieColors.cream,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero Image
                  Image.asset(
                    'assets/images/music.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: HarmonieColors.bg,
                      child: Opacity(
                        opacity: 0.4,
                        child: CustomPaint(
                          painter: _MusicVisualizationPainter(),
                        ),
                      ),
                    ),
                  ),
                  
                  // Decorative Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.1),
                          HarmonieColors.bg,
                        ],
                      ),
                    ),
                  ),

                  // Hero Text
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                              fontSize: 34,
                              height: 1.1,
                              color: HarmonieColors.cream,
                            ),
                            children: const [
                              TextSpan(text: 'Écoutez votre '),
                              TextSpan(
                                text: 'âme ',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: HarmonieColors.gold,
                                ),
                              ),
                              TextSpan(text: '\net jouez l\'harmonie.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Transformez chaque note en partition, chaque accord en savoir.',
                          style: TextStyle(
                            color: HarmonieColors.muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ─── Primary Quick Actions (Glassmorphic) ────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          title: 'Analyser',
                          subtitle: 'Audio / Vidéo',
                          icon: Icons.auto_awesome_rounded,
                          color: HarmonieColors.gold,
                          onTap: () => context.push('/analyser'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          title: 'Enregistrer',
                          subtitle: 'Performance',
                          icon: Icons.mic_external_on_rounded,
                          color: const Color(0xFF4CA9AF),
                          onTap: () => context.push('/enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ─── Instruments Switcher ────────────────────────────────────
                SectionHeader(
                  title: 'Instruments Actifs',
                  actionLabel: 'Configuration',
                  onAction: () => context.push('/instruments'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: InstrumentCatalog.all.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, i) {
                      final instr = InstrumentCatalog.all[i];
                      final isSelected = _selectedInstruments.contains(instr.id);
                      return _InstrumentCircle(
                        instrument: instr,
                        isSelected: isSelected,
                        onTap: () => setState(() {
                          if (isSelected) {
                            if (_selectedInstruments.length > 1) {
                              _selectedInstruments.remove(instr.id);
                            }
                          } else {
                            _selectedInstruments.add(instr.id);
                          }
                        }),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // ─── Explore & Learn ─────────────────────────────────────────
                SectionHeader(title: 'Explorer de nouveaux horizons'),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _WideModeCard(
                        icon: '🎼',
                        title: 'Transcription de Partitions',
                        subtitle: 'Importez une photo de partition, l\'IA s\'occupe du reste.',
                        onTap: () => context.push('/partition'),
                      ),
                      const SizedBox(height: 12),
                      _WideModeCard(
                        icon: '📚',
                        title: 'Bibliothèque de Théorie',
                        subtitle: 'Maîtrisez les gammes et les modes avec nos cours.',
                        onTap: () => context.go('/apprendre'),
                      ),
                    ],
                  ),
                ),

                // ─── Daily Inspiration ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HarmonieColors.gold.withOpacity(0.1),
                          HarmonieColors.surface2,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: HarmonieColors.gold.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Conseil du jour',
                                style: TextStyle(
                                  color: HarmonieColors.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Essayez de pratiquer les gammes pentatoniques pour fluidifier vos solos improvisés.',
                                style: TextStyle(
                                  color: HarmonieColors.cream,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ─── Recent Sessions ─────────────────────────────────────────
                SectionHeader(
                  title: 'Reprendre la pratique',
                  actionLabel: 'Tout voir',
                  onAction: () {},
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: const [
                      SessionTile(
                        emoji: '🎸',
                        title: 'Wonderwall — Oasis',
                        subtitle: 'Analyse terminée · il y a 2h',
                        progress: 1.0,
                        gradientIndex: 0,
                      ),
                      SizedBox(height: 12),
                      SessionTile(
                        emoji: '🎹',
                        title: 'Clair de Lune — Debussy',
                        subtitle: 'En cours d\'étude · hier',
                        progress: 0.45,
                        gradientIndex: 1,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: HarmonieColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x12FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: HarmonieColors.cream, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: HarmonieColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _InstrumentCircle extends StatelessWidget {
  final Instrument instrument;
  final bool isSelected;
  final VoidCallback onTap;

  const _InstrumentCircle({
    required this.instrument,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isSelected ? HarmonieColors.gold : HarmonieColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? HarmonieColors.gold : const Color(0x12FFFFFF),
                width: 2,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: HarmonieColors.gold.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ] : [],
            ),
            child: Center(
              child: Text(instrument.emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            instrument.name,
            style: TextStyle(
              color: isSelected ? HarmonieColors.cream : HarmonieColors.muted,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideModeCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WideModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HarmonieColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x0AFFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: HarmonieColors.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: HarmonieColors.cream, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: HarmonieColors.muted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0x40FFFFFF), size: 14),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x12FFFFFF)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _MusicVisualizationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HarmonieColors.gold.withOpacity(0.2)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (var i = 0; i < 60; i++) {
      final angle = (i / 60) * 3.14159 * 2;
      final length = 50 + (i % 7) * 20.0;
      final x1 = centerX + (length - 10) * 0.5 * (angle).toDouble(); // Just a placeholder for complex waves
      // Let's use a simpler radiant pattern
      final startRadius = 60.0;
      final endRadius = startRadius + 40 + (i % 5) * 15;
      
      final dx = (angle).toDouble();
      // Actually, let's just do vertical bars at the bottom
    }
    
    // Bottom bars like an equalizer
    final barWidth = size.width / 40;
    for (var i = 0; i < 40; i++) {
      final h = 20 + (i % 11) * 8.0;
      canvas.drawLine(
        Offset(i * barWidth + barWidth/2, size.height),
        Offset(i * barWidth + barWidth/2, size.height - h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
