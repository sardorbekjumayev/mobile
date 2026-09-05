import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/session_models.dart' show initialsOf;
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/analytics_cards.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// M15 — `GET /teacher/student/:id`.
class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      appBar: AppBar(),
      body: AsyncView<StudentDetail>(
        load: () => repo.student(studentId),
        builder: (context, student, refresh) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                BlobAvatar(
                  text: initialsOf(student.fullName),
                  size: 56,
                  background: AppColors.violetTint,
                  foreground: AppColors.violet,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24),
                      ),
                      if (student.phone != null)
                        Text(
                          student.phone!,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // A brand-new student is said in words. A chart of zeroes reads as
            // a failing student, not an absent one.
            if (student.isNew)
              EmptyView(message: s.studentNew, icon: Icons.hourglass_empty_rounded)
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      value: '${student.avgScore ?? 0}',
                      label: s.avgScore,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Metric(
                      value: '${student.attendancePct ?? 0}%',
                      label: s.attendance,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Metric(
                      value: '${student.streakDays ?? 0}',
                      label: s.streak,
                      color: AppColors.sand,
                    ),
                  ),
                ],
              ),
              if (student.advice != null) ...[
                const SizedBox(height: 12),
                AdviceCard(advice: student.advice!),
              ],
              if (student.trend.isNotEmpty) ...[
                const SizedBox(height: 12),
                TrendCard(trend: student.trend),
              ],
              if (student.strong.isNotEmpty || student.weak.isNotEmpty) ...[
                const SizedBox(height: 12),
                SkillsCard(strong: student.strong, weak: student.weak),
              ],
              if (student.tests.isNotEmpty) ...[
                const SizedBox(height: 12),
                _TestsCard(tests: student.tests),
              ],
              if (student.lastSeenAt != null) ...[
                const SizedBox(height: 14),
                Text(
                  '${s.lastSeen}: ${DateFormat('d MMM, HH:mm').format(student.lastSeenAt!)}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: const BorderRadius.all(Radius.circular(22)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  color: color,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.faint),
          ),
        ],
      ),
    );
  }
}

class _TestsCard extends StatelessWidget {
  const _TestsCard({required this.tests});

  final List<StudentTestRow> tests;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(s.tests),
          const SizedBox(height: 8),
          for (final test in tests)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.track)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.ink),
                        ),
                        if (test.submittedAt != null)
                          Text(
                            DateFormat('d MMM').format(test.submittedAt!),
                            style: const TextStyle(fontSize: 11, color: AppColors.faint),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    test.score == null ? '—' : '${test.score}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.body,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
