import '../../core/util/json.dart';
import 'session_models.dart' show initialsOf;
import 'student_models.dart';

/// `GET /teacher/home`.
class TeacherHome {
  const TeacherHome({required this.kpis, required this.attention});

  factory TeacherHome.fromJson(Map<String, dynamic> j) => TeacherHome(
        kpis: TeacherKpis.fromJson(asMap(j['kpis'])),
        attention: mapList(j['attention'], AttentionItem.fromJson),
      );

  final TeacherKpis kpis;

  /// The screen, not a decoration on it. Three rules, each with the tap target
  /// that resolves it — a teacher between lessons has ninety seconds, and a KPI
  /// grid does not tell them who to talk to.
  final List<AttentionItem> attention;
}

class TeacherKpis {
  const TeacherKpis({
    required this.groups,
    required this.students,
    required this.testsThisMonth,
    required this.avgScore,
  });

  factory TeacherKpis.fromJson(Map<String, dynamic> j) => TeacherKpis(
        groups: asInt(j['groups']),
        students: asInt(j['students']),
        testsThisMonth: asInt(j['tests_this_month']),
        avgScore: asInt(j['avg_score']),
      );

  final int groups;
  final int students;
  final int testsThisMonth;
  final int avgScore;
}

enum AttentionType {
  /// An assigned test nobody has started.
  notStarted,

  /// A group averaging under 60.
  lowScore,

  /// A student who has not opened the app in ten days.
  inactive,

  other;

  static AttentionType parse(dynamic v) => switch (asString(v)) {
        'not_started' => AttentionType.notStarted,
        'low_score' => AttentionType.lowScore,
        'inactive' => AttentionType.inactive,
        _ => AttentionType.other,
      };
}

class AttentionItem {
  const AttentionItem({
    required this.type,
    required this.raw,
    this.testId,
    this.groupId,
    this.studentId,
    this.title,
    this.groupName,
    this.fullName,
    this.topic,
    this.count,
    this.avgScore,
    this.days,
    this.dueAt,
  });

  factory AttentionItem.fromJson(Map<String, dynamic> j) => AttentionItem(
        type: AttentionType.parse(j['type']),
        raw: asString(j['type']),
        testId: asStringOrNull(j['test_id']),
        groupId: asStringOrNull(j['group_id']),
        studentId: asStringOrNull(j['student_id']),
        title: asStringOrNull(j['title']),
        groupName: asStringOrNull(j['group_name']),
        fullName: asStringOrNull(j['full_name']),
        topic: asStringOrNull(j['topic']),
        count: asIntOrNull(j['count']),
        avgScore: asIntOrNull(j['avg_score']),
        days: asIntOrNull(j['days']),
        dueAt: asDate(j['due_at']),
      );

  final AttentionType type;
  final String raw;
  final String? testId;
  final String? groupId;
  final String? studentId;
  final String? title;
  final String? groupName;
  final String? fullName;
  final String? topic;
  final int? count;
  final int? avgScore;
  final int? days;
  final DateTime? dueAt;
}

class TeacherGroup {
  const TeacherGroup({
    required this.id,
    required this.name,
    required this.subject,
    required this.level,
    required this.studentsCount,
    required this.schedule,
    this.avgScore,
    this.attendancePct,
    this.room,
  });

  factory TeacherGroup.fromJson(Map<String, dynamic> j) => TeacherGroup(
        id: asString(j['id']),
        name: asString(j['name']),
        subject: asString(j['subject']),
        level: asString(j['level']),
        studentsCount: asInt(j['students_count']),
        // Both nullable, and both mean "nothing to average yet" rather than
        // zero: a group with no submitted test has no average, and one whose
        // register has never been marked has no attendance. Reading them as
        // `asInt` printed "0" and "0%" for every new group in the center.
        avgScore: asIntOrNull(j['avg_score']),
        attendancePct: asIntOrNull(j['attendance_pct']),
        schedule: mapList(j['schedule'], ScheduleSlot.fromJson),
        room: asStringOrNull(j['room']),
      );

  final String id;
  final String name;
  final String subject;
  final String level;
  final int studentsCount;
  final List<ScheduleSlot> schedule;
  final int? avgScore;
  final int? attendancePct;
  final String? room;
}

class TeacherGroupDetail {
  const TeacherGroupDetail({required this.group, required this.roster});

