import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';
import '../shared/widgets/user_header.dart';

/// M4 — `GET /home` plus `GET /group` for the group strip.
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<StudentRepository>();

    return AsyncView<_HomeBundle>(
      load: () async {
        final home = await repo.home();
        // A student with no group has no group list worth fetching, and the
        // endpoint would answer with an empty array either way.
        final groups = home.hasNoGroup ? <StudentGroup>[] : await repo.groups();
        return _HomeBundle(home, groups);
      },
      builder: (context, bundle, refresh) => _HomeBody(bundle: bundle),
    );
  }
}

class _HomeBundle {
  const _HomeBundle(this.home, this.groups);

  final StudentHome home;
  final List<StudentGroup> groups;
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.bundle});

  final _HomeBundle bundle;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final home = bundle.home;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      children: [
        UserHeader(
          greetingKey: home.greeting,
          trailing: home.streakDays > 0
              ? StatusChip(
                  label: '${home.streakDays} ${s.streak}',
                  icon: Icons.local_fire_department_rounded,
                  background: AppColors.sandTint,
                  foreground: AppColors.sand,
                )
              : null,
        ),
        if (home.hasNoGroup)
          EmptyView(message: s.noGroupYet, icon: Icons.groups_2_outlined)
        else ...[
          _NextTestCard(test: home.nextTest),
          const SizedBox(height: 12),
          _StatsRow(home: home),
          const SizedBox(height: 12),
          _WeekCard(week: home.week),
          if (bundle.groups.isNotEmpty) ...[
            const SizedBox(height: 12),
            _GroupsCard(groups: bundle.groups),
          ],
        ],
      ],
    );
  }
}

class _NextTestCard extends StatelessWidget {
  const _NextTestCard({required this.test});

  final TestSummary? test;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final brand = context.brand;
    final next = test;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: brand.gradient,
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        boxShadow: AppShapes.buttonShadow(brand.primary),
      ),
      child: Stack(
        children: [
          // The template's soft highlight, clipped by the card's own corner
          // radius. Without it the hero is a flat rectangle of brand colour and
          // reads as a banner rather than as a card with light on it.
          Positioned(
            top: -76,
            right: -26,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: AppShapes.splashOf(190),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: AppShapes.chipRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 7),
                Text(
                  s.testFromCenter,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            next?.title ?? s.noNextTest,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white, fontSize: 24),
          ),
          if (next != null) ...[
            const SizedBox(height: 6),
            Text(
              // Joined from the parts that exist. Interpolating the group name
              // straight in left a stray "· " at the front of the line for
              // every test whose group the endpoint did not name.
              [
                if (next.groupName.isNotEmpty) next.groupName,
                '${next.questionCount} ${s.questions}',
                '${next.timeLimitMin} ${s.minutes}',
              ].join(' · '),
              style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.86)),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              borderRadius: AppShapes.pillRadius,
              child: InkWell(
                borderRadius: AppShapes.pillRadius,
                onTap: () => context.push('/student/test/${next.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  child: Text(
                    s.start,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: brand.dark,
                    ),
                  ),
                ),
              ),
            ),
          ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.home});

  final StudentHome home;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final delta = home.avgScoreDelta;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppCard(
              radius: AppShapes.tileRadius,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.avgScore, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  const SizedBox(height: 10),
                  Center(child: ScoreRing(score: home.avgScore)),
                  const SizedBox(height: 10),
                  Text(
                    delta == 0
                        ? '—'
                        : '${delta > 0 ? '+' : ''}$delta',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: delta >= 0 ? AppColors.green : AppColors.clay,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: s.tests,
                    value: '${home.metric('tests_taken')}',
                    icon: Icons.description_outlined,
                    background: AppColors.blueTint2,
                    foreground: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _MiniStat(
                    label: s.place,
                    value: home.rank == null ? '—' : '#${home.rank}',
                    icon: Icons.emoji_events_outlined,
                    background: AppColors.violetTint,
                    foreground: AppColors.violet,
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: background, borderRadius: AppShapes.tileRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week});

  final List<WeekDay> week;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final peak = week.fold<int>(0, (m, d) => d.tests > m ? d.tests : m);
    final total = week.fold<int>(0, (m, d) => m + d.tests);
    final today = DateTime.now();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            s.weekActivity,
            trailing: Text(
              '$total ${s.testsTaken}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in week)
                  Expanded(
                    child: _WeekBar(
                      day: day,
                      peak: peak,
                      isToday: day.date.year == today.year &&
                          day.date.month == today.month &&
                          day.date.day == today.day,
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

class _WeekBar extends StatelessWidget {
  const _WeekBar({required this.day, required this.peak, required this.isToday});

  final WeekDay day;
  final int peak;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final brand = context.brand;
    // A zero-test day still gets a visible stub, so the row reads as a week
    // rather than as missing data.
    final fraction = peak == 0 ? 0.0 : day.tests / peak;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: (0.08 + fraction * 0.92).clamp(0.08, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: day.tests == 0
                      ? AppColors.track
                      : (isToday ? brand.primary : AppColors.blueLight2),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            s.weekdayShort(day.date.weekday),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              color: isToday ? AppColors.ink : AppColors.faint,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupsCard extends StatelessWidget {
  const _GroupsCard({required this.groups});

  final List<StudentGroup> groups;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(s.myGroups),
          const SizedBox(height: 12),
          for (final group in groups)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => context.push('/student/group/${group.id}'),
                child: Row(
                  children: [
                    const BlobAvatar(
                      text: '',
                      icon: Icons.menu_book_outlined,
                      size: 42,
                      background: AppColors.blueTint,
                      foreground: AppColors.blueDark,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  group.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  group.teacher?.fullName ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: AppColors.faint),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: const BorderRadius.all(Radius.circular(99)),
                            child: LinearProgressIndicator(
                              value: (group.myAvgScore ?? 0) / 100,
                              minHeight: 6,
                              backgroundColor: AppColors.track,
                              valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      group.myAvgScore == null ? '—' : '${group.myAvgScore}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
