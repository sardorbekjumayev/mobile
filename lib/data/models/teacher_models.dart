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
    required this.studentTestId,
    required this.fullName,
    required this.initials,
    required this.state,
    this.score,
    this.submittedAt,
  });

  factory TestParticipant.fromJson(Map<String, dynamic> j) => TestParticipant(
        studentId: asString(j['student_id'] ?? j['id']),
        // Keyed by the instance, not the student — opening one student's answer
        // sheet needs this, since a re-sit would otherwise be ambiguous.
        studentTestId: asString(j['student_test_id']),
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
  final String studentTestId;
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

// ── test creation ────────────────────────────────────────────────────────

/// `GET /teacher/program` — the teacher's own subject, its branches and their
/// topics, in one call.
class TeacherProgram {
  const TeacherProgram({required this.subjectName, required this.branches});

  factory TeacherProgram.fromJson(Map<String, dynamic> j) => TeacherProgram(
        subjectName: asString(asMap(j['subject'])['name']),
        branches: mapList(j['branches'], ProgramBranch.fromJson),
      );

  final String subjectName;
  final List<ProgramBranch> branches;

  bool get isEmpty => branches.every((b) => b.topics.isEmpty);
}

class ProgramBranch {
  const ProgramBranch({
    required this.id,
    required this.name,
    required this.topics,
    this.hint,
  });

  factory ProgramBranch.fromJson(Map<String, dynamic> j) => ProgramBranch(
        id: asString(j['id']),
        name: asString(j['name']),
        hint: asStringOrNull(j['hint']),
        topics: mapList(j['topics'], ProgramTopic.fromJson),
      );

  final String id;
  final String name;
  final String? hint;
  final List<ProgramTopic> topics;
}

class ProgramTopic {
  const ProgramTopic({
    required this.id,
    required this.position,
    required this.name,
    required this.isCustom,
    this.hint,
  });

  factory ProgramTopic.fromJson(Map<String, dynamic> j) => ProgramTopic(
        id: asString(j['id']),
        position: asInt(j['position']),
        name: asString(j['name']),
        hint: asStringOrNull(j['hint']),
        isCustom: asBool(j['is_custom']),
      );

  final String id;
  final int position;
  final String name;
  final String? hint;

  /// Written by this center rather than seeded by the platform.
  final bool isCustom;
}

/// `GET /teacher/quota` — this month's generation allowance.
///
/// Generating spends the center's AI budget, so the center caps how much of it
/// one teacher can spend. Read before the form is drawn, not after it is filled
/// in.
class TeacherQuota {
  const TeacherQuota({
    required this.used,
    required this.limit,
    required this.remaining,
    this.resetsAt,
  });

  factory TeacherQuota.fromJson(Map<String, dynamic> j) => TeacherQuota(
        used: asInt(j['used']),
        limit: asInt(j['limit']),
        remaining: asInt(j['remaining']),
        resetsAt: asDate(j['resets_at']),
      );

  final int used;
  final int limit;
  final int remaining;
  final DateTime? resetsAt;

  bool get isExhausted => remaining <= 0;
}

/// How hard the questions should be. The server's own three values.
enum TestDifficulty {
  easy,
  mixed,
  hard;

  String get wire => name;
}

/// `same` deals one paper to the whole class; `unique` gives every student
/// their own order of the same bank — no extra AI tokens, just a per-student
/// shuffle, which is why a teacher gets to choose it from a phone.
enum TestVariantMode {
  same,
  unique;

  String get wire => name;
}

/// Generation flags — the server's own defaults, mirrored here so the form
/// starts on the same footing the center panel does.
class TestFlags {
  const TestFlags({
    this.shuffleQuestions = true,
    this.shuffleAnswers = true,
    this.showAnswers = true,
    this.showExplanation = true,
    this.allowCalculator = false,
  });

  final bool shuffleQuestions;
  final bool shuffleAnswers;
  final bool showAnswers;
  final bool showExplanation;
  final bool allowCalculator;

  TestFlags copyWith({
    bool? shuffleQuestions,
    bool? shuffleAnswers,
    bool? showAnswers,
    bool? showExplanation,
    bool? allowCalculator,
  }) =>
      TestFlags(
        shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
        shuffleAnswers: shuffleAnswers ?? this.shuffleAnswers,
        showAnswers: showAnswers ?? this.showAnswers,
        showExplanation: showExplanation ?? this.showExplanation,
        allowCalculator: allowCalculator ?? this.allowCalculator,
      );

  Map<String, dynamic> toJson() => {
        'shuffle_questions': shuffleQuestions,
        'shuffle_answers': shuffleAnswers,
        'show_answers': showAnswers,
        'show_explanation': showExplanation,
        'allow_calculator': allowCalculator,
      };
}

/// `POST /teacher/test/generate`, then `GET /teacher/test/generate/:job_id`.
class GenerationJob {
  const GenerationJob({
    required this.jobId,
    required this.testId,
    required this.state,
    required this.progress,
    this.title,
    this.error,
    this.estimatedSec,
  });

  factory GenerationJob.started(Map<String, dynamic> j) => GenerationJob(
        jobId: asString(j['job_id']),
        testId: asString(j['test_id']),
        state: asString(j['state'], 'queued'),
        progress: 0,
        estimatedSec: asIntOrNull(j['estimated_sec']),
      );

  factory GenerationJob.polled(Map<String, dynamic> j, String jobId) => GenerationJob(
        jobId: jobId,
        testId: asString(j['test_id']),
        state: asString(j['state'], 'queued'),
        progress: asDouble(j['progress']),
        title: asStringOrNull(j['title']),
        error: asStringOrNull(j['error']),
      );

  final String jobId;
  final String testId;
  final String state;

  /// `0..1`, straight from the job.
  final double progress;
  final String? title;
  final String? error;

  /// The server's own estimate, used to pace the progress bar between polls
  /// rather than leaving it frozen at 35% for twenty seconds.
  final int? estimatedSec;

  bool get isDone => state == 'ready';

  bool get isFailed => state == 'failed';
}

// ── answer review & correction ──────────────────────────────────────────

/// One question on a student's sheet, in the order and letters they saw —
/// `options[0]` is what they knew as "A". `chosenIndex`/`correctIndex` are
/// already in that same frame, translated server-side.
class ReviewQuestion {
  const ReviewQuestion({
    required this.questionId,
    required this.position,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.chosenIndex,
    this.isCorrect,
  });

  factory ReviewQuestion.fromJson(Map<String, dynamic> j) => ReviewQuestion(
        questionId: asString(j['question_id']),
        position: asInt(j['position']),
        text: asString(j['text']),
        options: asStringList(j['options']),
        correctIndex: asInt(j['correct_index']),
        chosenIndex: asIntOrNull(j['chosen_index']),
        isCorrect: j['is_correct'] as bool?,
      );

  final String questionId;
  final int position;
  final String text;
  final List<String> options;
  final int correctIndex;

  /// Null when unanswered; negative (a double mark) is possible from a scan.
  final int? chosenIndex;
  final bool? isCorrect;

  bool get wasAnswered => chosenIndex != null && chosenIndex! >= 0;
}

/// `GET /teacher/test/:id/student/:studentTestId`.
class StudentAnswerSheet {
  const StudentAnswerSheet({
    required this.fullName,
    required this.state,
    required this.questions,
    this.score,
  });

  factory StudentAnswerSheet.fromJson(Map<String, dynamic> j) => StudentAnswerSheet(
        fullName: asString(asMap(j['student'])['full_name']),
        state: asString(j['state']),
        score: asIntOrNull(j['score']),
        questions: mapList(j['questions'], ReviewQuestion.fromJson),
      );

  final String fullName;
  final String state;
  final int? score;
  final List<ReviewQuestion> questions;
}

/// The score after `POST .../correct` re-grades a sheet.
class CorrectionResult {
  const CorrectionResult({required this.score, required this.correctCount, required this.total});

  factory CorrectionResult.fromJson(Map<String, dynamic> j) => CorrectionResult(
        score: asInt(j['score']),
        correctCount: asInt(j['correct_count']),
        total: asInt(j['total']),
      );

  final int score;
  final int correctCount;
  final int total;
}

/// `A` for index 0. Answer sheets — printed, scanned or reviewed — are always
/// talked about in letters.
String letterOf(int index) =>
    index >= 0 && index < 8 ? String.fromCharCode('A'.codeUnitAt(0) + index) : '?';

// ── the generated paper, before anyone has taken it ─────────────────────

/// One question with its key — `answerIndex` is only ever sent to a teacher.
class PaperQuestionKey {
  const PaperQuestionKey({
    required this.id,
    required this.position,
    required this.text,
    required this.options,
    required this.answerIndex,
    this.explanation,
  });

  factory PaperQuestionKey.fromJson(Map<String, dynamic> j) => PaperQuestionKey(
        id: asString(j['id']),
        position: asInt(j['position']),
        text: asString(j['text']),
        options: asStringList(j['options']),
        answerIndex: asInt(j['answer_index']),
        explanation: asStringOrNull(j['explanation']),
      );

  final String id;
  final int position;
  final String text;
  final List<String> options;
  final int answerIndex;
  final String? explanation;
}

class PaperStudentRef {
  const PaperStudentRef({
    required this.studentTestId,
    required this.fullName,
    required this.groupName,
    this.paperCode,
    this.score,
  });

  factory PaperStudentRef.fromJson(Map<String, dynamic> j) => PaperStudentRef(
        studentTestId: asString(j['student_test_id']),
        fullName: asString(asMap(j['student'])['full_name']),
        groupName: asString(asMap(j['group'])['name']),
        paperCode: asStringOrNull(j['paper_code']),
        score: asIntOrNull(j['score']),
      );

  final String studentTestId;
  final String fullName;
  final String groupName;
  final String? paperCode;
  final int? score;
}

/// `GET /teacher/test/:id/paper` — `common` is set for a `same`-variant test
/// (one set every student gets); null for `unique`, where [students] is the
/// roster to pick one from instead.
class TestPaperOverview {
  const TestPaperOverview({
    required this.variantMode,
    required this.questionCount,
    required this.students,
    this.common,
  });

  factory TestPaperOverview.fromJson(Map<String, dynamic> j) => TestPaperOverview(
        variantMode: asString(j['variant_mode'], 'same'),
        questionCount: asInt(j['question_count']),
        common: j['common'] == null ? null : mapList(j['common'], PaperQuestionKey.fromJson),
        students: mapList(j['students'], PaperStudentRef.fromJson),
      );

  final String variantMode;
  final int questionCount;
  final List<PaperQuestionKey>? common;
  final List<PaperStudentRef> students;

  bool get isSame => variantMode == 'same';
}

/// `GET /teacher/test/:id/paper/:student_test_id` — one student's own paper.
class StudentPaper {
  const StudentPaper({
    required this.fullName,
    required this.groupName,
    required this.questions,
    this.paperCode,
    this.score,
  });

  factory StudentPaper.fromJson(Map<String, dynamic> j) => StudentPaper(
        fullName: asString(asMap(j['student'])['full_name']),
        groupName: asString(asMap(j['group'])['name']),
        paperCode: asStringOrNull(j['paper_code']),
        score: asIntOrNull(j['score']),
        questions: mapList(j['questions'], PaperQuestionKey.fromJson),
      );

  final String fullName;
  final String groupName;
  final String? paperCode;
  final int? score;
  final List<PaperQuestionKey> questions;
}

// ── paper scanning ──────────────────────────────────────────────────────

class ScannedStudent {
  const ScannedStudent({required this.studentTestId, required this.fullName, this.score});

  factory ScannedStudent.fromJson(Map<String, dynamic> j) => ScannedStudent(
        studentTestId: asString(j['student_test_id']),
        fullName: asString(j['full_name']),
        score: asIntOrNull(j['score']),
      );

  final String studentTestId;
  final String fullName;
  final int? score;
}

/// One uploaded, AI-read answer sheet — `GET test/:id/scan`.
class PaperScan {
  const PaperScan({
    required this.id,
    required this.state,
    required this.fileUrl,
    required this.readAnswers,
    this.readCode,
    this.confidence,
    this.error,
    this.student,
  });

  factory PaperScan.fromJson(Map<String, dynamic> j) => PaperScan(
        id: asString(j['id']),
        state: asString(j['state']),
        fileUrl: asString(j['file_url']),
        readCode: asStringOrNull(j['read_code']),
        readAnswers: (j['read_answers'] is Map)
            ? (j['read_answers'] as Map).map(
                (k, v) => MapEntry(k.toString(), v?.toString()),
              )
            : const {},
        confidence: j['confidence'] == null ? null : asDouble(j['confidence']),
        error: asStringOrNull(j['error']),
        student: j['student'] == null ? null : ScannedStudent.fromJson(asMap(j['student'])),
      );

  final String id;
  final String state;
  final String fileUrl;
  final String? readCode;
  final Map<String, String?> readAnswers;
  final double? confidence;
  final String? error;
  final ScannedStudent? student;

  bool get isMatched => student != null;
  bool get isReading => state == 'reading';
  bool get isFailed => state == 'failed';
}
