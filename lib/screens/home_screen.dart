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
    // Afficher le dialog de notation au premier lancement
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
          // ─── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: HarmonieColors.bg,
            floating: true,
            pinned: false,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
            title: Row(
                children: [
                  // Logo
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [HarmonieColors.gold, HarmonieColors.accent2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: HarmonieColors.gold.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('♪', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'H',
                          style: TextStyle(
                            fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                            fontSize: 22,
                            color: HarmonieColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: 'armonie',
                          style: TextStyle(
                            fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                            fontSize: 22,
                            color: HarmonieColors.cream,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _IconBtn(
                    icon: Icons.notifications_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _IconBtn(
                    icon: Icons.person_outline_rounded,
                    onTap: () => context.go('/profil'),
                  ),
                ],
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Greeting ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BONSOIR, MUSICIEN',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                            fontSize: 26,
                            height: 1.2,
                            color: HarmonieColors.cream,
                          ),
                          children: const [
                            TextSpan(text: 'Quelle '),
                            TextSpan(
                              text: 'mélodie ',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: HarmonieColors.gold,
                              ),
                            ),
                            TextSpan(text: 'jouons-\nnous aujourd\'hui ?'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─── Search bar ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Chercher une chanson, un accord, une note…',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: HarmonieColors.muted,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Upload zone ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: UploadZone(
                    onTapUpload: () => context.push('/analyser'),
                    onTapRecord: () => context.push('/enregistrer'),
                  ),
                ),

                const SizedBox(height: 28),

                // ─── Instruments ──────────────────────────────────────────
                SectionHeader(
                  title: 'Mes instruments',
                  actionLabel: 'Tous →',
                  onAction: () => context.push('/instruments'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: InstrumentCatalog.all.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final instr = InstrumentCatalog.all[i];
                      return InstrumentCard(
                        instrument: instr,
                        isSelected: _selectedInstruments.contains(instr.id),
                        onTap: () => setState(() {
                          if (_selectedInstruments.contains(instr.id)) {
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

                const SizedBox(height: 8),
                if (_selectedInstruments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      children: _selectedInstruments.map((id) {
                        final instr = InstrumentCatalog.findById(id);
                        if (instr == null) return const SizedBox();
                        return Chip(
                          label: Text(
                            '${instr.emoji} ${instr.name}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: HarmonieColors.cream,
                            ),
                          ),
                          backgroundColor: HarmonieColors.surface2,
                          side: const BorderSide(
                            color: HarmonieColors.gold,
                            width: 0.5,
                          ),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 14,
                            color: HarmonieColors.muted,
                          ),
                          onDeleted: _selectedInstruments.length > 1
                              ? () => setState(
                                    () => _selectedInstruments.remove(id),
                                  )
                              : null,
                        );
                      }).toList(),
                    ),
                  ),

                // ─── Divider ──────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Divider(),
                ),

                // ─── Modes ────────────────────────────────────────────────
                SectionHeader(title: 'Que souhaitez-vous faire ?'),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Featured — Analyser
                      ModeCard(
                        icon: '🎵',
                        title: 'Analyser un chant',
                        description:
                            'Importez ou enregistrez — obtenez les notes, accords et la mélodie jouée sur votre instrument.',
                        badge: 'IA',
                        featured: true,
                        onTap: () => context.push('/analyser'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ModeCard(
                              icon: '🎼',
                              title: 'Lire partition',
                              description:
                                  'Importez une image ou PDF et l\'IA la joue pour vous.',
                              onTap: () => context.push('/partition'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ModeCard(
                              icon: '📚',
                              title: 'Apprendre',
                              description:
                                  'Cours interactifs et exercices adaptés à votre niveau.',
                              onTap: () => context.go('/apprendre'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ModeCard(
                        icon: '🎙',
                        title: 'Enregistrement studio',
                        description:
                            'Enregistrez audio ou vidéo, puis obtenez les accords et notes de votre performance.',
                        onTap: () => context.push('/enregistrer'),
                      ),
                    ],
                  ),
                ),

                // ─── Sessions récentes ────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Divider(),
                ),
                SectionHeader(
                  title: 'Sessions récentes',
                  actionLabel: 'Historique →',
                  onAction: () {},
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: const [
                      SessionTile(
                        emoji: '🎸',
                        title: 'Wonderwall — Oasis',
                        subtitle: 'Guitare acoustique · il y a 2h',
                        progress: 0.78,
                        gradientIndex: 0,
                      ),
                      SizedBox(height: 10),
                      SessionTile(
                        emoji: '🎹',
                        title: 'Clair de Lune — Debussy',
                        subtitle: 'Piano · hier',
                        progress: 0.45,
                        gradientIndex: 1,
                      ),
                      SizedBox(height: 10),
                      SessionTile(
                        emoji: '🎻',
                        title: 'La Vie en Rose — Piaf',
                        subtitle: 'Violon · il y a 3 jours',
                        progress: 0.92,
                        gradientIndex: 2,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: HarmonieColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x12FFFFFF)),
        ),
        child: Icon(icon, color: HarmonieColors.muted, size: 20),
      ),
    );
  }
}
