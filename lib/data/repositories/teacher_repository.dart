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
