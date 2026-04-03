// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sessions = await SupabaseService.getSessions(limit: 20);
      if (mounted) setState(() { _sessions = sessions; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    final isLoggedIn = SupabaseService.isLoggedIn;

    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: HarmonieColors.bg,
            floating: true,
            toolbarHeight: 60,
            automaticallyImplyLeading: false,
            title: Text(
              'Profil',
              style: TextStyle(
                fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                fontSize: 22,
                color: HarmonieColors.cream,
              ),
            ),
            actions: [
              if (isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: HarmonieColors.muted, size: 20),
                  onPressed: _signOut,
                  tooltip: 'Déconnexion',
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Avatar & infos ───────────────────────────────────
                  if (!isLoggedIn) ...[
                    _GuestBanner(
                      onLogin: () => context.push('/login'),
                      onSignup: () => context.push('/signup'),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                HarmonieColors.gold,
                                HarmonieColors.accent
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (user?.email?.substring(0, 1).toUpperCase() ??
                                  '?'),
                              style: TextStyle(
                                fontFamily:
                                    GoogleFonts.playfairDisplay().fontFamily,
                                fontSize: 28,
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                  color: HarmonieColors.cream,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_sessions.length} session${_sessions.length > 1 ? 's' : ''} sauvegardée${_sessions.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: HarmonieColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ─── Stats ────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          emoji: '🎵',
                          value: '${_sessions.length}',
                          label: 'Analyses',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: _StatCard(
                          emoji: '🎸',
                          value: '—',
                          label: 'Instruments',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: _StatCard(
                          emoji: '🔥',
                          value: '—',
                          label: 'Streak',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ─── Sessions récentes ────────────────────────────────
                  Text(
                    'Mes sessions',
                    style: TextStyle(
                      fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                      fontSize: 18,
                      color: HarmonieColors.cream,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_loading)
                    const Center(
                      child: CircularProgressIndicator(
                          color: HarmonieColors.gold, strokeWidth: 2),
                    )
                  else if (_sessions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: HarmonieColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x12FFFFFF)),
                      ),
                      child: Column(
                        children: [
                          const Text('🎵',
                              style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 12),
                          const Text(
                            'Aucune session pour l\'instant.\nAnalyse un morceau pour commencer !',
                            style: TextStyle(
                                color: HarmonieColors.muted,
                                fontSize: 13,
                                height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => context.push('/analyser'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: HarmonieColors.gold, width: 0.8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Analyser un morceau',
                                style: TextStyle(
                                    color: HarmonieColors.gold, fontSize: 13)),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final s = _sessions[i];
                        return _SessionCard(session: s);
                      },
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  const _GuestBanner({required this.onLogin, required this.onSignup});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HarmonieColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👤', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          Text(
            'Connecte-toi pour sauvegarder tes analyses',
            style: TextStyle(
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              fontSize: 16,
              color: HarmonieColors.cream,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Retrouve tes sessions, suis ta progression et accède à l\'IA musicale.',
            style: TextStyle(
                color: HarmonieColors.muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Se connecter',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSignup,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(
                        color: HarmonieColors.gold, width: 0.8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('S\'inscrire',
                      style: TextStyle(
                          color: HarmonieColors.gold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatCard(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              fontSize: 20,
              color: HarmonieColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: HarmonieColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  const _SessionCard({required this.session});

  String get _emoji {
    final type = session['file_type'] as String? ?? 'audio';
    switch (type) {
      case 'video': return '🎬';
      case 'image': return '🖼';
      case 'pdf': return '📄';
      default: return '🎵';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = session['title'] as String? ?? 'Session';
    final instrument = session['instrument_id'] as String? ?? '';
    final key = session['key_signature'] as String? ?? '';
    final bpm = session['bpm'] as int?;
    final createdAt = session['created_at'] as String?;

    String dateLabel = '';
    if (createdAt != null) {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inDays == 0) {
          dateLabel = "aujourd'hui";
        } else if (diff.inDays == 1) {
          dateLabel = 'hier';
        } else {
          dateLabel = 'il y a ${diff.inDays} jours';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: HarmonieColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(_emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: HarmonieColors.cream,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (instrument.isNotEmpty) instrument,
                    if (key.isNotEmpty) key,
                    if (bpm != null) '$bpm BPM',
                    if (dateLabel.isNotEmpty) dateLabel,
                  ].join(' · '),
                  style: const TextStyle(
                    color: HarmonieColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
