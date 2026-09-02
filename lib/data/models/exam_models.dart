import '../../core/util/json.dart';

/// `POST /test/:id/start`.
///
/// Deliberately without `answer_index` and `explanation` — shipping the correct
/// answer to the device and hiding it in the UI is not a test. Both arrive with
/// `GET /test/:id/result`, after submission.
class TestAttempt {
  const TestAttempt({
    required this.studentTestId,
    required this.attemptNo,
    required this.questions,
    this.expiresAt,
  });

  factory TestAttempt.fromJson(Map<String, dynamic> j) => TestAttempt(
        studentTestId: asString(j['student_test_id']),
        attemptNo: asInt(j['attempt_no'], 1),
        questions: mapList(j['questions'], ExamQuestion.fromJson)
          ..sort((a, b) => a.position.compareTo(b.position)),
        expiresAt: asDate(j['expires_at']),
      );

  final String studentTestId;
  final int attemptNo;
  final List<ExamQuestion> questions;

  /// Server-issued (`now + time_limit_min`). The client's countdown is
  /// decoration: a submit after this instant is still accepted and graded on
  /// the answers that arrived before it.
  final DateTime? expiresAt;

  Duration? get remaining {
    if (expiresAt == null) return null;
    final left = expiresAt!.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }
}

class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.position,
    required this.text,
    required this.options,
    this.skill,
    this.figure,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> j) => ExamQuestion(
        id: asString(j['id']),
        position: asInt(j['position']),
        text: asString(j['text']),
        options: asStringList(j['options']),
        skill: asStringOrNull(j['skill']),
        figure: j['figure'] == null ? null : QuestionFigure.fromJson(asMap(j['figure'])),
      );

  final String id;
  final int position;
  final String text;
  final List<String> options;
  final String? skill;
  final QuestionFigure? figure;
}

/// A drawing spec for geometry and physics questions, rendered on a 320×220
/// canvas with y pointing down. See `08-AI-ENGINE.md` §6.
class QuestionFigure {
  const QuestionFigure({required this.lines, required this.circles, required this.labels});

  factory QuestionFigure.fromJson(Map<String, dynamic> j) => QuestionFigure(
        lines: _numRows(j['lines']).map(FigureLine.fromRow).toList(),
        circles: _numRows(j['circles']).map(FigureCircle.fromRow).toList(),
        labels: (j['labels'] is List ? j['labels'] as List : const [])
            .whereType<List>()
            .map(FigureLabel.fromRow)
            .toList(),
      );

  static const canvasWidth = 320.0;
  static const canvasHeight = 220.0;

  final List<FigureLine> lines;
  final List<FigureCircle> circles;
  final List<FigureLabel> labels;

  bool get isEmpty => lines.isEmpty && circles.isEmpty && labels.isEmpty;

  static List<List<num>> _numRows(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<List>()
        .map((row) => row.whereType<num>().toList())
        .where((row) => row.isNotEmpty)
        .toList();
  }
}

class FigureLine {
  const FigureLine({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.dashed,
  });

  /// `[x1, y1, x2, y2, dashed]` — the fifth element is `1` for a hidden edge.
  factory FigureLine.fromRow(List<num> r) => FigureLine(
        x1: _at(r, 0),
        y1: _at(r, 1),
        x2: _at(r, 2),
        y2: _at(r, 3),
        dashed: r.length > 4 && r[4] == 1,
      );

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final bool dashed;
}

class FigureCircle {
  const FigureCircle({required this.cx, required this.cy, required this.r});

  /// `[cx, cy, r]`.
  factory FigureCircle.fromRow(List<num> r) =>
      FigureCircle(cx: _at(r, 0), cy: _at(r, 1), r: _at(r, 2));

  final double cx;
  final double cy;
  final double r;
}

class FigureLabel {
  const FigureLabel({required this.x, required this.y, required this.text});

  /// `[x, y, "A"]`.
  factory FigureLabel.fromRow(List row) => FigureLabel(
        x: row.isNotEmpty && row[0] is num ? (row[0] as num).toDouble() : 0,
        y: row.length > 1 && row[1] is num ? (row[1] as num).toDouble() : 0,
        text: row.length > 2 ? asString(row[2]) : '',
      );

