import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// M14 — `GET /teacher/group/:id`: the roster with score, attendance and
/// engagement per student.
class TeacherGroupDetailScreen extends StatelessWidget {
  const TeacherGroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return Scaffold(
      appBar: AppBar(),
      body: AsyncView<TeacherGroupDetail>(
        load: () => repo.group(groupId),
        builder: (context, detail, refresh) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(detail.group.name, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 6),
            Text(
              '${detail.group.subject} · ${detail.roster.length} ${s.students.toLowerCase()}',
              style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            BrandButton(
              label: s.register,
              icon: Icons.checklist_rounded,
              onPressed: () => context.push('/teacher/group/$groupId/attendance'),
            ),
            const SizedBox(height: 16),
            if (detail.roster.isEmpty)
              EmptyView(message: s.noTeacherGroups, icon: Icons.person_add_alt)
            else
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    for (final entry in detail.roster) _RosterRow(entry: entry),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({required this.entry});

  final RosterEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (dotColor, dotLabel) = switch (entry.engagement) {
      Engagement.active => (AppColors.green, s.engagementActive),
      Engagement.slipping => (AppColors.sand, s.engagementSlipping),
      Engagement.inactive => (AppColors.clay, s.engagementInactive),
      Engagement.isNew => (AppColors.faint2, s.engagementNew),
    };

    return InkWell(
      onTap: () => context.push('/teacher/student/${entry.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.track)),
        ),
        child: Row(
          children: [
            BlobAvatar(
              text: entry.initials,
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
                    entry.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    entry.attendancePct == null
                        ? s.studentNew
                        : '${s.attendance} ${entry.attendancePct}%',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.faint),
                  ),
                ],
              ),
            ),
            // A bare coloured dot with no legend is a colour, not information.
            // The word is what lets a teacher scan the list for who to call.
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: .12),
                borderRadius: AppShapes.pillRadius,
              ),
              child: Text(
                dotLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: dotColor,
                ),
              ),
            ),
            Text(
              entry.avgScore == null ? '—' : '${entry.avgScore}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.body,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint2),
          ],
        ),
      ),
    );
  }
}
