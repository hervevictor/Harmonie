import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/course_model.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      appBar: AppBar(
        backgroundColor: HarmonieColors.bg,
        elevation: 0,
        title: Text(
          course.title,
          style: TextStyle(
            fontFamily: GoogleFonts.playfairDisplay().fontFamily,
            fontSize: 18,
            color: HarmonieColors.cream,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: HarmonieColors.cream),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${course.emoji} ${course.level.label}',
              style: const TextStyle(
                color: HarmonieColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              course.description,
              style: const TextStyle(color: HarmonieColors.muted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HarmonieColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x12FFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sections',
                    style: TextStyle(color: HarmonieColors.cream, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...course.sections.map((section) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Section ${section.number}: ${section.title}',
                              style: const TextStyle(color: HarmonieColors.gold, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              section.content,
                              style: const TextStyle(color: HarmonieColors.muted, fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
