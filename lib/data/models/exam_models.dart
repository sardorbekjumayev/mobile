import '../../core/util/json.dart';
import 'solution_models.dart';

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
    this.timeLimitMin,
    this.solutionRequired = false,
    this.solutionPages = 0,
  });

  factory TestAttempt.fromJson(Map<String, dynamic> j) => TestAttempt(
        studentTestId: asString(j['student_test_id']),
        attemptNo: asInt(j['attempt_no'], 1),
        questions: mapList(j['questions'], ExamQuestion.fromJson)
          ..sort((a, b) => a.position.compareTo(b.position)),
        expiresAt: asDate(j['expires_at']),
        timeLimitMin: asIntOrNull(j['time_limit_min']),
        solutionRequired: asBool(j['solution_required']),
        solutionPages: asInt(j['solution_pages']),
      );

  final String studentTestId;
  final int attemptNo;
  final List<ExamQuestion> questions;

  /// Server-issued (`now + time_limit_min`). The client's countdown is
  /// decoration: a submit after this instant is still accepted and graded on
  /// the answers that arrived before it.
  final DateTime? expiresAt;

  /// The test's own limit, and the ceiling on [remaining].
  final int? timeLimitMin;

  /// Submit is refused (`20811`) until the worked solution sheet is uploaded.
  final bool solutionRequired;
  final int solutionPages;

  /// Time left, clamped to the test's limit.
  ///
  /// `expires_at` is computed server-side and compared against the *phone's*
  /// clock here, so a device set a day behind — or a stale expiry — produced a
  /// countdown of six hundred thousand hours. A student can never have more
  /// time left than the test allows, so that is the cap.
  Duration? get remaining {
    if (expiresAt == null) return null;
    final left = expiresAt!.difference(DateTime.now());
    if (left.isNegative) return Duration.zero;
    final limit = timeLimitMin;
    if (limit == null) return left;
    final ceiling = Duration(minutes: limit);
    return left > ceiling ? ceiling : left;
  }
}

/// The server's `QuestionType` enum, mirrored as plain strings rather than a
/// Dart `enum` — a response missing `type` entirely (an older payload, or a
/// backend endpoint that hasn't been extended yet) must still parse as the
/// one type that always existed: `single_choice`.
class QuestionKind {
  static const singleChoice = 'single_choice';
  static const multipleChoice = 'multiple_choice';
  static const imageBased = 'image_based';
  static const dragAndDrop = 'drag_and_drop';
}

String questionTypeOf(dynamic v) {
  const known = {
    QuestionKind.singleChoice,
    QuestionKind.multipleChoice,
    QuestionKind.imageBased,
    QuestionKind.dragAndDrop,
  };
  final s = v?.toString();
  return known.contains(s) ? s! : QuestionKind.singleChoice;
}

/// `drag_and_drop`'s matching exercise — items on the left, targets on the
/// right. `correct` is the answer key: present on the result/teacher-review
/// payloads, empty on the pre-submission ones (`POST /test/:id/start`) where
/// it must never be shipped to the device.
class DragItems {
  const DragItems({this.items = const [], this.targets = const [], this.correct = const []});

  factory DragItems.fromJson(dynamic j) {
    if (j == null) return const DragItems();
    final m = asMap(j);
    return DragItems(
      items: asStringList(m['items']),
      targets: asStringList(m['targets']),
      correct: asIntList(m['correct']),
    );
  }

  final List<String> items;
  final List<String> targets;
  final List<int> correct;

  bool get isEmpty => items.isEmpty;
}

class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.position,
    required this.text,
    required this.options,
    this.type = QuestionKind.singleChoice,
    this.skill,
    this.figure,
    this.mediaUrl,
    this.mediaHint,
    this.dragItems,
    this.givenIndex,
    this.givenIndexes,
    this.givenDrag,
  });

  /// `POST /test/:id/start` sends a matching exercise's `items`/`targets` at
  /// the top level of the question, not under `drag_items` — reading only the
  /// nested key left every `drag_and_drop` question blank with its Next button
  /// permanently disabled. Both shapes are accepted.
  factory ExamQuestion.fromJson(Map<String, dynamic> j) => ExamQuestion(
        id: asString(j['id']),
        position: asInt(j['position']),
        text: asString(j['text']),
        options: asStringList(j['options']),
        type: questionTypeOf(j['type']),
        skill: asStringOrNull(j['skill']),
        figure: j['figure'] == null ? null : QuestionFigure.fromJson(asMap(j['figure'])),
        mediaUrl: asStringOrNull(j['media_url']),
        mediaHint: asStringOrNull(j['media_hint']),
        dragItems: j['drag_items'] != null
            ? DragItems.fromJson(j['drag_items'])
            : (j['items'] != null || j['targets'] != null)
                ? DragItems(items: asStringList(j['items']), targets: asStringList(j['targets']))
                : null,
        givenIndex: asIntOrNull(j['chosen_index']),
        givenIndexes: j['chosen_indexes'] == null ? null : asIntList(j['chosen_indexes']),
        givenDrag: j['drag_answer'] == null ? null : asIntList(j['drag_answer']),
      );

  final String id;
  final int position;
  final String text;
  final List<String> options;
  final String type;
  final String? skill;
  final QuestionFigure? figure;

  /// `image_based` — the attached file, once a teacher has attached one. Null means "not attached yet", which a `ready` test can
  /// never actually reach the student with (`start` refuses it server-side),
  /// so in practice this is only ever null while the question type itself is
  /// unset — see `QuestionKind`'s own doc.
  final String? mediaUrl;
  final String? mediaHint;
  final DragItems? dragItems;

  /// What this student already answered, when `start` resumes an attempt
  /// they left mid-way — so the runner reopens on their paper, not a blank one.
  final int? givenIndex;
  final List<int>? givenIndexes;
  final List<int>? givenDrag;

  bool get isMultipleChoice => type == QuestionKind.multipleChoice;
  bool get isDragAndDrop => type == QuestionKind.dragAndDrop;
  bool get isImage => type == QuestionKind.imageBased;

  /// Whether this question has a picture to show at all.
  ///
  /// An `image_based` question's picture is the stimulus, but an illustrated
  /// test also draws pictures for ordinary questions — and a picture the
  /// center paid to generate has to reach the student who is answering.
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
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
    this.solutionRequired = false,
    this.solutionPages = 0,
    this.solution,
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
        solutionRequired: asBool(j['solution_required']),
        solutionPages: asInt(j['solution_pages']),
        solution: Solution.maybe(j['solution']),
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

  final bool solutionRequired;
  final int solutionPages;

  /// Null when no sheet has been uploaded.
  final Solution? solution;

  /// True when the center turned answer review off — the score stands alone.
  bool get answersHidden => questions.isEmpty || questions.every((q) => !q.hasAnswerKey);
}

