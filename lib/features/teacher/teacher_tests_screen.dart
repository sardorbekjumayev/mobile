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
/// A teacher sees what their groups were assigned, how far the submissions have
/// got — and builds their own from here. The button is a floating one rather
/// than a row in the list because the list is the answer to "how is it going",
/// and making a test is a different errand that should not have to be scrolled
/// to past forty cards.
class TeacherTestsScreen extends StatelessWidget {
  const TeacherTestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create-test',
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: Text(
          s.createTest,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        onPressed: () => context.push('/teacher/create-test'),
      ),
      body: _Body(repo: repo, s: s),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.repo, required this.s});

  final TeacherRepository repo;
  final S s;

  @override
  Widget build(BuildContext context) {
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
          // Room for the floating button, so the last card is not hidden under
          // it at the bottom of the scroll.
          const SizedBox(height: 64),
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
                        // Centers name their groups after the subject —
                        // "Matematika · 9-sinf" — so printing both gave every
                        // card "Matematika · Matematika · 9-sinf". The group is
                        // the more specific of the two; the subject earns its
                        // place only when the group does not already say it.
                        if (test.groupNames.every((g) => !g.contains(test.subject)))
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
