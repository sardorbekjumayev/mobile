import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// M13 — `GET /teacher/group`.
class TeacherGroupsScreen extends StatelessWidget {
  const TeacherGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return AsyncView<List<TeacherGroup>>(
      load: repo.groups,
      builder: (context, groups, refresh) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Text(s.myGroups, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          if (groups.isEmpty)
            EmptyView(message: s.noTeacherGroups, icon: Icons.layers_outlined)
          else
            for (final group in groups)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GroupCard(group: group),
              ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final TeacherGroup group;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BlobAvatar(
                text: '',
                icon: Icons.menu_book_outlined,
                background: AppColors.violetTint,
                foreground: AppColors.violet,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      // The room needs its noun. "Matematika · 9 · 301" reads as
                      // three unrelated numbers; "301-xona" is a room.
                      [
                        group.subject,
                        if (group.level.isNotEmpty) '${group.level}-${s.levelSuffix}',
                        if (group.room != null && group.room!.isNotEmpty)
                          '${group.room}-${s.roomSuffix}',
                      ].where((e) => e.isNotEmpty).join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: '${group.avgScore}',
                background: (group.avgScore ?? 0) < 60 ? AppColors.clayTint : AppColors.greenTint,
                foreground: (group.avgScore ?? 0) < 60 ? AppColors.clay : AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _Stat(value: '${group.studentsCount}', label: s.students)),
              const SizedBox(width: 9),
              Expanded(
                child: _Stat(
                  value: group.attendancePct == null ? '—' : '${group.attendancePct}%',
                  label: s.attendance,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _Stat(
                  value: group.avgScore == null ? '—' : '${group.avgScore}',
                  label: s.avgScore,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  label: s.students,
                  onPressed: () => context.push('/teacher/group/${group.id}'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Material(
                  color: AppColors.violet,
                  borderRadius: AppShapes.pillRadius,
                  child: InkWell(
                    borderRadius: AppShapes.pillRadius,
                    onTap: () => context.push('/teacher/group/${group.id}/attendance'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Center(
                        child: Text(
                          s.register,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 2),
          // Two lines, and no letter-spacing. Three of these share a phone's
          // width, and "O'RTACHA BALL" — the longest label and the one that
          // matters most — clipped to "O'RTACHA BA…" on every card. Wrapping is
          // better than a label the reader has to guess at.
          Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: AppColors.faint2,
            ),
          ),
        ],
      ),
    );
  }
}
