import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// What was generated, before anyone has taken it.
///
/// The same content [TeacherRepository.testPdf] puts on paper, read here for
/// a quick look right after generation finishes — one common set for a
/// `same`-variant test, or the roster to pick a student's own paper from for
/// a `unique` one.
class TeacherTestPaperScreen extends StatelessWidget {
  const TeacherTestPaperScreen({super.key, required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(s.viewVariants)),
      body: AsyncView<TestPaperOverview>(
        load: () => repo.paperOverview(testId),
        builder: (context, overview, refresh) {
          if (overview.isSame && overview.common != null) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(s.commonPaper, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                for (final q in overview.common!) _PaperQuestionCard(question: q),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            itemCount: overview.students.length,
            itemBuilder: (context, i) {
              final st = overview.students[i];
              return _StudentPaperRow(
                student: st,
                onTap: () => context.push('/teacher/test/$testId/paper/${st.studentTestId}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _StudentPaperRow extends StatelessWidget {
  const _StudentPaperRow({required this.student, required this.onTap});

  final PaperStudentRef student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        radius: AppShapes.tileRadius,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    student.groupName,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

/// One student's own paper — read-only, with the key.
class TeacherStudentPaperScreen extends StatelessWidget {
  const TeacherStudentPaperScreen({
    super.key,
    required this.testId,
    required this.studentTestId,
  });

  final String testId;
  final String studentTestId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(s.viewVariants)),
      body: AsyncView<StudentPaper>(
        load: () => repo.studentPaper(testId, studentTestId),
        builder: (context, paper, refresh) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(paper.fullName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(paper.groupName, style: const TextStyle(fontSize: 12.5, color: AppColors.faint)),
            const SizedBox(height: 16),
            for (final q in paper.questions) _PaperQuestionCard(question: q),
          ],
        ),
      ),
    );
  }
}

class _PaperQuestionCard extends StatelessWidget {
  const _PaperQuestionCard({required this.question});

  final PaperQuestionKey question;

  @override
  Widget build(BuildContext context) {
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
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: i == question.answerIndex ? AppColors.greenTint : AppColors.surface2,
                    borderRadius: AppShapes.tileRadius,
                  ),
                  child: Row(
                    children: [
                      Text(
                        letterOf(i),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: i == question.answerIndex ? AppColors.green : AppColors.body,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          question.options[i],
                          style: TextStyle(
                            fontSize: 12.5,
                            color: i == question.answerIndex ? AppColors.green : AppColors.body,
                          ),
                        ),
                      ),
                      if (i == question.answerIndex)
                        const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.green),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
