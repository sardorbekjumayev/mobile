import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/exam_models.dart' show QuestionKind;
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';
import '../shared/widgets/solution_analysis.dart';

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

  /// `grade()` keys its answers by a running row number that only equals a
  /// question's `position` when nothing before it expanded into more than
  /// one row (see `buildAnswerRows` on the backend) — true for every sheet
  /// except one with a `drag_and_drop` question in it. This screen has no way
  /// to recompute that numbering independently without duplicating that
  /// logic in Dart, so correcting a sheet that contains one is disabled
  /// outright rather than risk sending every row after it under the wrong key
  /// and silently erasing real answers.
  bool _canCorrect(StudentAnswerSheet sheet) =>
      !sheet.questions.any((q) => q.type == QuestionKind.dragAndDrop);

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
                  if (sheet.solution != null) ...[
                    SolutionAnalysisSection(solution: sheet.solution, onRefresh: refresh),
                    const SizedBox(height: 16),
                  ],
                  if (!_canCorrect(sheet))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        s.correctionUnsupportedType,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.clay),
                      ),
                    ),
                  for (final q in sheet.questions)
                    _QuestionCard(
                      question: q,
                      chosen: _overrides[q.questionId] ?? q.chosenIndex,
                      editable: _canCorrect(sheet),
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
                  onPressed:
                      _overrides.isEmpty || _saving || !_canCorrect(sheet) ? null : () => _save(sheet),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Only reached when `_canCorrect(sheet)` — no `drag_and_drop` question
  /// anywhere in the sheet — so every row number still equals its question's
  /// `position` (see `_canCorrect`'s own doc) and this key scheme is safe.
  Future<void> _save(StudentAnswerSheet sheet) async {
    setState(() => _saving = true);

    final answers = <String, String?>{
      for (final q in sheet.questions)
        '${q.position}': q.type == QuestionKind.multipleChoice
            // Never overridden here (read-only) — re-sent as it already
            // stood, or the wholesale-replace would erase it.
            ? _lettersFor(q.chosenIndexes)
            : _letterFor(_overrides[q.questionId] ?? q.chosenIndex),
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

  static String? _lettersFor(List<int>? shownIndexes) {
    if (shownIndexes == null || shownIndexes.isEmpty) return null;
    final letters = shownIndexes.where((i) => i >= 0).map(letterOf).toList();
    return letters.isEmpty ? null : letters.join();
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.chosen,
    required this.editable,
    required this.onChanged,
  });

  final ReviewQuestion question;
  final int? chosen;
  final bool editable;
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
            // `multiple_choice`/`drag_and_drop` aren't shaped for this
            // screen's single-letter correction (see `_letterFor`'s own
            // doc) — shown read-only instead of through a one-letter
            // override that can't express "more than one" or a matching
            // exercise.
            if (question.type == QuestionKind.multipleChoice)
              _MultiChoiceReadOnly(question: question)
            else if (question.type == QuestionKind.dragAndDrop)
              _DragAndDropReadOnly(question: question)
            else
              for (var i = 0; i < question.options.length; i++)
                _OptionRow(
                  letter: letterOf(i),
                  text: question.options[i],
                  isCorrect: i == question.correctIndex,
                  isChosen: i == chosen,
                  onTap: editable ? () => onChanged(i) : null,
                ),
            if (question.type != QuestionKind.multipleChoice &&
                question.type != QuestionKind.dragAndDrop &&
                (chosen == null || chosen! < 0))
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
  final VoidCallback? onTap;

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

/// `multiple_choice`, read-only: every option, marked correct/chosen exactly
/// like a single-choice row — a student can be right on more than one.
class _MultiChoiceReadOnly extends StatelessWidget {
  const _MultiChoiceReadOnly({required this.question});

  final ReviewQuestion question;

  @override
  Widget build(BuildContext context) {
    final correct = question.correctIndexes ?? const [];
    final chosen = question.chosenIndexes ?? const [];
    return Column(
      children: [
        for (var i = 0; i < question.options.length; i++)
          _OptionRow(
            letter: letterOf(i),
            text: question.options[i],
            isCorrect: correct.contains(i),
            isChosen: chosen.contains(i),
            onTap: null,
          ),
        if (chosen.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(S.of(context).noAnswer, style: const TextStyle(fontSize: 11.5, color: AppColors.faint)),
          ),
      ],
    );
  }
}

/// `drag_and_drop`, read-only: each item beside the target the student
/// matched it to, marked right/wrong against the key.
class _DragAndDropReadOnly extends StatelessWidget {
  const _DragAndDropReadOnly({required this.question});

  final ReviewQuestion question;

  @override
  Widget build(BuildContext context) {
    final items = question.dragItems.items;
    final targets = question.dragItems.targets;
    final correct = question.dragItems.correct;
    final given = question.dragAnswer;

    if (given == null) {
      return Text(S.of(context).noAnswer, style: const TextStyle(fontSize: 11.5, color: AppColors.faint));
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _DragPairRow(
            item: items[i],
            chosenTarget: i < given.length && given[i] >= 0 && given[i] < targets.length
                ? targets[given[i]]
                : null,
            correctTarget: i < correct.length && correct[i] < targets.length ? targets[correct[i]] : null,
            isCorrect: i < given.length && i < correct.length && given[i] == correct[i],
          ),
      ],
    );
  }
}

class _DragPairRow extends StatelessWidget {
  const _DragPairRow({
    required this.item,
    required this.chosenTarget,
    required this.correctTarget,
    required this.isCorrect,
  });

  final String item;
  final String? chosenTarget;
  final String? correctTarget;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final foreground = isCorrect ? AppColors.green : AppColors.clay;
    final background = isCorrect ? AppColors.greenTint : AppColors.clayTint;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: background, borderRadius: AppShapes.tileRadius),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(item, style: TextStyle(fontSize: 12.5, color: foreground))),
          Icon(Icons.arrow_forward_rounded, size: 14, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chosenTarget ?? S.of(context).noAnswer,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: foreground),
                ),
                if (!isCorrect && correctTarget != null)
                  Text(
                    '${S.of(context).correctAnswerLabel}: $correctTarget',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.green),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
