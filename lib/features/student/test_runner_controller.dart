import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/exam_models.dart';
import '../../data/repositories/student_repository.dart';

enum RunnerPhase { loading, running, submitting, submitted, failed }

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

  /// questionId → chosen option index.
  final Map<String, int> _answers = {};

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

  int? get chosenIndex => current == null ? null : _answers[current!.id];

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
  Future<void> choose(int optionIndex) async {
    final question = current;
    final attempt = _attempt;
    if (question == null || attempt == null) return;

    _answers[question.id] = optionIndex;
    notifyListeners();

    final spent = DateTime.now().difference(_shownAt).inMilliseconds;
    try {
      await _repo.answer(
        testId: testId,
        studentTestId: attempt.studentTestId,
        questionId: question.id,
        chosenIndex: optionIndex,
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
      final chosen = _answers[questionId];
      if (chosen == null) continue;
      try {
        await _repo.answer(
          testId: testId,
          studentTestId: attempt.studentTestId,
          questionId: questionId,
          chosenIndex: chosen,
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
