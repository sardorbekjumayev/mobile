import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// One student's sheet, question by question — the "tekshirish" screen.
///
/// Opened from a test's roster (an already-graded online sheet) or from
/// reviewing a paper scan (an AI-read one); both are the same shape once
/// loaded, and both correct the same way: tap a different option, save, and
/// `scanAssistant.grade` re-scores the whole sheet server-side.
class TeacherStudentReviewScreen extends StatefulWidget {
  const TeacherStudentReviewScreen({
    super.key,
    required this.testId,
    required this.studentTestId,
  });

  final String testId;
  final String studentTestId;

  @override
  State<TeacherStudentReviewScreen> createState() => _TeacherStudentReviewScreenState();
}

class _TeacherStudentReviewScreenState extends State<TeacherStudentReviewScreen> {
  /// Only the questions a teacher has actually tapped. Everything else is
  /// re-sent as it already stood — `grade()` replaces the sheet wholesale, so
  /// leaving a question out of the payload would erase a genuine answer.
  final Map<String, int> _overrides = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(s.reviewAnswers)),
      body: AsyncView<StudentAnswerSheet>(
        load: () => repo.studentAnswers(widget.testId, widget.studentTestId),
        builder: (context, sheet, refresh) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  Text(sheet.fullName, style: Theme.of(context).textTheme.headlineMedium),
                  if (sheet.score != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${sheet.score}',
                      style: const TextStyle(fontSize: 13, color: AppColors.faint),
                    ),
                  ],
                  const SizedBox(height: 16),
                  for (final q in sheet.questions)
                    _QuestionCard(
                      question: q,
                      chosen: _overrides[q.questionId] ?? q.chosenIndex,
                      onChanged: (i) => setState(() => _overrides[q.questionId] = i),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: BrandButton(
                  label: s.saveCorrection,
                  busy: _saving,
                  accent: AppColors.violet,
                  onPressed: _overrides.isEmpty || _saving ? null : () => _save(sheet),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(StudentAnswerSheet sheet) async {
    setState(() => _saving = true);

    final answers = <String, String?>{
      for (final q in sheet.questions)
        '${q.position}': _letterFor(_overrides[q.questionId] ?? q.chosenIndex),
    };

    try {
      final result = await context
          .read<TeacherRepository>()
          .correctAnswers(widget.testId, widget.studentTestId, answers);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${S.of(context).scoreUpdated}: ${result.score}')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// A negative index is a scan's double mark — this screen has no way to
  /// re-enter two letters, so fixing it here means picking one, which clears
  /// the ambiguity rather than preserving it.
  static String? _letterFor(int? shownIndex) =>
      shownIndex == null || shownIndex < 0 ? null : letterOf(shownIndex);
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.chosen, required this.onChanged});

  final ReviewQuestion question;
  final int? chosen;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${question.position}. ${question.text}',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < question.options.length; i++)
              _OptionRow(
                letter: letterOf(i),
                text: question.options[i],
                isCorrect: i == question.correctIndex,
                isChosen: i == chosen,
                onTap: () => onChanged(i),
              ),
            if (chosen == null || chosen! < 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(s.noAnswer, style: const TextStyle(fontSize: 11.5, color: AppColors.faint)),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.letter,
    required this.text,
    required this.isCorrect,
    required this.isChosen,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool isCorrect;
  final bool isChosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (isCorrect) {
      background = AppColors.greenTint;
      foreground = AppColors.green;
    } else if (isChosen) {
      background = AppColors.clayTint;
      foreground = AppColors.clay;
    } else {
      background = AppColors.surface2;
      foreground = AppColors.body;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: AppShapes.tileRadius,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: background, borderRadius: AppShapes.tileRadius),
        child: Row(
          children: [
            Text(
              letter,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: foreground),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: foreground))),
            if (isChosen) Icon(Icons.person_rounded, size: 15, color: foreground),
            if (isCorrect) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, size: 15, color: foreground),
            ],
          ],
        ),
      ),
    );
  }
}
