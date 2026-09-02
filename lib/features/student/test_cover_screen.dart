import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// M7b — `GET /test/:id`: config and attempts, deliberately no questions.
class TestCoverScreen extends StatelessWidget {
  const TestCoverScreen({super.key, required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<StudentRepository>();

    return Scaffold(
      appBar: AppBar(),
      body: AsyncView<TestSummary>(
        load: () => repo.test(testId),
        builder: (context, test, refresh) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(test.title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              '${test.subject} · ${test.groupName}',
              style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            AppCard(
              child: Column(
                children: [
                  _Row(label: s.questions, value: '${test.questionCount}'),
                  _Row(label: s.minutes, value: '${test.timeLimitMin}'),
                  if (test.passScore != null)
                    _Row(label: s.passScore, value: '${test.passScore}'),
                  _Row(label: s.attemptsLeft, value: '${test.attemptsLeft}'),
                  if (test.dueAt != null)
                    _Row(
                      label: s.due,
                      value: DateFormat('d MMM, HH:mm').format(test.dueAt!),
                      last: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (test.canStart)
              BrandButton(
                label: test.state == TestState.inProgress ? s.continueTest : s.start,
                onPressed: () => context.pushReplacement('/student/test/$testId/run'),
              )
            else if (test.state == TestState.submitted)
              BrandButton(
                label: s.result,
                onPressed: () => context.pushReplacement('/student/test/$testId/result'),
              )
            else
              EmptyView(message: s.noAttemptsLeft, icon: Icons.block_rounded),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.track)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.body)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
