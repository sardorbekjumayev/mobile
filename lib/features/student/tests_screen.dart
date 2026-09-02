import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// M7 — `GET /test`, split into the two states a student cares about.
///
/// `assigned` and `in_progress` share the "pending" tab: from the student's
/// side both mean "this is waiting for you", and the card's own button says
/// which one it is.
class StudentTestsScreen extends StatefulWidget {
  const StudentTestsScreen({super.key});

  @override
  State<StudentTestsScreen> createState() => _StudentTestsScreenState();
}

class _StudentTestsScreenState extends State<StudentTestsScreen> {
  bool _pending = true;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<StudentRepository>();

    return AsyncView<List<TestSummary>>(
      key: ValueKey(_pending),
      load: () async {
        if (!_pending) {
          final done = await repo.tests(state: TestState.submitted);
          return done.items;
        }
        final assigned = await repo.tests(state: TestState.assigned);
        final started = await repo.tests(state: TestState.inProgress);
        return [...started.items, ...assigned.items];
      },
      builder: (context, tests, refresh) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Text(s.tests, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          _Segmented(
            left: s.pending,
            right: s.done,
            leftSelected: _pending,
            onChanged: (value) => setState(() => _pending = value),
          ),
          const SizedBox(height: 12),
          if (tests.isEmpty)
            EmptyView(
              message: _pending ? s.noPendingTests : s.noDoneTests,
              icon: Icons.fact_check_outlined,
            )
          else
            for (final test in tests)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TestRow(test: test),
              ),
        ],
      ),
    );
  }
}

/// The pill toggle above the list.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.left,
    required this.right,
    required this.leftSelected,
    required this.onChanged,
  });

  final String left;
  final String right;
  final bool leftSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShapes.pillRadius,
        boxShadow: AppShapes.shadow1,
      ),
      child: Row(
        children: [
          Expanded(child: _Tab(label: left, selected: leftSelected, onTap: () => onChanged(true))),
          Expanded(
            child: _Tab(label: right, selected: !leftSelected, onTap: () => onChanged(false)),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blueTint : Colors.transparent,
      borderRadius: AppShapes.pillRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppShapes.pillRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.blueDark : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One test in a list — used on the tests tab and inside a group's detail.
class TestRow extends StatelessWidget {
  const TestRow({super.key, required this.test});

  final TestSummary test;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final submitted = test.state == TestState.submitted;
    final started = test.state == TestState.inProgress;

    return AppCard(
      radius: AppShapes.tileRadius,
      padding: const EdgeInsets.all(18),
      onTap: () => context.push(
        submitted ? '/student/test/${test.id}/result' : '/student/test/${test.id}',
      ),
      child: Row(
        children: [
          BlobAvatar(
            text: '',
            icon: submitted ? Icons.check_rounded : Icons.edit_note_rounded,
            size: 46,
            background: submitted ? AppColors.greenTint : AppColors.blueTint,
            foreground: submitted ? AppColors.green : AppColors.blueDark,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${test.groupName} · ${test.questionCount} ${s.questions}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (submitted)
            Text(
              '${test.score ?? 0}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    color: AppColors.green,
                  ),
            )
          else
            _TakeButton(label: started ? s.continueTest : s.take, testId: test.id),
        ],
      ),
    );
  }
}

class _TakeButton extends StatelessWidget {
  const _TakeButton({required this.label, required this.testId});

  final String label;
  final String testId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blue,
      borderRadius: AppShapes.pillRadius,
      child: InkWell(
        borderRadius: AppShapes.pillRadius,
        onTap: () => context.push('/student/test/$testId'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
