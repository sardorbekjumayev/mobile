import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/models/student_models.dart';
import '../../../l10n/strings.dart';
import 'primitives.dart';

/// The AI advice sentence — `GET /home` for a student reading it about
/// themselves, `GET /teacher/student/:id` for a teacher reading the identical
/// cached sentence about them. One widget so a design change doesn't have to
/// be made twice and doesn't quietly drift between the two.
class AdviceCard extends StatelessWidget {
  const AdviceCard({super.key, required this.advice});

  final String advice;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.violetTint,
        borderRadius: AppShapes.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.violet),
              const SizedBox(width: 8),
              Text(
                s.advice,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.violet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            advice,
            style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          Text(
            s.adviceNote,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// The monthly score bars — `GET /progress` for a student looking at their own
/// profile, `GET /teacher/student/:id` for a teacher looking at theirs.
///
/// Both endpoints return the same `trend` rows, and drawing them twice is how
/// the two views end up disagreeing about what a flat month looks like.
class TrendCard extends StatelessWidget {
  const TrendCard({super.key, required this.trend, this.color = AppColors.violet});

  final List<TrendPoint> trend;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // The tallest bar is the scale, never a hard 100: a student whose months sit
    // between 40 and 55 should see the difference, not five identical stubs.
    final peak = trend.fold<int>(1, (m, p) => p.score > m ? p.score : m);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(s.progress),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in trend)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${point.score}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.body,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: FractionallySizedBox(
                              alignment: Alignment.bottomCenter,
                              heightFactor: (point.score / peak).clamp(0.05, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            monthLabel(point.month),
                            style: const TextStyle(fontSize: 9.5, color: AppColors.faint2),
                          ),
                        ],
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

/// Weak skills above strong ones — the order a teacher opening a student, and a
/// student opening their own profile, both need first.
class SkillsCard extends StatelessWidget {
  const SkillsCard({super.key, required this.strong, required this.weak});

  /// Splits one mixed `skills` array — what `GET /progress` returns — on the
  /// server-side `tone` bucket, so the client never re-decides who is weak.
  factory SkillsCard.fromSkills(List<SkillAccuracy> skills, {Key? key}) => SkillsCard(
        key: key,
        weak: skills.where((s) => s.tone == SkillTone.weak).toList(),
        strong: skills.where((s) => s.tone == SkillTone.strong).toList(),
      );

  final List<SkillAccuracy> strong;
  final List<SkillAccuracy> weak;

  bool get isEmpty => strong.isEmpty && weak.isEmpty;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (weak.isNotEmpty) ...[
            SectionTitle(s.weakSkills),
            const SizedBox(height: 12),
            for (final skill in weak) _SkillRow(skill: skill, color: AppColors.clay),
          ],
          if (strong.isNotEmpty) ...[
            if (weak.isNotEmpty) const SizedBox(height: 16),
            SectionTitle(s.strongSkills),
            const SizedBox(height: 12),
            for (final skill in strong) _SkillRow(skill: skill, color: AppColors.green),
          ],
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill, required this.color});

  final SkillAccuracy skill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              skill.skill,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.body),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(99)),
              child: LinearProgressIndicator(
                value: skill.accuracy / 100,
                minHeight: 6,
                backgroundColor: AppColors.track,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text(
              '${skill.accuracy}%',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// `2026-07` → `Iyul`, in the user's own language.
///
/// The axis used to read `07`. A bare two-digit number under a bar is not a
/// month label — it is the substring that happened to be left after cutting the
/// year off, and it means nothing to the student reading it.
String monthLabel(String raw) {
  final parts = raw.split('-');
  if (parts.length < 2) return raw;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) return raw;
  return DateFormat.MMM().format(DateTime(year, month));
}
