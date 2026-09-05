import '../../core/api/api_client.dart';
import '../../core/util/json.dart';
import '../models/teacher_models.dart';

class TeacherRepository {
  const TeacherRepository(this._api);

  final ApiClient _api;

  Future<TeacherHome> home() async =>
      TeacherHome.fromJson(asMap(await _api.get('/teacher/home')));

  Future<List<TeacherGroup>> groups() async =>
      mapList(await _api.get('/teacher/group'), TeacherGroup.fromJson);

  Future<TeacherGroupDetail> group(String id) async =>
      TeacherGroupDetail.fromJson(asMap(await _api.get('/teacher/group/$id')));

  /// Scoped: the student must be in one of this teacher's groups, otherwise the
  /// server answers `403` even inside the same center.
  Future<StudentDetail> student(String id) async =>
      StudentDetail.fromJson(asMap(await _api.get('/teacher/student/$id')));

  Future<List<TeacherTest>> tests() async =>
      mapList(await _api.get('/teacher/test'), TeacherTest.fromJson);

  Future<TeacherTestDetail> test(String id) async =>
      TeacherTestDetail.fromJson(asMap(await _api.get('/teacher/test/$id')));

  // ── test creation ──────────────────────────────────────────────────

  /// The teacher's own subject, its branches and their topics — one call, where
  /// the center panel drills down through three.
  Future<TeacherProgram> program() async =>
      TeacherProgram.fromJson(asMap(await _api.get('/teacher/program')));

  /// This month's generation allowance. Read before the form is drawn.
  Future<TeacherQuota> quota() async =>
      TeacherQuota.fromJson(asMap(await _api.get('/teacher/quota')));

  /// Queues a generation and returns the job to poll.
  ///
  /// The server refuses a group that is not this teacher's with `20713`, and a
  /// teacher who has spent their allowance with `20712` — both carry a message
  /// the screen can show as-is.
  Future<GenerationJob> generate({
    required String topicId,
    required List<String> groupIds,
    required int questionCount,
    required TestDifficulty difficulty,
    required int timeLimitMin,
    int? passScore,
    bool mixPrior = false,
    TestVariantMode variantMode = TestVariantMode.same,
    DateTime? dueAt,
  }) async {
    final data = await _api.post('/teacher/test/generate', body: {
      'topic_id': topicId,
      'group_ids': groupIds,
      'question_count': questionCount,
      'difficulty': difficulty.wire,
      'time_limit_min': timeLimitMin,
      'pass_score': ?passScore,
      'mix_prior': mixPrior,
      'variant_mode': variantMode.wire,
      if (dueAt != null) 'due_at': dueAt.toUtc().toIso8601String(),
    });
    return GenerationJob.started(asMap(data));
  }

  Future<GenerationJob> generationState(String jobId) async => GenerationJob.polled(
        asMap(await _api.get('/teacher/test/generate/$jobId')),
        jobId,
      );

  /// A new section under my own subject — neither panel has this until now.
  Future<ProgramBranch> createBranch({required String name, String? hint}) async =>
      ProgramBranch.fromJson(asMap(await _api.post('/teacher/branch/create', body: {
        'name_i18n': {'uz': name},
        if (hint != null && hint.isNotEmpty) 'hint_i18n': {'uz': hint},
      })));

  /// A new topic under one of my sections.
  Future<ProgramTopic> createTopic({
    required String branchId,
    required String name,
    String? hint,
  }) async =>
      ProgramTopic.fromJson(asMap(await _api.post('/teacher/topic/create', body: {
        'branch_id': branchId,
        'name_i18n': {'uz': name},
        if (hint != null && hint.isNotEmpty) 'hint_i18n': {'uz': hint},
      })));

  /// The printable test — QR-coded, one sheet per student. Raw bytes, not the
  /// usual JSON envelope.
  Future<List<int>> testPdf(String testId, {bool withKey = false}) => _api.downloadBytes(
        '/teacher/test/$testId/pdf',
        body: {'test_id': testId, 'with_key': withKey},
      );

  /// One student's sheet, question by question, in the frame they saw it.
  Future<StudentAnswerSheet> studentAnswers(String testId, String studentTestId) async =>
      StudentAnswerSheet.fromJson(
        asMap(await _api.get('/teacher/test/$testId/student/$studentTestId')),
      );

  /// Overrule the grading on one student's sheet — online or a paper scan,
  /// the same shape: slot number to the letter of the answer, `null` for
  /// unanswered. Replaces the sheet wholesale.
  Future<CorrectionResult> correctAnswers(
    String testId,
    String studentTestId,
    Map<String, String?> answers,
  ) async =>
      CorrectionResult.fromJson(asMap(await _api.post(
        '/teacher/test/$testId/student/$studentTestId/correct',
        body: {'answers': answers},
      )));

  // ── paper scanning ──────────────────────────────────────────────────

  /// Uploads one photographed answer sheet. Called once per photo, since
  /// [ApiClient.upload] takes a single file.
  Future<void> uploadScan(String testId, String filePath) =>
      _api.upload('/teacher/test/$testId/scan', field: 'files', filePath: filePath);

  Future<List<PaperScan>> scans(String testId) async =>
      mapList(await _api.get('/teacher/test/$testId/scan'), PaperScan.fromJson);

  /// "This sheet is Ali's." Attaches an unmatched sheet and grades it.
  Future<void> assignScan(String scanId, String studentTestId) => _api.post(
        '/teacher/scan/assign',
        body: {'scan_id': scanId, 'student_test_id': studentTestId},
      );

  /// Fixes the letters read off a sheet and re-grades it.
  Future<void> correctScan(String scanId, Map<String, String?> answers) =>
      _api.post('/teacher/scan/correct', body: {'scan_id': scanId, 'answers': answers});

  /// The one write a teacher makes. Upserts on
  /// `(group_id, student_id, lesson_date)`, so re-submitting the register
  /// corrects it instead of failing — which is what a teacher who mis-tapped
  /// is about to do.
  Future<void> markAttendance({
    required String groupId,
    required DateTime lessonDate,
    required List<AttendanceMark> records,
  }) =>
      _api.post('/teacher/attendance', body: {
        'group_id': groupId,
        'lesson_date': _isoDate(lessonDate),
        'records': records.map((r) => r.toJson()).toList(),
      });

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
