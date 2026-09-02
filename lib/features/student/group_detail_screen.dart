import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';
import 'tests_screen.dart' show TestRow;

/// M6 — `GET /group/:id`.
///
/// Classmates appear as a name and initials only. This is the one screen where
/// a student sees other students, and it stays the narrowest one in the app.
class StudentGroupDetailScreen extends StatelessWidget {
  const StudentGroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<StudentRepository>();

    return Scaffold(
      appBar: AppBar(),
      body: AsyncView<StudentGroupDetail>(
        load: () => repo.group(groupId),
        builder: (context, detail, refresh) {
          final group = detail.group;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(group.name, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 6),
              Text(
                [group.subject, group.level].where((e) => e.isNotEmpty).join(' · '),
                style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (group.teacher != null)
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: s.teacher,
                        value: group.teacher!.fullName,
                      ),
                    if (group.room != null)
                      _InfoRow(
                        icon: Icons.meeting_room_outlined,
                        label: s.room,
                        value: group.room!,
                      ),
                    if (group.schedule.isNotEmpty)
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        label: s.schedule,
                        value: group.schedule
                            .map((slot) =>
                                '${s.weekdayShort(slot.day)} ${slot.start}–${slot.end}')
                            .join(', '),
                      ),
                    if (group.myAvgScore != null)
                      _InfoRow(
                        icon: Icons.show_chart_rounded,
                        label: s.avgScore,
                        value: '${group.myAvgScore}',
                        last: true,
                      ),
                  ],
                ),
              ),
              if (detail.classmates.isNotEmpty) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle('${s.classmates} · ${detail.classmates.length}'),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        children: [
                          for (final mate in detail.classmates)
                            SizedBox(
                              width: 64,
                              child: Column(
                                children: [
                                  BlobAvatar(text: mate.initials, size: 42),
                                  const SizedBox(height: 6),
                                  Text(
                                    mate.fullName.split(' ').first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (detail.tests.isNotEmpty) ...[
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: SectionTitle(s.groupTests),
                ),
                const SizedBox(height: 12),
                for (final test in detail.tests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TestRow(test: test),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.track)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.faint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.body)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
