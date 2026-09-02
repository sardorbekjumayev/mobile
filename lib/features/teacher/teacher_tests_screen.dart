import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// M17 — `GET /teacher/test`.
///
/// Read-only by design: a teacher sees what was assigned to their groups and
/// how it is going, but tests are built in the center panel. The one write in
/// the teacher app is the attendance register.
class TeacherTestsScreen extends StatelessWidget {
  const TeacherTestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return AsyncView<List<TeacherTest>>(
      load: repo.tests,
      builder: (context, tests, refresh) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Text(s.myGroupTests, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 6),
          Text(
            s.myGroupTestsNote,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          if (tests.isEmpty)
            EmptyView(message: s.noTeacherTests, icon: Icons.fact_check_outlined)
          else
            for (final test in tests)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TeacherTestCard(test: test),
              ),
        ],
      ),
    );
  }
}

/// One test as a card: what it is, which groups have it, and how far the
/// submissions have got. Shared with the test detail screen's header.
class TeacherTestCard extends StatelessWidget {
  const TeacherTestCard({super.key, required this.test, this.onTap});

  final TeacherTest test;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final overdue = test.dueAt != null && test.dueAt!.isBefore(DateTime.now());

    return AppCard(
      onTap: onTap ?? () => context.push('/teacher/test/${test.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BlobAvatar(
                text: '',
                icon: Icons.auto_awesome_rounded,
                background: AppColors.violetTint,
                foreground: AppColors.violet,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      [
                        test.subject,
                        ...test.groupNames,
                        '${test.questionCount} ${s.questions}',
                      ].where((e) => e.isNotEmpty).join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
                    ),
                  ],
                ),
              ),
              if (test.avgScore != null)
                StatusChip(
                  label: '${test.avgScore}',
                  background:
                      test.avgScore! < 60 ? AppColors.clayTint : AppColors.greenTint,
                  foreground: test.avgScore! < 60 ? AppColors.clay : AppColors.green,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(99)),
                  child: LinearProgressIndicator(
                    value: test.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.track,
                    valueColor: const AlwaysStoppedAnimation(AppColors.violet),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${test.submittedCount}/${test.assignedCount}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.body,
                ),
              ),
            ],
          ),
          if (test.dueAt != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: overdue ? AppColors.clay : AppColors.faint,
                ),
                const SizedBox(width: 6),
                Text(
                  '${s.due}: ${DateFormat('d MMM, HH:mm').format(test.dueAt!)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: overdue ? AppColors.clay : AppColors.faint,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
