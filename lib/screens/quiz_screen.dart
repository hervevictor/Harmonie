import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final CourseLevel level;
  final String instrumentId;

  const QuizScreen({super.key, required this.level, required this.instrumentId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;
  Map<String, dynamic>? _quizData;
  Map<int, dynamic> _answers = {};
  Map<String, dynamic>? _evaluationResult;

  Future<void> _generateQuiz() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _quizData = null;
      _evaluationResult = null;
      _answers = {};
    });

    try {
      final quiz = await ApiService.generateQuiz(
        instrument: widget.instrumentId,
        topic: 'Théorie musicale',
        level: widget.level.label,
        numQuestions: 5,
      );
      setState(() {
        _quizData = quiz;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _submitAnswers() async {
    if (_quizData == null) return;

    final questions = List<Map<String, dynamic>>.from(
      _quizData!['questions'] as List<dynamic>? ?? [],
    );

    final answers = questions.map((question) {
      final questionId = question['id'] as int? ?? 0;
      final questionType = question['type'] as String? ?? 'qcm';
      final answerValue = _answers[questionId];

      if (questionType == 'qcm') {
        return {
          'question_id': questionId,
          'answer_index': answerValue is int ? answerValue : -1,
          'time_seconds': 0,
        };
      }

      if (questionType == 'vrai_faux') {
        return {
          'question_id': questionId,
          'answer_value': answerValue == true,
          'time_seconds': 0,
        };
      }

      return {
        'question_id': questionId,
        'answer_value': answerValue?.toString() ?? '',
        'time_seconds': 0,
      };
    }).toList();

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _evaluationResult = null;
    });

    try {
      final result = await ApiService.evaluateQuiz(
        quiz: _quizData!,
        answers: answers,
      );
      setState(() {
        _evaluationResult = result;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  Widget _buildChoiceOptions(Map<String, dynamic> question) {
    final questionId = question['id'] as int? ?? 0;
    final type = question['type'] as String? ?? 'qcm';
    final selectedValue = _answers[questionId];

    if (type == 'qcm') {
      final options = List<String>.from(question['options'] as List<dynamic>? ?? []);
      final currentIndex = selectedValue is int ? selectedValue : null;
      return RadioGroup<int>(
        groupValue: currentIndex,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _answers[questionId] = value;
            });
          }
        },
        child: Column(
          children: options.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            return InkWell(
              onTap: () {
                setState(() {
                  _answers[questionId] = index;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      fillColor: WidgetStateProperty.all(HarmonieColors.gold),
                    ),
                    Expanded(
                      child: Text(label, style: const TextStyle(color: HarmonieColors.cream)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    if (type == 'vrai_faux') {
      final currentBool = selectedValue is bool ? selectedValue : null;
      return RadioGroup<bool>(
        groupValue: currentBool,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _answers[questionId] = value;
            });
          }
        },
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _answers[questionId] = true;
                  });
                },
                child: Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      fillColor: WidgetStateProperty.all(HarmonieColors.gold),
                    ),
                    const Text('Vrai', style: TextStyle(color: HarmonieColors.cream)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _answers[questionId] = false;
                  });
                },
                child: Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      fillColor: WidgetStateProperty.all(HarmonieColors.gold),
                    ),
                    const Text('Faux', style: TextStyle(color: HarmonieColors.cream)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return TextFormField(
      initialValue: selectedValue?.toString() ?? '',
      style: const TextStyle(color: HarmonieColors.cream),
      decoration: const InputDecoration(
        hintText: 'Écris ta réponse',
        hintStyle: TextStyle(color: HarmonieColors.muted),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        _answers[questionId] = value;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Quiz IA — ${widget.level.label}';
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      appBar: AppBar(
        backgroundColor: HarmonieColors.bg,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: GoogleFonts.playfairDisplay().fontFamily,
            fontSize: 18,
            color: HarmonieColors.cream,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: HarmonieColors.cream),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instrument : ${widget.instrumentId}',
              style: const TextStyle(
                color: HarmonieColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            if (_evaluationResult != null) ...[
              _buildResultCard(),
              const SizedBox(height: 20),
            ],
            Expanded(
              child: _quizData == null ? _buildPlaceholder() : _buildQuizForm(),
            ),
            const SizedBox(height: 16),
            if (_quizData == null)
              ElevatedButton(
                onPressed: _loading ? null : _generateQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HarmonieColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Générer mon quiz IA',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
              )
            else
              ElevatedButton(
                onPressed: _submitting ? null : _submitAnswers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HarmonieColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Envoyer mes réponses',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiz d’évaluation IA',
          style: TextStyle(
            color: HarmonieColors.cream,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.playfairDisplay().fontFamily,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'L’IA préparera un quiz de théorie musicale adapté à ton instrument et ton niveau.',
          style: TextStyle(color: HarmonieColors.muted, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 20),
        const Text(
          'Appuie sur le bouton ci-dessous pour charger les questions. Ensuite, réponds aux questions et envoie-les pour recevoir un score et un feedback personnalisé.',
          style: TextStyle(color: HarmonieColors.muted, fontSize: 14, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildQuizForm() {
    final quizTitle = _quizData?['quiz_title'] as String? ?? 'Quiz IA';
    final questions = List<Map<String, dynamic>>.from(
      _quizData?['questions'] as List<dynamic>? ?? [],
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quizTitle,
            style: TextStyle(
              color: HarmonieColors.gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Niveau : ${_quizData?['level'] ?? widget.level.label}',
            style: const TextStyle(color: HarmonieColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 18),
          ...questions.map((question) => _buildQuestionCard(question)),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final id = question['id']?.toString() ?? '-';
    final type = question['type'] as String? ?? 'qcm';
    final questionText = question['question'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HarmonieColors.muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question $id • ${type.toUpperCase()}',
              style: const TextStyle(color: HarmonieColors.gold, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(questionText, style: const TextStyle(color: HarmonieColors.cream, fontSize: 16)),
          const SizedBox(height: 14),
          _buildChoiceOptions(question),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final score = _evaluationResult?['percentage']?.toString() ?? '0';
    final total = _evaluationResult?['max_score']?.toString() ?? '0';
    final feedback = _evaluationResult?['feedback'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HarmonieColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Résultat', style: TextStyle(color: HarmonieColors.gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Score : $score% ($total pts)', style: const TextStyle(color: HarmonieColors.cream, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(feedback, style: const TextStyle(color: HarmonieColors.muted, height: 1.5)),
        ],
      ),
    );
  }
}
