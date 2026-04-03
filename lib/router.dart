// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/home',
  routes: [
    // ── Onglets principaux (bottom nav) ──────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (c, s) => _fade(const HomeScreen()),
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
          path: '/apprendre',
          pageBuilder: (c, s) => _fade(const LearnScreen()),
        ),
        GoRoute(
          path: '/profil',
          pageBuilder: (c, s) => _fade(const ProfileScreen()),
        ),
      ],
    ),

    // ── Écrans plein-page (sans bottom nav) ──────────────────────────────────
    GoRoute(
      path: '/instruments',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(const InstrumentCatalogScreen()),
    ),
    GoRoute(
      path: '/analyser',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(const AnalyseScreen()),
    ),
    GoRoute(
      path: '/analyser/resultat',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) {
        final extra = s.extra as Map<String, dynamic>? ?? {};
        return _slideUp(AnalyseResultScreen(data: extra));
      },
    ),
    GoRoute(
      path: '/partition',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(const PartitionScreen()),
    ),
    GoRoute(
      path: '/enregistrer',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(const RecordScreen()),
    ),

    // ── Chat contextuel (depuis résultats / Apprendre) — sans bottom nav ──────
    GoRoute(
      path: '/assistant',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) {
        final extra = s.extra as Map<String, dynamic>?;
        final ctx = extra?['analysisContext'] as String?;
        final initial = extra?['initialMessage'] as String?;
        return _slideUp(ChatScreen(analysisContext: ctx, initialMessage: initial));
      },
    ),

    // ── Auth ──────────────────────────────────────────────────────────────────
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