  factory TeacherGroupDetail.fromJson(Map<String, dynamic> j) {
    final groupJson = j['group'] is Map<String, dynamic> ? asMap(j['group']) : j;
    return TeacherGroupDetail(
      group: TeacherGroup.fromJson(groupJson),
      roster: mapList(j['students'] ?? j['roster'], RosterEntry.fromJson),
    );
  }

  final TeacherGroup group;
  final List<RosterEntry> roster;
}

/// How engaged a student is, bucketed server-side.
///
/// These are the server's own four words, not a low/medium/high scale. The
/// client used to parse `low`/`medium`/`high`, which the API has never sent —
/// so every student fell through to the default and the roster showed forty
/// identical amber dots. On a screen whose whole job is spotting the student
/// who stopped turning up, that is the screen not working.
enum Engagement {
  /// Never opened the app, or has taken no test yet.
  isNew,

  /// Seen in the last week and taking tests.
  active,

  /// A week or more quiet, or no tests at all.
  slipping,

  /// Two weeks or more with no sign of them.
  inactive;

  static Engagement parse(dynamic v) => switch (asString(v)) {
        'active' => Engagement.active,
        'slipping' => Engagement.slipping,
        'inactive' => Engagement.inactive,
        _ => Engagement.isNew,
      };

  /// True where the teacher is meant to do something about it.
  bool get needsAttention => this == Engagement.slipping || this == Engagement.inactive;
}

class RosterEntry {
  const RosterEntry({
    required this.id,
    required this.fullName,
    required this.initials,
    required this.engagement,
    this.avgScore,
    this.attendancePct,
  });

  factory RosterEntry.fromJson(Map<String, dynamic> j) => RosterEntry(
        id: asString(j['id'] ?? j['student_id']),
        fullName: asString(j['full_name']),
        // Only `GET /student/group/:id` sends `initials`; every other endpoint
        // sends the name alone, and reading a field that is not there drew a
        // blank avatar next to every student.
        initials: asStringOrNull(j['initials']) ?? initialsOf(asString(j['full_name'])),
        engagement: Engagement.parse(j['engagement']),
        avgScore: asIntOrNull(j['avg_score']),
        attendancePct: asIntOrNull(j['attendance_pct']),
      );

  final String id;
  final String fullName;
  final String initials;
  final Engagement engagement;
  final int? avgScore;
  final int? attendancePct;
}

/// `GET /teacher/student/:id`.
///
/// `state == new` means the student has never submitted anything and every
/// analytic is null. The client says so in words rather than drawing a flat
/// line at zero, which reads as a failing student instead of an absent one.
class StudentDetail {
  const StudentDetail({
    required this.id,
    required this.fullName,
    required this.state,
    required this.trend,
    required this.weak,
    required this.strong,
    required this.tests,
    this.phone,
    this.avgScore,
    this.attendancePct,
    this.streakDays,
    this.lastSeenAt,
    this.advice,
  });

  factory StudentDetail.fromJson(Map<String, dynamic> j) {
    final student = asMap(j['student']);
    return StudentDetail(
      id: asString(student['id'] ?? j['id']),
      fullName: asString(student['full_name'] ?? j['full_name']),
      state: asString(j['state'], 'active'),
      trend: mapList(j['trend'], TrendPoint.fromJson),
      weak: mapList(j['weak'], SkillAccuracy.fromJson),
      strong: mapList(j['strong'], SkillAccuracy.fromJson),
      tests: mapList(j['tests'], StudentTestRow.fromJson),
      phone: asStringOrNull(student['phone']),
      avgScore: asIntOrNull(j['avg_score']),
      attendancePct: asIntOrNull(j['attendance_pct']),
      streakDays: asIntOrNull(j['streak_days']),
      lastSeenAt: asDate(j['last_seen_at']),
      advice: asStringOrNull(j['advice']),
    );
  }

  final String id;
  final String fullName;
  final String state;
  final List<TrendPoint> trend;
  final List<SkillAccuracy> weak;
  final List<SkillAccuracy> strong;
  final List<StudentTestRow> tests;
  final String? phone;
  final int? avgScore;
  final int? attendancePct;
  final int? streakDays;
  final DateTime? lastSeenAt;

  /// AI-generated, cached 24h, written in the teacher's language. A suggestion,
  /// never a grade — the copy around it says so.
  final String? advice;

  bool get isNew => state == 'new';
}

class StudentTestRow {
  const StudentTestRow({required this.id, required this.title, this.score, this.submittedAt});

