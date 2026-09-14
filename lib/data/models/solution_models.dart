import '../../core/util/json.dart';

/// The worked-solution sheet ("yechim varag'i") — photographed handwritten
/// work a teacher can require on a test. The photos themselves are deleted
/// once a vision model has read them; only the structured analysis stays.
enum SolutionState {
  waiting,
  analyzing,
  done,
  failed;

  /// Null when nothing has been uploaded — which is itself a state the UI
  /// renders ("Yuklanmagan"), so it is not folded into [waiting].
  static SolutionState? parse(dynamic v) => switch (asStringOrNull(v)) {
        'waiting' => SolutionState.waiting,
        'analyzing' => SolutionState.analyzing,
        'done' => SolutionState.done,
        'failed' => SolutionState.failed,
        _ => null,
      };

  /// Still on the server's queue — worth a refresh, not a re-upload.
  bool get isPending => this == SolutionState.waiting || this == SolutionState.analyzing;
}

/// `Solution` — what `GET test/:id/solution`, `GET test/:id/result` and the
/// teacher's student sheet all carry.
class Solution {
  const Solution({
    required this.state,
    required this.pages,
    this.uploadedAt,
    this.analyzedAt,
    this.error,
    this.analysis,
  });

  factory Solution.fromJson(Map<String, dynamic> j) => Solution(
        state: SolutionState.parse(j['state']) ?? SolutionState.waiting,
        pages: asInt(j['pages']),
        uploadedAt: asDate(j['uploaded_at']),
        analyzedAt: asDate(j['analyzed_at']),
        error: asStringOrNull(j['error']),
        analysis: j['analysis'] is Map<String, dynamic>
            ? SolutionResult.fromJson(asMap(j['analysis']))
            : null,
      );

  static Solution? maybe(dynamic v) => v is Map<String, dynamic> ? Solution.fromJson(v) : null;

  final SolutionState state;
  final int pages;
  final DateTime? uploadedAt;
  final DateTime? analyzedAt;
  final String? error;

  /// Present only when [state] is `done`.
  final SolutionResult? analysis;

  /// Missing or unreadable — the student has to (re-)upload.
  static bool needsUpload(Solution? s) => s == null || s.state == SolutionState.failed;
}

/// The error taxonomy the analysis counts by. Kept as wire strings — an
/// unknown key from a newer backend still renders, just under its raw name.
class SolutionErrorType {
  const SolutionErrorType._();

  static const none = 'none';
  static const calculation = 'calculation';
  static const formula = 'formula';
  static const concept = 'concept';
  static const units = 'units';
  static const misread = 'misread';
  static const incomplete = 'incomplete';
  static const noWork = 'no_work';

  static const all = [calculation, formula, concept, units, misread, incomplete, noWork];
}

class SolutionResult {
  const SolutionResult({
    required this.summary,
    required this.methodStyle,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    required this.errorCounts,
    required this.guessed,
    required this.noWork,
    required this.questions,
    this.legibility,
  });

  factory SolutionResult.fromJson(Map<String, dynamic> j) {
    final counts = <String, int>{};
    asMap(j['error_counts']).forEach((k, v) => counts[k] = asInt(v));
    final legibility = j['legibility'];
    return SolutionResult(
      summary: asString(j['summary']),
      methodStyle: asString(j['method_style']),
      strengths: asStringList(j['strengths']),
      weaknesses: asStringList(j['weaknesses']),
      recommendations: asStringList(j['recommendations']),
      legibility: legibility is num ? legibility.toDouble().clamp(0.0, 1.0) : null,
      errorCounts: counts,
      guessed: asInt(j['guessed']),
      noWork: asInt(j['no_work']),
      questions: mapList(j['questions'], SolutionQuestion.fromJson)
        ..sort((a, b) => a.n.compareTo(b.n)),
    );
  }

  final String summary;
  final String methodStyle;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;

  /// 0..1, null when the model could not judge it.
  final double? legibility;
  final Map<String, int> errorCounts;
  final int guessed;
  final int noWork;
  final List<SolutionQuestion> questions;
}

class SolutionQuestion {
  const SolutionQuestion({
    required this.n,
    required this.work,
    required this.errorType,
    required this.guessSuspected,
    this.method,
    this.note,
    this.isCorrect,
  });

  factory SolutionQuestion.fromJson(Map<String, dynamic> j) => SolutionQuestion(
        n: asInt(j['n']),
        work: asString(j['work'], 'none'),
        method: asStringOrNull(j['method']),
        errorType: asString(j['error_type'], SolutionErrorType.none),
        guessSuspected: asBool(j['guess_suspected']),
        note: asStringOrNull(j['note']),
        isCorrect: j['is_correct'] is bool ? j['is_correct'] as bool : null,
      );

  /// The question number as the student saw it.
  final int n;

  /// `full` · `partial` · `none`.
  final String work;
  final String? method;
  final String errorType;
  final bool guessSuspected;
  final String? note;
  final bool? isCorrect;
}

/// `GET test/:id/solution`.
class SolutionStatus {
  const SolutionStatus({required this.required, required this.pages, this.solution});

  factory SolutionStatus.fromJson(Map<String, dynamic> j) => SolutionStatus(
        required: asBool(j['solution_required']),
        pages: asInt(j['solution_pages'], 1),
        solution: Solution.maybe(j['solution']),
      );

  final bool required;
  final int pages;
  final Solution? solution;
}

/// `GET home` → `pending_solutions[]` — a graded test still missing its sheet.
class PendingSolution {
  const PendingSolution({
    required this.testId,
    required this.studentTestId,
    required this.title,
    required this.pages,
    required this.retry,
  });

  factory PendingSolution.fromJson(Map<String, dynamic> j) => PendingSolution(
        testId: asString(j['test_id']),
        studentTestId: asString(j['student_test_id']),
        title: asString(j['title']),
        pages: asInt(j['solution_pages'], 1),
        retry: asBool(j['retry']),
      );

  final String testId;
  final String studentTestId;
  final String title;
  final int pages;

  /// The last upload could not be read — ask again.
  final bool retry;
}