  final double x;
  final double y;
  final String text;
}

double _at(List<num> r, int i) => i < r.length ? r[i].toDouble() : 0;

/// `POST /test/:id/answer` — says only that the answer was saved.
///
/// No verdict on purpose: returning correctness per answer turns the timer into
/// a brute-force oracle on a second attempt.
class AnswerAck {
  const AnswerAck({required this.saved, required this.answered, required this.total});

  factory AnswerAck.fromJson(Map<String, dynamic> j) => AnswerAck(
        saved: asBool(j['saved'], true),
        answered: asInt(j['answered']),
        total: asInt(j['total']),
      );

  final bool saved;
  final int answered;
  final int total;
}

/// `POST /test/:id/submit`.
class SubmitOutcome {
  const SubmitOutcome({
    required this.score,
    required this.correctCount,
    required this.total,
    required this.passed,
    required this.rankDelta,
    required this.newBadges,
    required this.durationSec,
  });

  factory SubmitOutcome.fromJson(Map<String, dynamic> j) => SubmitOutcome(
        score: asInt(j['score']),
        correctCount: asInt(j['correct_count']),
        total: asInt(j['total']),
        passed: asBool(j['passed']),
        rankDelta: asInt(j['rank_delta']),
        newBadges: asStringList(j['new_badges']),
        durationSec: asInt(j['duration_sec']),
      );

  final int score;
  final int correctCount;
  final int total;
  final bool passed;
  final int rankDelta;
  final List<String> newBadges;
  final int durationSec;
}

/// `GET /test/:id/result` — the only payload that carries correct answers.
///
/// `answer_index` and `explanation` are gated on `tests.flags.answers` and
/// `tests.flags.explain`; a center can turn either off, and then the field is
/// simply absent.
class TestResult {
  const TestResult({
    required this.testId,
    required this.title,
    required this.score,
    required this.correctCount,
    required this.total,
    required this.passed,
    required this.questions,
    this.submittedAt,
    this.durationSec = 0,
  });

  factory TestResult.fromJson(Map<String, dynamic> j) => TestResult(
        testId: asString(j['id'] ?? j['test_id']),
        title: asString(j['title']),
        score: asInt(j['score']),
        correctCount: asInt(j['correct_count']),
        total: asInt(j['total'] ?? j['question_count']),
        passed: asBool(j['passed']),
        questions: mapList(j['questions'], ResultQuestion.fromJson)
          ..sort((a, b) => a.position.compareTo(b.position)),
        submittedAt: asDate(j['submitted_at']),
        durationSec: asInt(j['duration_sec']),
      );

  final String testId;
  final String title;
  final int score;
  final int correctCount;
  final int total;
  final bool passed;
  final List<ResultQuestion> questions;
  final DateTime? submittedAt;
  final int durationSec;

  /// True when the center turned answer review off — the score stands alone.
  bool get answersHidden => questions.isEmpty || questions.every((q) => q.answerIndex == null);
}

class ResultQuestion {
  const ResultQuestion({
    required this.id,
    required this.position,
    required this.text,
    required this.options,
    this.answerIndex,
    this.chosenIndex,
    this.explanation,
    this.skill,
  });

  factory ResultQuestion.fromJson(Map<String, dynamic> j) => ResultQuestion(
        id: asString(j['id']),
        position: asInt(j['position']),
        text: asString(j['text']),
        options: asStringList(j['options']),
        answerIndex: asIntOrNull(j['answer_index']),
        chosenIndex: asIntOrNull(j['chosen_index']),
        explanation: asStringOrNull(j['explanation']),
        skill: asStringOrNull(j['skill']),
      );

  final String id;
  final int position;
  final String text;
  final List<String> options;
  final int? answerIndex;
  final int? chosenIndex;
  final String? explanation;
  final String? skill;

  /// Unanswered counts as incorrect — the same rule the server grades by.
  bool get isCorrect => answerIndex != null && chosenIndex == answerIndex;

  bool get isUnanswered => chosenIndex == null;
}