  factory StudentTestRow.fromJson(Map<String, dynamic> j) => StudentTestRow(
        id: asString(j['id']),
        title: asString(j['title']),
        score: asIntOrNull(j['score']),
        submittedAt: asDate(j['submitted_at']),
      );

  final String id;
  final String title;
  final int? score;
  final DateTime? submittedAt;
}

/// `GET /teacher/test` — read-only. Test creation lives in the center panel,
/// because generation spends the center's AI budget.
class TeacherTest {
  const TeacherTest({
    required this.id,
    required this.title,
    required this.subject,
    required this.groupNames,
    required this.questionCount,
    required this.submittedCount,
    required this.assignedCount,
    this.avgScore,
    this.dueAt,
  });

  factory TeacherTest.fromJson(Map<String, dynamic> j) => TeacherTest(
        id: asString(j['id']),
        title: asString(j['title']),
        subject: asString(j['subject']),
        groupNames: _groupNames(j),
        questionCount: asInt(j['question_count']),
        // The endpoint calls them `submitted` and `assigned`; the model was
        // reading `submitted_count` and `assigned_count`, which it has never
        // sent — so every test card in the app showed "0/0 topshirdi" and an
        // empty progress bar, including tests a whole group had finished.
        submittedCount: asInt(j['submitted'] ?? j['submitted_count']),
        assignedCount: asInt(j['assigned'] ?? j['assigned_count']),
        avgScore: asIntOrNull(j['avg_score']),
        dueAt: asDate(j['due_at']),
      );

  final String id;
  final String title;
  final String subject;
  final List<String> groupNames;
  final int questionCount;
  final int submittedCount;
  final int assignedCount;
  final int? avgScore;
  final DateTime? dueAt;

  double get progress => assignedCount == 0 ? 0 : submittedCount / assignedCount;

  static List<String> _groupNames(Map<String, dynamic> j) {
    if (j['groups'] is List) {
      return (j['groups'] as List)
          .map((g) => g is Map ? asString(g['name']) : asString(g))
          .where((s) => s.isNotEmpty)
          .toList();
    }
    // `GET /teacher/test` sends one nested `group`, not a `group_name` — the
    // card had no group to name under any of its tests.
    final single = asStringOrNull(j['group_name']) ?? asStringOrNull(asMap(j['group'])['name']);
    return single == null ? const [] : [single];
  }
}

class TeacherTestDetail {
  const TeacherTestDetail({required this.test, required this.students});

  factory TeacherTestDetail.fromJson(Map<String, dynamic> j) {
    final testJson = j['test'] is Map<String, dynamic> ? asMap(j['test']) : j;
    return TeacherTestDetail(
      test: TeacherTest.fromJson(testJson),
      students: mapList(j['students'], TestParticipant.fromJson),
    );
  }

  final TeacherTest test;
  final List<TestParticipant> students;
}

class TestParticipant {
  const TestParticipant({
    required this.studentId,
    required this.fullName,
    required this.initials,
    required this.state,
    this.score,
    this.submittedAt,
  });

  factory TestParticipant.fromJson(Map<String, dynamic> j) => TestParticipant(
        studentId: asString(j['student_id'] ?? j['id']),
        fullName: asString(j['full_name']),
        // Only `GET /student/group/:id` sends `initials`; every other endpoint
        // sends the name alone, and reading a field that is not there drew a
        // blank avatar next to every student.
        initials: asStringOrNull(j['initials']) ?? initialsOf(asString(j['full_name'])),
        state: TestState.parse(j['state']),
        score: asIntOrNull(j['score']),
        submittedAt: asDate(j['submitted_at']),
      );

  final String studentId;
  final String fullName;
  final String initials;
  final TestState state;
  final int? score;
  final DateTime? submittedAt;
}

enum AttendanceStatus {
  present,
  late,
  absent,
  excused;

  String get wire => name;

  static AttendanceStatus parse(dynamic v) => switch (asString(v)) {
        'late' => AttendanceStatus.late,
        'absent' => AttendanceStatus.absent,
        'excused' => AttendanceStatus.excused,
        _ => AttendanceStatus.present,
      };
}

class AttendanceMark {
  const AttendanceMark({required this.studentId, required this.status});

  final String studentId;
  final AttendanceStatus status;

  Map<String, dynamic> toJson() => {'student_id': studentId, 'status': status.wire};
}
