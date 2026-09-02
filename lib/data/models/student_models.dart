import '../../core/util/json.dart';

/// A test as it appears in a list or on the home card.
class TestSummary {
  const TestSummary({
    required this.id,
    required this.title,
    required this.subject,
    required this.groupName,
    required this.questionCount,
    required this.timeLimitMin,
    required this.state,
    this.passScore,
    this.dueAt,
    this.score,
    this.attemptsLeft = 0,
  });

  factory TestSummary.fromJson(Map<String, dynamic> j) => TestSummary(
        id: asString(j['id']),
        title: asString(j['title']),
        subject: asString(j['subject']),
        groupName: asString(j['group_name']),
        questionCount: asInt(j['question_count']),
        timeLimitMin: asInt(j['time_limit_min']),
        state: TestState.parse(j['state']),
        passScore: asIntOrNull(j['pass_score']),
        dueAt: asDate(j['due_at']),
        score: asIntOrNull(j['score']),
        attemptsLeft: asInt(j['attempts_left']),
      );

  final String id;
  final String title;
  final String subject;
  final String groupName;
  final int questionCount;
  final int timeLimitMin;
  final TestState state;
  final int? passScore;
  final DateTime? dueAt;
  final int? score;
  final int attemptsLeft;

  bool get isPending => state != TestState.submitted;

  bool get canStart => attemptsLeft > 0 && state != TestState.submitted;
}

enum TestState {
  assigned,
  inProgress,
  submitted;

  static TestState parse(dynamic v) {
    switch (asString(v)) {
      case 'in_progress':
        return TestState.inProgress;
      case 'submitted':
        return TestState.submitted;
      default:
        return TestState.assigned;
    }
  }

  String get wire => switch (this) {
        TestState.assigned => 'assigned',
        TestState.inProgress => 'in_progress',
        TestState.submitted => 'submitted',
      };
}

/// `GET /home`.
class StudentHome {
  const StudentHome({
    required this.greeting,
    required this.streakDays,
    required this.avgScore,
    required this.avgScoreDelta,
    required this.metrics,
    required this.week,
    this.nextTest,
    this.rank,
    this.emptyState,
  });

  factory StudentHome.fromJson(Map<String, dynamic> j) => StudentHome(
        greeting: asString(j['greeting'], 'morning'),
        streakDays: asInt(j['streak_days']),
        avgScore: asInt(j['avg_score']),
        avgScoreDelta: asInt(j['avg_score_delta']),
        metrics: mapList(j['metrics'], HomeMetric.fromJson),
        week: mapList(j['week'], WeekDay.fromJson),
        nextTest: j['next_test'] == null ? null : TestSummary.fromJson(asMap(j['next_test'])),
        rank: asIntOrNull(j['rank']),
        emptyState: asStringOrNull(j['empty_state']),
      );

  final String greeting;
  final int streakDays;
  final int avgScore;
  final int avgScoreDelta;
  final List<HomeMetric> metrics;
  final List<WeekDay> week;
  final TestSummary? nextTest;
  final int? rank;

  /// `"no_group"` when the center has not placed the student in a group yet.
  /// The most common state for a brand-new account, and the least worth
  /// rendering as a wall of zeroes.
  final String? emptyState;

  bool get hasNoGroup => emptyState == 'no_group';

  int metric(String key) =>
      metrics.firstWhere((m) => m.key == key, orElse: () => const HomeMetric(key: '', value: 0)).value;
}

class HomeMetric {
  const HomeMetric({required this.key, required this.value});

  factory HomeMetric.fromJson(Map<String, dynamic> j) =>
      HomeMetric(key: asString(j['key']), value: asInt(j['value']));

  final String key;
  final int value;
}

class WeekDay {
  const WeekDay({required this.date, required this.tests});

  factory WeekDay.fromJson(Map<String, dynamic> j) =>
      WeekDay(date: asDate(j['date']) ?? DateTime.now(), tests: asInt(j['tests']));

  final DateTime date;
  final int tests;
}

/// `GET /progress`.
class StudentProgress {
  const StudentProgress({required this.trend, required this.skills});

  factory StudentProgress.fromJson(Map<String, dynamic> j) => StudentProgress(
        trend: mapList(j['trend'], TrendPoint.fromJson),
        skills: mapList(j['skills'], SkillAccuracy.fromJson),
      );

