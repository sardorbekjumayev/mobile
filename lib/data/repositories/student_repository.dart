import '../../core/api/api_client.dart';
import '../../core/api/envelope.dart';
import '../../core/util/json.dart';
import '../models/exam_models.dart';
import '../models/rank_models.dart';
import '../models/student_models.dart';
import '../models/teacher_models.dart'
    show TestDifficulty, TeacherProgram, TeacherQuota, GenerationJob;

class StudentRepository {
  const StudentRepository(this._api);

  final ApiClient _api;

  Future<StudentHome> home() async => StudentHome.fromJson(asMap(await _api.get('/home')));

  Future<StudentProgress> progress() async =>
      StudentProgress.fromJson(asMap(await _api.get('/progress')));

  Future<List<StudentGroup>> groups() async =>
      mapList(await _api.get('/group'), StudentGroup.fromJson);

  Future<StudentGroupDetail> group(String id) async =>
      StudentGroupDetail.fromJson(asMap(await _api.get('/group/$id')));

  Future<Page<TestSummary>> tests({TestState? state, int page = 1, int limit = 20}) async {
    final data = await _api.get('/test', query: {
      if (state != null) 'state': state.wire,
      'page': page,
      'limit': limit,
    });
    return Page.fromJson(data, TestSummary.fromJson);
  }

  Future<TestSummary> test(String id) async =>
      TestSummary.fromJson(asMap(await _api.get('/test/$id')));

  Future<TestAttempt> start(String testId) async =>
      TestAttempt.fromJson(asMap(await _api.post('/test/$testId/start')));

  /// Idempotent per question — the endpoint upserts on
  /// `(student_test_id, question_id)`, so a retry after a flaky connection
  /// never duplicates a row or double-counts a question.
  Future<AnswerAck> answer({
    required String testId,
    required String studentTestId,
    required String questionId,
    required int chosenIndex,
    required int timeSpentMs,
  }) async {
    final data = await _api.post('/test/$testId/answer', body: {
      'student_test_id': studentTestId,
      'question_id': questionId,
      'chosen_index': chosenIndex,
      'time_spent_ms': timeSpentMs,
    });
    return AnswerAck.fromJson(asMap(data));
  }

  /// Unanswered questions count as incorrect. A second submit returns `20802`
  /// and the first submission stands.
  Future<SubmitOutcome> submit({
    required String testId,
    required String studentTestId,
  }) async {
    final data = await _api.post('/test/$testId/submit', body: {
      'student_test_id': studentTestId,
    });
    return SubmitOutcome.fromJson(asMap(data));
  }

  Future<TestResult> result(String testId) async =>
      TestResult.fromJson(asMap(await _api.get('/test/$testId/result')));

  Future<Leaderboard> leaderboard() async =>
      Leaderboard.fromJson(asMap(await _api.get('/leaderboard')));

  Future<List<Badge>> badges() async => mapList(await _api.get('/badge'), Badge.fromJson);

  // ── practice papers ───────────────────────────────────────────────

  /// Subjects I can practice — one per group I'm enrolled in.
  Future<List<PracticeSubject>> practiceSubjects() async =>
      mapList(await _api.get('/practice/subjects'), PracticeSubject.fromJson);

  /// Branches and topics for one subject — same shape as the teacher's
  /// `program()`, so the same topic-picker sheet works for both.
  Future<TeacherProgram> practiceProgram(String subjectId) async => TeacherProgram.fromJson(
        asMap(await _api.get('/practice/program', query: {'subject_id': subjectId})),
      );

  /// This month's practice-paper allowance.
  Future<TeacherQuota> practiceQuota() async =>
      TeacherQuota.fromJson(asMap(await _api.get('/practice/quota')));

  Future<GenerationJob> generatePractice({
    required String topicId,
    required int questionCount,
    TestDifficulty? difficulty,
  }) async {
    final data = await _api.post('/practice/generate', body: {
      'topic_id': topicId,
      'question_count': questionCount,
      if (difficulty != null) 'difficulty': difficulty.wire,
    });
    return GenerationJob.started(asMap(data));
  }

  Future<GenerationJob> practiceGenerationState(String jobId) async => GenerationJob.polled(
        asMap(await _api.get('/practice/generate/$jobId')),
        jobId,
      );
}
