// `Badge` here is the model in `rank_models.dart` — Material's own
// `Badge` widget (the dot on an icon) is not used anywhere in the app.
import 'package:flutter/material.dart' hide Badge;

import '../../../core/theme/tokens.dart';
import '../../../data/models/rank_models.dart';
import '../../../l10n/strings.dart';
import 'primitives.dart';

/// `GET /badge`, drawn once for both places a student meets their badges: the
/// rating screen and their own profile.
///
/// Icons and labels are the client's: a badge is a UI object with a server-side
/// predicate, and shipping its wording from the backend adds a deploy to every
/// copy change.
class BadgesCard extends StatelessWidget {
  const BadgesCard({super.key, required this.badges});

  final List<Badge> badges;

  static const _icons = <String, IconData>{
    'first_test': Icons.flag_outlined,
    'tests_5': Icons.looks_5_outlined,
    'tests_20': Icons.workspace_premium_outlined,
    'score_90': Icons.star_outline_rounded,
    'flawless': Icons.verified_outlined,
    'top3': Icons.emoji_events_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(s.achievements),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              for (final badge in badges)
                Opacity(
                  // An unearned badge stays visible: the next one is the point.
                  opacity: badge.earned ? 1 : 0.4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BlobAvatar(
                        text: '',
                        icon: _icons[badge.code] ?? Icons.military_tech_outlined,
                        size: 54,
                        background: badge.earned ? AppColors.sandTint : AppColors.track,
                        foreground: badge.earned ? AppColors.sand : AppColors.faint,
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          s.badge(badge.code),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            height: 1.3,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      if (!badge.earned && badge.progress != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${badge.progress!.current}/${badge.progress!.target}',
                            style: const TextStyle(fontSize: 9.5, color: AppColors.faint2),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
