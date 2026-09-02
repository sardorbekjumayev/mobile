// `Badge` here is the model in `rank_models.dart` — Material's own
// `Badge` widget (the dot on an icon) is not used anywhere in the app.
import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/rank_models.dart';
import '../../data/repositories/student_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/badges_card.dart';
import '../shared/widgets/primitives.dart';

/// M10 — `GET /leaderboard` and `GET /badge`.
class StudentRankScreen extends StatelessWidget {
  const StudentRankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<StudentRepository>();

    return AsyncView<_RankBundle>(
      load: () async => _RankBundle(await repo.leaderboard(), await repo.badges()),
      builder: (context, bundle, refresh) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Text(s.rating, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          _MyRankCard(board: bundle.board),
          const SizedBox(height: 12),
          if (bundle.board.leaders.isEmpty)
            EmptyView(message: s.emptyBoard, icon: Icons.emoji_events_outlined)
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  for (final leader in bundle.board.leaders) _LeaderRow(leader: leader),
                ],
              ),
            ),
          const SizedBox(height: 12),
          BadgesCard(badges: bundle.badges),
        ],
      ),
    );
  }
}

class _RankBundle {
  const _RankBundle(this.board, this.badges);

  final Leaderboard board;
  final List<Badge> badges;
}

class _MyRankCard extends StatelessWidget {
  const _MyRankCard({required this.board});

  final Leaderboard board;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ranked = board.isRanked;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.violet, AppColors.violetDark],
        ),
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: AppShapes.blob,
            ),
            child: Text(
              ranked ? '${board.myRank}' : '—',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.white, fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranked ? s.yourRank : s.unranked,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ranked
                      ? '${board.myScore ?? 0} · ${board.totalRanked} '
                          '${s.testsTaken}'
                          '${board.gapToNext != null ? ' · ${s.gapToNext} ${board.gapToNext}' : ''}'
                      : s.unrankedNote,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.leader});

  final LeaderRow leader;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final me = leader.isMe;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.track)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${leader.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: leader.rank <= 3 ? AppColors.sand : AppColors.faint,
              ),
            ),
          ),
          const SizedBox(width: 12),
          BlobAvatar(
            text: leader.initials,
            size: 38,
            background: me ? AppColors.blueTint : AppColors.track,
            foreground: me ? AppColors.blueDark : AppColors.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leader.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: me ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${leader.tests} ${s.testsTaken}',
                  style: const TextStyle(fontSize: 11, color: AppColors.faint),
                ),
              ],
            ),
          ),
          Text(
            '${leader.score}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: me ? AppColors.blueDark : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
