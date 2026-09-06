import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/exam_models.dart';
import '../../data/repositories/student_repository.dart';

enum RunnerPhase { loading, running, submitting, submitted, failed }

/// One question's in-progress answer, shaped by its type — exactly one of
/// the three is ever set for a given question.
class _Answer {
  const _Answer({this.single, this.multi, this.drag});

  /// single_choice / image_based / audio_based.
  final int? single;

  /// multiple_choice.
  final Set<int>? multi;

  /// drag_and_drop — one entry per item, `null` until that item is matched.
  final List<int?>? drag;
}

/// Drives the sit-a-test sequence: `start` → `answer`ⁿ → `submit`.
class TestRunnerController extends ChangeNotifier {
  TestRunnerController({required StudentRepository repository, required this.testId})
      : _repo = repository;

  final StudentRepository _repo;
  final String testId;

  RunnerPhase _phase = RunnerPhase.loading;
  TestAttempt? _attempt;
  int _index = 0;
  String? _error;
  SubmitOutcome? _outcome;
  Timer? _ticker;

  /// questionId → this student's answer so far.
  final Map<String, _Answer> _answers = {};

  /// Answers whose POST failed. Retried before submit, because the server
  /// grades what it received, not what the screen shows.
  final Set<String> _unsynced = {};

  /// When the current question first appeared, for `time_spent_ms`.
  DateTime _shownAt = DateTime.now();

  RunnerPhase get phase => _phase;

  TestAttempt? get attempt => _attempt;

  String? get error => _error;

  SubmitOutcome? get outcome => _outcome;

  List<ExamQuestion> get questions => _attempt?.questions ?? const [];

  int get index => _index;

  int get total => questions.length;

  ExamQuestion? get current => _index < questions.length ? questions[_index] : null;

  /// single_choice / image_based / audio_based only.
  int? get chosenIndex => current == null ? null : _answers[current!.id]?.single;

  /// multiple_choice only.
  Set<int> get chosenIndexes => current == null ? const {} : (_answers[current!.id]?.multi ?? const {});

  /// drag_and_drop only — one entry per item, `null` for an unmatched one.
  List<int?> get dragTargets {
    final q = current;
    if (q == null) return const [];
    final n = q.dragItems?.items.length ?? 0;
    return _answers[q.id]?.drag ?? List<int?>.filled(n, null);
  }

  /// Whether the current question has enough of an answer to move on —
  /// every drag item matched, at least one option checked, or one chosen.
  bool get hasAnswered {
    final q = current;
    if (q == null) return false;
    if (q.isMultipleChoice) return chosenIndexes.isNotEmpty;
    if (q.isDragAndDrop) {
      final d = dragTargets;
      return d.isNotEmpty && !d.contains(null);
    }
    return chosenIndex != null;
  }

  int get answeredCount => _answers.length;

  bool get isLast => total > 0 && _index == total - 1;

  bool get hasUnsynced => _unsynced.isNotEmpty;

  double get progress => total == 0 ? 0 : (_index + 1) / total;

  Duration? get remaining => _attempt?.remaining;

  Future<void> start() async {
    _phase = RunnerPhase.loading;
    _error = null;
    notifyListeners();
    try {
      final attempt = await _repo.start(testId);
      _attempt = attempt;
      _index = 0;
      _shownAt = DateTime.now();
      _phase = RunnerPhase.running;
      _startTicker();
    } on ApiException catch (e) {
      _error = e.message;
      _phase = RunnerPhase.failed;
    }
    notifyListeners();
  }

  /// Records the choice locally first, then pushes it. The endpoint upserts on
  /// `(student_test_id, question_id)`, so a retry can never double-count.
  /// single_choice / image_based / audio_based.
  Future<void> chooseSingle(int optionIndex) async {
    final question = current;
    if (question == null) return;
    _answers[question.id] = _Answer(single: optionIndex);
    notifyListeners();
    await _push(question, chosenIndex: optionIndex);
  }

  /// multiple_choice — toggles one option; any number may end up checked.
  Future<void> toggleMultiple(int optionIndex) async {
    final question = current;
    if (question == null) return;
    final next = {...(_answers[question.id]?.multi ?? const <int>{})};
    if (!next.remove(optionIndex)) next.add(optionIndex);
    _answers[question.id] = _Answer(multi: next);
    notifyListeners();
    await _push(question, chosenIndexes: next.toList());
  }

