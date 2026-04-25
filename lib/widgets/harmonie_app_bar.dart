// lib/widgets/harmonie_app_bar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class HarmonieAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool transparent;

  const HarmonieAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: transparent ? Colors.transparent : HarmonieColors.bg,
      elevation: 0,
      centerTitle: false,
      leading: showBackButton
          ? Center(
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HarmonieColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: HarmonieColors.cream,
                    size: 16,
                  ),
                ),
              ),
            )
          : null,
      titleSpacing: showBackButton ? 0 : 20,
      title: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note_rounded, color: HarmonieColors.gold, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Harmonie',
                style: TextStyle(
                  fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                  fontSize: 18,
                  color: HarmonieColors.cream,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (title != 'Harmonie' && title.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 14,
                  color: HarmonieColors.muted.withOpacity(0.3),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      color: HarmonieColors.gold.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
