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
import '../shared/widgets/user_header.dart';

/// M12 — `GET /teacher/home` and `GET /teacher/group` for the averages chart.
class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<TeacherRepository>();

    return AsyncView<_TeacherBundle>(
      load: () async => _TeacherBundle(await repo.home(), await repo.groups()),
      builder: (context, bundle, refresh) {
        final home = bundle.home;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          children: [
            const UserHeader(
              trailing: StatusChip(
                label: 'STEPIX',
                background: AppColors.violetTint,
                foreground: AppColors.violet,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _Kpi(
                    icon: Icons.layers_outlined,
                    value: '${home.kpis.groups}',
                    label: s.groups,
                    color: AppColors.violet,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Kpi(
                    icon: Icons.groups_2_outlined,
                    value: '${home.kpis.students}',
                    label: s.students,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Kpi(
                    icon: Icons.show_chart_rounded,
                    value: '${home.kpis.avgScore}',
                    label: s.avgScore,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _TestsBanner(count: home.kpis.testsThisMonth),
            const SizedBox(height: 12),
            _AttentionCard(items: home.attention),
            if (bundle.groups.isNotEmpty) ...[
              const SizedBox(height: 12),
              _AveragesCard(groups: bundle.groups),
            ],
          ],
        );
      },
    );
  }
}

class _TeacherBundle {
  const _TeacherBundle(this.home, this.groups);

  final TeacherHome home;
  final List<TeacherGroup> groups;
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: const BorderRadius.all(Radius.circular(24)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 23)),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, height: 1.3, color: AppColors.faint),
          ),
        ],
      ),
    );
  }
}

class _TestsBanner extends StatelessWidget {
  const _TestsBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        onTap: () => context.go('/teacher/tests'),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.violet, AppColors.violetDark],
            ),
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppShapes.blob,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 23, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.myGroupTests,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.myGroupTestsNote,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 19, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three rules, each with the tap target that resolves it.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.items});

  final List<AttentionItem> items;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            s.needsAttention,
            trailing: items.isEmpty
                ? null
                : StatusChip(
                    label: '${items.length}',
                    background: AppColors.clayTint,
                    foreground: AppColors.clay,
                  ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              s.allClear,
              style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.faint),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _AttentionRow(item: item),
              ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});

  final AttentionItem item;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (icon, background, foreground) = switch (item.type) {
      AttentionType.notStarted => (
          Icons.hourglass_empty_rounded,
          AppColors.sandTint,
          AppColors.sand,
        ),
      AttentionType.lowScore => (
          Icons.trending_down_rounded,
          AppColors.clayTint,
          AppColors.clay,
        ),
      AttentionType.inactive => (
          Icons.person_off_outlined,
          AppColors.blueTint,
          AppColors.blueDark,
        ),
      AttentionType.other => (Icons.info_outline_rounded, AppColors.track, AppColors.muted),
    };

    final title = switch (item.type) {
      AttentionType.notStarted => item.title ?? s.notStartedTitle,
      AttentionType.lowScore => item.groupName ?? s.lowScoreTitle,
      AttentionType.inactive => item.fullName ?? s.inactiveTitle,
      AttentionType.other => item.title ?? s.needsAttention,
    };

    final meta = switch (item.type) {
      AttentionType.notStarted => [
          item.groupName,
          if (item.count != null) '${item.count} ${s.students.toLowerCase()}',
          if (item.dueAt != null) DateFormat('d MMM').format(item.dueAt!),
        ].whereType<String>().join(' · '),
      AttentionType.lowScore => [
          if (item.avgScore != null) '${s.avgScore} ${item.avgScore}',
          item.topic,
        ].whereType<String>().join(' · '),
      AttentionType.inactive => item.days == null ? '' : '${item.days} ${s.streak}',
      AttentionType.other => item.groupName ?? '',
    };

    final target = switch (item.type) {
      AttentionType.notStarted when item.testId != null => '/teacher/test/${item.testId}',
      AttentionType.lowScore when item.groupId != null => '/teacher/group/${item.groupId}',
      AttentionType.inactive when item.studentId != null => '/teacher/student/${item.studentId}',
      _ => null,
    };

    return Row(
      children: [
        BlobAvatar(
          text: '',
          icon: icon,
          size: 38,
          background: background,
          foreground: foreground,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              if (meta.isNotEmpty)
                Text(
                  meta,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GhostButton(
          label: target == null ? s.ok : s.open,
          dense: true,
          onPressed: target == null ? null : () => context.push(target),
        ),
      ],
    );
  }
}

class _AveragesCard extends StatelessWidget {
  const _AveragesCard({required this.groups});

  final List<TeacherGroup> groups;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(s.groupAverages),
          const SizedBox(height: 16),
          for (final group in groups)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(99)),
                      child: LinearProgressIndicator(
                        // A group with no submitted test draws an empty track
                        // rather than a bar at zero — "nobody has taken it yet"
                        // and "everyone scored nothing" are different facts.
                        value: (group.avgScore ?? 0) / 100,
                        minHeight: 8,
                        backgroundColor: AppColors.track,
                        valueColor: AlwaysStoppedAnimation(
                          (group.avgScore ?? 100) < 60 ? AppColors.clay : AppColors.violet,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 26,
                    child: Text(
                      group.avgScore == null ? '—' : '${group.avgScore}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.body,
                      ),
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
