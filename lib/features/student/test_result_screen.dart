import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/exam_models.dart';
import '../../data/repositories/student_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// M9 — `GET /test/:id/result`, the only payload carrying correct answers.
///
/// Both `answer_index` and `explanation` are gated on the test's own flags, so
/// a center can ship the score without the review; the screen says so rather
/// than rendering an empty list.
class TestResultScreen extends StatelessWidget {
  const TestResultScreen({super.key, required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<StudentRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(s.result)),
      body: AsyncView<TestResult>(
        load: () => repo.result(testId),
        builder: (context, result, refresh) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _ScoreHero(result: result),
            const SizedBox(height: 16),
            if (result.answersHidden)
              EmptyView(message: s.answersHidden, icon: Icons.visibility_off_outlined)
            else
              for (final question in result.questions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ResultCard(question: question),
                ),
            const SizedBox(height: 8),
            GhostButton(label: s.tests, onPressed: () => context.go('/student/tests')),
          ],
        ),
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.result});

  final TestResult result;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final passed = result.passed;
    final gradient = passed
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.greenLight, AppColors.green],
          )
        : context.brand.gradient;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.all(Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.score}',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(color: Colors.white, fontSize: 52),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  passed ? s.passed : s.failed,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${result.correctCount}/${result.total} ${s.correctAnswers}',
            style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.86)),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.question});

  final ResultQuestion question;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final correct = question.isCorrect;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlobAvatar(
                text: '${question.position}',
                size: 34,
                background: correct ? AppColors.greenTint : AppColors.clayTint,
                foreground: correct ? AppColors.green : AppColors.clay,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.text,
                  style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < question.options.length; i++)
            _OptionLine(
              text: question.options[i],
              isCorrect: question.answerIndex == i,
              isChosen: question.chosenIndex == i,
            ),
          if (question.isUnanswered) ...[
            const SizedBox(height: 8),
            Text(
              s.notAnswered,
              style: const TextStyle(fontSize: 11.5, color: AppColors.clay),
            ),
          ],
          if (question.explanation != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: AppShapes.tileRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.explanation,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.faint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question.explanation!,
                    style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.body),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionLine extends StatelessWidget {
  const _OptionLine({
    required this.text,
    required this.isCorrect,
    required this.isChosen,
  });

  final String text;
  final bool isCorrect;
  final bool isChosen;

  @override
  Widget build(BuildContext context) {
    final wrongChoice = isChosen && !isCorrect;
    final color = isCorrect
        ? AppColors.green
        : (wrongChoice ? AppColors.clay : AppColors.body);
    final background = isCorrect
        ? AppColors.greenTint
        : (wrongChoice ? AppColors.clayTint : Colors.transparent);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: background, borderRadius: AppShapes.tileRadius),
      child: Row(
        children: [
          Icon(
            isCorrect
                ? Icons.check_circle_rounded
                : (wrongChoice ? Icons.cancel_rounded : Icons.circle_outlined),
            size: 16,
            color: isCorrect || wrongChoice ? color : AppColors.faint2,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: isCorrect || isChosen ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
