import '../../core/util/json.dart';
import 'session_models.dart' show initialsOf;

/// `GET /leaderboard` — top 20, scoped to the center, never platform-wide.
///
/// The only place a student sees data about another student, and it stays the
/// narrowest payload in the API: a name and aggregates, nothing else.
class Leaderboard {
  const Leaderboard({
    required this.myRank,
    required this.myScore,
    required this.totalRanked,
    required this.gapToNext,
    required this.leaders,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> j) => Leaderboard(
        myRank: asIntOrNull(j['my_rank']),
        myScore: asIntOrNull(j['my_score']),
        totalRanked: asInt(j['total_ranked']),
        gapToNext: asIntOrNull(j['gap_to_next']),
        leaders: mapList(j['leaders'], LeaderRow.fromJson),
      );

  final int? myRank;
  final int? myScore;
  final int totalRanked;
  final int? gapToNext;
  final List<LeaderRow> leaders;

  /// A student needs three submitted tests to enter the ranking; until then
  /// they are unranked rather than last.
  bool get isRanked => myRank != null && myRank! > 0;
}

class LeaderRow {
  const LeaderRow({
    required this.rank,
    required this.userId,
    required this.fullName,
    required this.initials,
    required this.score,
    required this.tests,
    required this.isMe,
  });

  factory LeaderRow.fromJson(Map<String, dynamic> j) => LeaderRow(
        rank: asInt(j['rank']),
        userId: asString(j['user_id']),
        fullName: asString(j['full_name']),
        // Only `GET /student/group/:id` sends `initials`; every other endpoint
        // sends the name alone, and reading a field that is not there drew a
        // blank avatar next to every student.
        initials: asStringOrNull(j['initials']) ?? initialsOf(asString(j['full_name'])),
        score: asInt(j['score']),
        tests: asInt(j['tests']),
        isMe: asBool(j['is_me']),
      );

  final int rank;
  final String userId;
  final String fullName;
  final String initials;
  final int score;
  final int tests;
  final bool isMe;
}

/// `GET /badge`.
///
/// Labels and icons live in the client's own bundle — a badge is a UI object
/// with a server-side predicate, and shipping its label from the backend adds a
/// deploy to every wording change.
class Badge {
  const Badge({required this.code, required this.earned, this.earnedAt, this.progress});

  factory Badge.fromJson(Map<String, dynamic> j) => Badge(
        code: asString(j['code']),
        earned: asBool(j['earned']),
        earnedAt: asDate(j['earned_at']),
        progress: j['progress'] == null ? null : BadgeProgress.fromJson(asMap(j['progress'])),
      );

  final String code;
  final bool earned;
  final DateTime? earnedAt;
  final BadgeProgress? progress;
}

class BadgeProgress {
  const BadgeProgress({required this.current, required this.target});

  factory BadgeProgress.fromJson(Map<String, dynamic> j) =>
      BadgeProgress(current: asInt(j['current']), target: asInt(j['target']));

  final int current;
  final int target;

  double get fraction => target == 0 ? 0 : (current / target).clamp(0, 1).toDouble();
}
