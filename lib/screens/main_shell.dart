// lib/screens/main_shell.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/analyser')) return 1;
    if (location.startsWith('/enregistrer')) return 2;
    if (location.startsWith('/apprendre')) return 3;
    if (location.startsWith('/profil')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/analyser');
        break;
      case 2:
        context.go('/enregistrer');
        break;
      case 3:
        context.go('/apprendre');
        break;
      case 4:
        context.go('/profil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _HarmonieNavBar(
        currentIndex: _getSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  const _NavTab(this.icon, this.label);
}

class _HarmonieNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _HarmonieNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const tabs = [
    _NavTab(Icons.home_rounded, 'Accueil'),
    _NavTab(Icons.auto_awesome_rounded, 'Analyse'),
    _NavTab(Icons.mic_external_on_rounded, 'Studio'),
    _NavTab(Icons.menu_book_rounded, 'Académie'),
    _NavTab(Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HarmonieColors.surface.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(tabs.length, (i) {
                  final isActive = i == currentIndex;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width / tabs.length,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tabs[i].icon,
                            color: isActive ? HarmonieColors.gold : HarmonieColors.muted.withOpacity(0.6),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tabs[i].label,
                            style: TextStyle(
                              color: isActive ? HarmonieColors.gold : HarmonieColors.muted.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