  final List<TrendPoint> trend;
  final List<SkillAccuracy> skills;

  bool get isEmpty => trend.isEmpty && skills.isEmpty;
}

class TrendPoint {
  const TrendPoint({required this.month, required this.score});

  factory TrendPoint.fromJson(Map<String, dynamic> j) =>
      TrendPoint(month: asString(j['month']), score: asInt(j['score']));

  final String month;
  final int score;
}

/// `tone` is bucketed server-side (`weak < 65 ≤ ok < 85 ≤ strong`) so the app
/// and the center panel never disagree about who is struggling.
enum SkillTone {
  weak,
  ok,
  strong;

  static SkillTone parse(dynamic v) => switch (asString(v)) {
        'weak' => SkillTone.weak,
        'strong' => SkillTone.strong,
        _ => SkillTone.ok,
      };
}

class SkillAccuracy {
  const SkillAccuracy({required this.skill, required this.accuracy, required this.tone});

  factory SkillAccuracy.fromJson(Map<String, dynamic> j) => SkillAccuracy(
        skill: asString(j['skill']),
        accuracy: asInt(j['accuracy']),
        tone: SkillTone.parse(j['tone']),
      );

  final String skill;
  final int accuracy;
  final SkillTone tone;
}

class GroupTeacher {
  const GroupTeacher({required this.id, required this.fullName, this.avatarUrl});

  factory GroupTeacher.fromJson(Map<String, dynamic> j) => GroupTeacher(
        id: asString(j['id']),
        fullName: asString(j['full_name']),
        avatarUrl: asStringOrNull(j['avatar_url']),
      );

  final String id;
  final String fullName;
  final String? avatarUrl;
}

class ScheduleSlot {
  const ScheduleSlot({required this.day, required this.start, required this.end});

  factory ScheduleSlot.fromJson(Map<String, dynamic> j) => ScheduleSlot(
        day: asInt(j['day']),
        start: asString(j['start']),
        end: asString(j['end']),
      );

  /// 1 = Monday, matching ISO-8601 and `DateTime.weekday`.
  final int day;
  final String start;
  final String end;
}

class StudentGroup {
  const StudentGroup({
    required this.id,
    required this.name,
    required this.subject,
    required this.level,
    required this.schedule,
    required this.studentsCount,
    this.teacher,
    this.room,
    this.myAvgScore,
  });

  factory StudentGroup.fromJson(Map<String, dynamic> j) => StudentGroup(
        id: asString(j['id']),
        name: asString(j['name']),
        subject: asString(j['subject']),
        level: asString(j['level']),
        schedule: mapList(j['schedule'], ScheduleSlot.fromJson),
        studentsCount: asInt(j['students_count']),
        teacher: j['teacher'] == null ? null : GroupTeacher.fromJson(asMap(j['teacher'])),
        room: asStringOrNull(j['room']),
        myAvgScore: asIntOrNull(j['my_avg_score']),
      );

  final String id;
  final String name;
  final String subject;
  final String level;
  final List<ScheduleSlot> schedule;
  final int studentsCount;
  final GroupTeacher? teacher;
  final String? room;
  final int? myAvgScore;
}

/// `GET /group/:id` — the group plus classmates and this student's test history.
///
/// Classmates carry a name and initials and nothing else: no scores, no phone
/// numbers. See `02-API-MOBILE.md` §4.
class StudentGroupDetail {
  const StudentGroupDetail({
    required this.group,
    required this.classmates,
    required this.tests,
  });

  factory StudentGroupDetail.fromJson(Map<String, dynamic> j) {
    final groupJson = j['group'] is Map<String, dynamic> ? asMap(j['group']) : j;
    return StudentGroupDetail(
      group: StudentGroup.fromJson(groupJson),
      classmates: mapList(j['classmates'], Classmate.fromJson),
      tests: mapList(j['tests'], TestSummary.fromJson),
    );
  }

  final StudentGroup group;
  final List<Classmate> classmates;
  final List<TestSummary> tests;
}

class Classmate {
  const Classmate({required this.id, required this.fullName, required this.initials});

  factory Classmate.fromJson(Map<String, dynamic> j) => Classmate(
        id: asString(j['id']),
        fullName: asString(j['full_name']),
        initials: asString(j['initials']),
      );

  final String id;
  final String fullName;
  final String initials;
}