class ResultQuestion {
  const ResultQuestion({
    required this.id,
    required this.position,
    required this.text,
    required this.options,
    this.type = QuestionKind.singleChoice,
    this.answerIndex,
    this.chosenIndex,
    this.answerIndexes,
    this.chosenIndexes,
    this.dragItems,
    this.dragAnswer,
    this.isCorrectServer,
    this.explanation,
    this.skill,
  });

  factory ResultQuestion.fromJson(Map<String, dynamic> j) => ResultQuestion(
        id: asString(j['id']),
        position: asInt(j['position']),
        text: asString(j['text']),
        options: asStringList(j['options']),
        type: questionTypeOf(j['type']),
        answerIndex: asIntOrNull(j['answer_index']),
        chosenIndex: asIntOrNull(j['chosen_index']),
        answerIndexes: j['answer_indexes'] == null ? null : asIntList(j['answer_indexes']),
        chosenIndexes: j['chosen_indexes'] == null ? null : asIntList(j['chosen_indexes']),
        dragItems: j['items'] == null && j['targets'] == null
            ? null
            : DragItems(
                items: asStringList(j['items']),
                targets: asStringList(j['targets']),
                correct: asIntList(j['correct']),
              ),
        dragAnswer: j['drag_answer'] == null ? null : asIntList(j['drag_answer']),
        isCorrectServer: j['is_correct'] as bool?,
        explanation: asStringOrNull(j['explanation']),
        skill: asStringOrNull(j['skill']),
      );

  final String id;
  final int position;
  final String text;
  final List<String> options;
  final String type;
  final int? answerIndex;
  final int? chosenIndex;

  /// `multiple_choice` only.
  final List<int>? answerIndexes;
  final List<int>? chosenIndexes;

  /// `drag_and_drop` only — `dragItems.correct` is the key, `dragAnswer` is
  /// what this student matched, parallel to `dragItems.items`.
  final DragItems? dragItems;
  final List<int>? dragAnswer;

  /// The server's own verdict, when it sends one — always present from
  /// `GET /test/:id/result`, absent from screens built before rich types
  /// that only ever compared `chosenIndex == answerIndex` themselves.
  final bool? isCorrectServer;

  final String? explanation;
  final String? skill;

  bool get isMultipleChoice => type == QuestionKind.multipleChoice;
  bool get isDragAndDrop => type == QuestionKind.dragAndDrop;

  /// Unanswered counts as incorrect — the same rule the server grades by.
  bool get isCorrect {
    if (isCorrectServer != null) return isCorrectServer!;
    if (isMultipleChoice) {
      final chosen = {...(chosenIndexes ?? const [])};
      final correct = {...(answerIndexes ?? const [])};
      return chosen.isNotEmpty && chosen.length == correct.length && chosen.containsAll(correct);
    }
    if (isDragAndDrop) {
      final given = dragAnswer ?? const [];
      final correct = dragItems?.correct ?? const [];
      return given.isNotEmpty &&
          given.length == correct.length &&
          List.generate(given.length, (i) => given[i] == correct[i]).every((v) => v);
    }
    return answerIndex != null && chosenIndex == answerIndex;
  }

  bool get isUnanswered {
    if (isMultipleChoice) return chosenIndexes == null || chosenIndexes!.isEmpty;
    if (isDragAndDrop) return dragAnswer == null || dragAnswer!.isEmpty;
    return chosenIndex == null;
  }

  /// Whether the server actually sent this question's answer key — gated on
  /// `tests.flags.show_answers`, and shaped differently per type, so
  /// `TestResult.answersHidden` can't just check `answerIndex` the way it
  /// could before `multiple_choice`/`drag_and_drop` existed.
  bool get hasAnswerKey {
    if (isMultipleChoice) return answerIndexes != null;
    if (isDragAndDrop) return dragItems != null && dragItems!.correct.isNotEmpty;
    return answerIndex != null;
  }
}