  /// drag_and_drop — pairs one item with one target. Pushed to the server
  /// only once every item has a target: a partial mapping isn't a valid
  /// `drag_answer` (it must be one entry per item), and pushing early would
  /// have the server reject a shape it doesn't recognise instead of just
  /// waiting for the rest of the matches.
  Future<void> setDragTarget(int itemIndex, int targetIndex) async {
    final question = current;
    if (question == null) return;
    final itemCount = question.dragItems?.items.length ?? 0;
    final next = [...(_answers[question.id]?.drag ?? List<int?>.filled(itemCount, null))];
    if (itemIndex < 0 || itemIndex >= next.length) return;
    next[itemIndex] = targetIndex;
    _answers[question.id] = _Answer(drag: next);
    notifyListeners();
    if (!next.contains(null)) {
      await _push(question, dragAnswer: next.cast<int>());
    }
  }

  Future<void> _push(
    ExamQuestion question, {
    int? chosenIndex,
    List<int>? chosenIndexes,
    List<int>? dragAnswer,
  }) async {
    final attempt = _attempt;
    if (attempt == null) return;
    final spent = DateTime.now().difference(_shownAt).inMilliseconds;
    try {
      await _repo.answer(
        testId: testId,
        studentTestId: attempt.studentTestId,
        questionId: question.id,
        chosenIndex: chosenIndex,
        chosenIndexes: chosenIndexes,
        dragAnswer: dragAnswer,
        timeSpentMs: spent,
      );
      _unsynced.remove(question.id);
    } on ApiException {
      // Keep the choice on screen and try again before submitting. Dropping it
      // because a packet was lost is the one failure the student cannot see.
      _unsynced.add(question.id);
    }
    notifyListeners();
  }

  void next() {
    if (_index >= total - 1) return;
    _index++;
    _shownAt = DateTime.now();
    notifyListeners();
  }

  void previous() {
    if (_index == 0) return;
    _index--;
    _shownAt = DateTime.now();
    notifyListeners();
  }

  void jumpTo(int index) {
    if (index < 0 || index >= total) return;
    _index = index;
    _shownAt = DateTime.now();
    notifyListeners();
  }

  Future<bool> submit() async {
    final attempt = _attempt;
    if (attempt == null || _phase == RunnerPhase.submitting) return false;

    _phase = RunnerPhase.submitting;
    _error = null;
    notifyListeners();

    await _flushUnsynced(attempt);

    try {
      _outcome = await _repo.submit(testId: testId, studentTestId: attempt.studentTestId);
      _phase = RunnerPhase.submitted;
      _ticker?.cancel();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      if (e.code == ErrorCodes.testAlreadySubmitted) {
        // The first submission stands; the result screen has the real numbers.
        _phase = RunnerPhase.submitted;
        _ticker?.cancel();
        notifyListeners();
        return true;
      }
      _error = e.message;
      _phase = RunnerPhase.running;
      notifyListeners();
      return false;
    }
  }

  Future<void> _flushUnsynced(TestAttempt attempt) async {
    for (final questionId in _unsynced.toList()) {
      final a = _answers[questionId];
      if (a == null) continue;
      final drag = a.drag;
      final dragAnswer = drag != null && !drag.contains(null) ? drag.cast<int>() : null;
      // A drag mapping still missing a target here never became "answered"
      // in the first place — nothing to flush for it.
      if (a.single == null && (a.multi?.isEmpty ?? true) && dragAnswer == null) continue;
      try {
        await _repo.answer(
          testId: testId,
          studentTestId: attempt.studentTestId,
          questionId: questionId,
          chosenIndex: a.single,
          chosenIndexes: a.multi?.toList(),
          dragAnswer: dragAnswer,
          timeSpentMs: 0,
        );
        _unsynced.remove(questionId);
      } on ApiException {
        // Submitting anyway: a submit after the deadline is graded on the
        // answers that did arrive, and losing the whole attempt to one
        // unreachable question is worse than losing that question.
      }
    }
  }

  /// Repaints the countdown once a second. `expires_at` is server-issued and
  /// this clock is decoration — reaching zero submits rather than locking the
  /// student out of answers they already gave.
  void _startTicker() {
    _ticker?.cancel();
    if (_attempt?.expiresAt == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_phase != RunnerPhase.running) return;
      final left = remaining;
      if (left != null && left == Duration.zero) {
        _ticker?.cancel();
        unawaited(submit());
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
