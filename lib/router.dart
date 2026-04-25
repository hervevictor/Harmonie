// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonie/models/music_result.dart';

import 'screens/main_shell.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/instrument_catalog_screen.dart';
import 'screens/analyse_screen.dart';
import 'screens/analyse_result_screen.dart';
import 'screens/partition_screen.dart';
import 'screens/record_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/analysis/harmony_detail_screen.dart';
import 'screens/analysis/melody_detail_screen.dart';
import 'screens/analysis/partition_detail_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/home',
  routes: [
    // ── Shell principal avec Bottom Navigation Bar ───────────────────────────
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (c, s) => _fade(const HomeScreen()),
        ),
        GoRoute(
          path: '/analyser',
          pageBuilder: (c, s) => _fade(const AnalyseScreen()),
          routes: [
            GoRoute(
              path: 'resultat',
              pageBuilder: (c, s) {
                final extra = s.extra as Map<String, dynamic>? ?? {};
                return _fade(AnalyseResultScreen(data: extra));
              },
              routes: [
                GoRoute(
                  path: 'harmonie',
                  pageBuilder: (c, s) {
                    final extra = s.extra as Map<String, dynamic>;
                    return _fade(HarmonyDetailScreen(
                      harmony: extra['harmony'] as HarmonyResult,
                      audioPath: extra['audioPath'] as String?,
                    ));
                  },
                ),
                GoRoute(
                  path: 'melodie',
                  pageBuilder: (c, s) {
                    final extra = s.extra as Map<String, dynamic>;
                    return _fade(MelodyDetailScreen(
                      notes: extra['notes'] as List<Note>,
                      useFrench: extra['useFrench'] as bool,
                      audioPath: extra['audioPath'] as String?,
                    ));
                  },
                ),
                GoRoute(
                  path: 'partition',
                  pageBuilder: (c, s) {
                    final extra = s.extra as Map<String, dynamic>;
                    return _fade(PartitionDetailScreen(
                      partitionUrl: extra['partitionUrl'] as String?,
                      svgContent: extra['svgContent'] as String?,
                    ));
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/enregistrer',
          pageBuilder: (c, s) => _fade(const RecordScreen()),
        ),
        GoRoute(
          path: '/apprendre',
          pageBuilder: (c, s) => _fade(const LearnScreen()),
        ),
        GoRoute(
          path: '/profil',
          pageBuilder: (c, s) => _fade(const ProfileScreen()),
        ),
        // Autres pages métier qui doivent garder la navigation
        GoRoute(
          path: '/partition',
          pageBuilder: (c, s) => _fade(const PartitionScreen()),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (c, s) {
            final extra = s.extra as Map<String, dynamic>?;
            final ctx = extra?['analysisContext'] as String?;
            final initial = extra?['initialMessage'] as String?;
            return _fade(ChatScreen(analysisContext: ctx, initialMessage: initial));
          },
        ),
        GoRoute(
          path: '/assistant',
          pageBuilder: (c, s) {
            final extra = s.extra as Map<String, dynamic>?;
            final ctx = extra?['analysisContext'] as String?;
            final initial = extra?['initialMessage'] as String?;
            return _fade(ChatScreen(analysisContext: ctx, initialMessage: initial));
          },
        ),
        GoRoute(
          path: '/instruments',
          pageBuilder: (c, s) => _fade(const InstrumentCatalogScreen()),
        ),
      ],
    ),

    // ── Auth (Plein écran sans navigation) ───────────────────────────────────
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _fade(const LoginScreen()),
    ),
    GoRoute(
      path: '/signup',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(const SignupScreen()),
    ),
  ],
);

CustomTransitionPage _fade(Widget child) => CustomTransitionPage(
      child: child,
      transitionsBuilder: (c, a, sa, ch) =>
          FadeTransition(opacity: a, child: ch),
      transitionDuration: const Duration(milliseconds: 250),
    );

CustomTransitionPage _slideUp(Widget child) => CustomTransitionPage(
      child: child,
      transitionsBuilder: (c, a, sa, ch) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: ch,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    );
