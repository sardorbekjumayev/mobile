import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/student_models.dart' show TestState;
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';
import 'teacher_tests_screen.dart' show TeacherTestCard;

/// M17 detail — `GET /teacher/test/:id`.
///
/// The roster is the point of the screen: who has not started, who is mid-test
/// and who scored what. Every row leads to that student's own analytics, which
/// is where a teacher actually acts.
class TeacherTestDetailScreen extends StatelessWidget {
  const TeacherTestDetailScreen({super.key, required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'scan-answers',
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner_outlined, size: 18),
        label: Text(s.scanAnswers, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        onPressed: () => context.push('/teacher/test/$testId/scan'),
      ),
      body: AsyncView<TeacherTestDetail>(
        load: () => repo.test(testId),
        builder: (context, detail, refresh) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // The card is not tappable here: this *is* the test it opens.
            TeacherTestCard(test: detail.test, onTap: () {}),
            const SizedBox(height: 12),
            if (detail.students.isEmpty)
              EmptyView(message: s.noTeacherTests, icon: Icons.groups_2_outlined)
            else
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      s.students,
                      trailing: Text(
                        '${detail.students.length}',
                        style: const TextStyle(fontSize: 12, color: AppColors.faint),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final student in detail.students)
                      _ParticipantRow(testId: testId, student: student),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.testId, required this.student});

  final String testId;
  final TestParticipant student;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final (label, background, foreground) = switch (student.state) {
      TestState.submitted => (s.done, AppColors.greenTint, AppColors.green),
      TestState.inProgress => (s.stateInProgress, AppColors.sandTint, AppColors.sand),
      TestState.assigned => (s.stateAssigned, AppColors.track, AppColors.muted),
    };

    return InkWell(
      onTap: () => context.push('/teacher/student/${student.studentId}'),
      borderRadius: AppShapes.tileRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.track)),
        ),
        child: Row(
          children: [
            BlobAvatar(
              text: student.initials,
              size: 38,
              background: AppColors.violetTint,
              foreground: AppColors.violet,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.ink),
                  ),
                  if (student.submittedAt != null)
                    Text(
                      DateFormat('d MMM, HH:mm').format(student.submittedAt!),
                      style: const TextStyle(fontSize: 11, color: AppColors.faint),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // A score replaces the state chip once there is one — an unfinished
            // test has no score, and a zero would read as a failed one.
            if (student.score != null)
              StatusChip(
                label: '${student.score}',
                background: student.score! < 60 ? AppColors.clayTint : AppColors.greenTint,
                foreground: student.score! < 60 ? AppColors.clay : AppColors.green,
              )
            else
              StatusChip(label: label, background: background, foreground: foreground),
            if (student.state == TestState.submitted) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.fact_check_outlined, size: 19, color: AppColors.faint),
                tooltip: S.of(context).reviewAnswers,
                onPressed: () => context
                    .push('/teacher/test/$testId/student/${student.studentTestId}/review'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
