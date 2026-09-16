import 'package:flutter_test/flutter_test.dart';
import 'package:stepix/core/api/api_exception.dart';
import 'package:stepix/data/models/student_models.dart';
import 'package:stepix/data/models/teacher_models.dart';
import 'package:stepix/data/repositories/auth_repository.dart';
import 'package:stepix/data/repositories/profile_repository.dart';
import 'package:stepix/data/repositories/student_repository.dart';
import 'package:stepix/data/repositories/teacher_repository.dart';

import '../fake_api_client.dart';

/// What each repository sends, and where — the half of the contract a model test
/// cannot see.
void main() {
  group('student repository', () {
    test('tests send the state wire value and paging, and read a page', () async {
      final api = FakeApiClient({
        'GET /test': {
          'total': 7,
          'data': [
            {'id': 't1', 'state': 'in_progress'},
          ],
        },
      });
      final page = await StudentRepository(api).tests(state: TestState.inProgress, page: 2);
      expect(api.bodies['GET /test'], {'state': 'in_progress', 'page': 2, 'limit': 20});
      expect(page.total, 7);
      expect(page.items.single.state, TestState.inProgress);
    });

    test('a bare array from /test is a single full page', () async {
      final api = FakeApiClient({
        'GET /test': [
          {'id': 'a'},
          {'id': 'b'},
        ],
      });
      final page = await StudentRepository(api).tests();
      expect(page.total, 2);
      expect((api.bodies['GET /test']! as Map).containsKey('state'), isFalse);
    });

    test('an answer sends only the field for its type', () async {
      final api = FakeApiClient({'POST /test/t1/answer': {'saved': true}});
      final repo = StudentRepository(api);

      await repo.answer(testId: 't1', studentTestId: 'st', questionId: 'q', chosenIndex: 2, timeSpentMs: 5);
      expect(api.bodies['POST /test/t1/answer'], {
        'student_test_id': 'st',
        'question_id': 'q',
        'chosen_index': 2,
        'time_spent_ms': 5,
      });

      await repo.answer(testId: 't1', studentTestId: 'st', questionId: 'q', dragAnswer: [1, 0], timeSpentMs: 0);
      final body = api.bodies['POST /test/t1/answer']! as Map;
      expect(body['drag_answer'], [1, 0]);
      expect(body.containsKey('chosen_index'), isFalse);
      expect(body.containsKey('chosen_indexes'), isFalse);
    });

    test('start, submit and result hit the test\'s own paths', () async {
      final api = FakeApiClient({
        'POST /test/t1/start': {'student_test_id': 'st', 'questions': []},
        'POST /test/t1/submit': {'score': 80, 'passed': true},
        'GET /test/t1/result': {'title': 'R', 'score': 80},
        'GET /test/t1': {'id': 't1', 'attempts_left': 1},
      });
      final repo = StudentRepository(api);
      expect((await repo.start('t1')).studentTestId, 'st');
      expect((await repo.submit(testId: 't1', studentTestId: 'st')).passed, isTrue);
      expect(api.bodies['POST /test/t1/submit'], {'student_test_id': 'st'});
      expect((await repo.result('t1')).score, 80);
      expect((await repo.test('t1')).canStart, isTrue);
    });

    test('a solution upload sends every page in one request', () async {
      final api = FakeApiClient({'POST /test/t1/solution': {'state': 'waiting', 'pages': 2}});
      final sheet = await StudentRepository(api).uploadSolution('t1', ['/a.jpg', '/b.jpg']);
      expect(api.bodies['POST /test/t1/solution'], ['/a.jpg', '/b.jpg']);
      expect(sheet?.pages, 2);
    });

    test('an upload that answers null yields no sheet', () async {
      final api = FakeApiClient({'POST /test/t1/solution': null});
      expect(await StudentRepository(api).uploadSolution('t1', ['/a.jpg']), isNull);
    });

    test('practice sends the subject in the query and difficulty only when chosen', () async {
      final api = FakeApiClient({
        'GET /practice/program': {'subject': {'id': 's', 'name': 'M'}, 'branches': []},
        'POST /practice/generate': {'job_id': 'j', 'test_id': 't'},
        'GET /practice/generate/j': {'state': 'ready', 'test_id': 't'},
        'GET /practice/quota': {'remaining': 3, 'limit': 5},
        'GET /practice/subjects': [
          {'id': 's', 'name': 'M'},
        ],
      });
      final repo = StudentRepository(api);
      await repo.practiceProgram('s');
      expect(api.bodies['GET /practice/program'], {'subject_id': 's'});
      await repo.generatePractice(topicId: 'tp', questionCount: 10);
      expect(api.bodies['POST /practice/generate'], {'topic_id': 'tp', 'question_count': 10});
      await repo.generatePractice(topicId: 'tp', questionCount: 10, difficulty: TestDifficulty.hard);
      expect((api.bodies['POST /practice/generate']! as Map)['difficulty'], 'hard');
      expect((await repo.practiceGenerationState('j')).isDone, isTrue);
      expect((await repo.practiceQuota()).remaining, 3);
      expect((await repo.practiceSubjects()).single.id, 's');
    });

    test('home, groups, leaderboard and badges read their endpoints', () async {
      final api = FakeApiClient({
        'GET /home': {'streak_days': 3},
        'GET /group': [
          {'id': 'g'},
        ],
        'GET /group/g': {'group': {'id': 'g'}, 'classmates': []},
        'GET /leaderboard': {'my_rank': 1, 'leaders': []},
        'GET /badge': [
          {'code': 'first_test', 'earned': true},
        ],
        'GET /progress': {'trend': []},
        'GET /test/t/solution': {'solution_required': true, 'solution_pages': 3},
      });
      final repo = StudentRepository(api);
      expect((await repo.home()).streakDays, 3);
      expect((await repo.groups()).single.id, 'g');
      expect((await repo.group('g')).group.id, 'g');
      expect((await repo.leaderboard()).isRanked, isTrue);
      expect((await repo.badges()).single.earned, isTrue);
      expect((await repo.progress()).isEmpty, isTrue);
      expect((await repo.solution('t')).pages, 3);
    });
  });

  group('teacher repository', () {
    test('program sends subject_id only when one is chosen', () async {
      final api = FakeApiClient({
        'GET /teacher/program': {'subject': {'id': 's2', 'name': 'F'}, 'branches': []},
      });
      final repo = TeacherRepository(api);

      await repo.program();
      expect(api.bodies['GET /teacher/program'], <String, dynamic>{});

      await repo.program(subjectId: '');
      expect(api.bodies['GET /teacher/program'], <String, dynamic>{});

      final p = await repo.program(subjectId: 's2');
      expect(api.bodies['GET /teacher/program'], {'subject_id': 's2'});
      expect(p.subjectId, 's2');
    });

    test('a new section carries the subject it belongs to', () async {
      final api = FakeApiClient({'POST /teacher/branch/create': {'id': 'b', 'name': 'N', 'topics': []}});
      final repo = TeacherRepository(api);

      await repo.createBranch(name: 'N', hint: '', subjectId: 's1');
      expect(api.bodies['POST /teacher/branch/create'], {
        'subject_id': 's1',
        'name_i18n': {'uz': 'N'},
      });

      await repo.createBranch(name: 'N', hint: 'H');
      final body = api.bodies['POST /teacher/branch/create']! as Map;
      expect(body.containsKey('subject_id'), isFalse);
      expect(body['hint_i18n'], {'uz': 'H'});
    });

    test('a topic is created under its branch', () async {
      final api = FakeApiClient({'POST /teacher/topic/create': {'id': 't', 'name': 'T', 'is_custom': true}});
      final topic = await TeacherRepository(api).createTopic(branchId: 'b', name: 'T');
      expect(api.bodies['POST /teacher/topic/create'], {
        'branch_id': 'b',
        'name_i18n': {'uz': 'T'},
      });
      expect(topic.isCustom, isTrue);
    });

    test('material goes up in one request and is polled by id', () async {
      final api = FakeApiClient({
        'POST /teacher/material/upload': [
          {'id': 'm1', 'kind': 'pdf', 'state': 'reading'},
          {'id': 'm2', 'kind': 'image', 'state': 'reading'},
        ],
        'GET /teacher/material/m1': {'id': 'm1', 'kind': 'pdf', 'state': 'ready', 'chars': 900},
      });
      final repo = TeacherRepository(api);

      final uploaded = await repo.uploadMaterial(['/a.pdf', '/b.jpg']);
      expect(api.bodies['POST /teacher/material/upload'], ['/a.pdf', '/b.jpg']);
      expect(uploaded.map((m) => m.id), ['m1', 'm2']);

      final polled = await repo.material('m1');
      expect(polled.isReady, isTrue);
      expect(polled.chars, 900);
    });

    test('topics drawn from material are marked custom and from material', () async {
      final api = FakeApiClient({
        'POST /teacher/topic/from-material': {
          'topics': [
            {'id': 't1', 'name': 'Kuch', 'position': 3},
          ],
        },
      });
      final topics = await TeacherRepository(api).topicsFromMaterial(branchId: 'b', materialIds: ['m1']);
      expect(api.bodies['POST /teacher/topic/from-material'], {
        'branch_id': 'b',
        'material_ids': ['m1'],
      });
      expect(topics.single.isCustom, isTrue);
      expect(topics.single.fromMaterial, isTrue);
      expect(topics.single.position, 3);
    });

    test('a student\'s solution sheet goes to that attempt\'s path', () async {
      final api = FakeApiClient({'POST /teacher/test/t1/student/st9/solution': {'state': 'waiting'}});
      await TeacherRepository(api).uploadStudentSolution('t1', 'st9', ['/p1.jpg']);
      expect(api.calls, ['POST /teacher/test/t1/student/st9/solution']);
      expect(api.bodies['POST /teacher/test/t1/student/st9/solution'], ['/p1.jpg']);
    });

    test('generate sends the whole configuration, pages only when a sheet is required', () async {
      final api = FakeApiClient({'POST /teacher/test/generate': {'job_id': 'j', 'test_id': 't'}});
      final repo = TeacherRepository(api);

      await repo.generate(
        topicId: 'tp',
        groupIds: ['g1'],
        questionCount: 15,
        difficulty: TestDifficulty.mixed,
        timeLimitMin: 25,
        solutionPages: 4,
      );
      var body = api.bodies['POST /teacher/test/generate']! as Map;
      expect(body['topic_id'], 'tp');
      expect(body['group_ids'], ['g1']);
      expect(body['variant_mode'], 'same');
      expect(body['solution_required'], isFalse);
      expect(body.containsKey('solution_pages'), isFalse);
      expect(body.containsKey('question_types'), isFalse);
      expect(body.containsKey('pass_score'), isFalse);

      final due = DateTime.utc(2026, 9, 20, 18);
      await repo.generate(
        topicId: 'tp',
        groupIds: ['g1'],
        questionCount: 15,
        difficulty: TestDifficulty.hard,
        timeLimitMin: 25,
        passScore: 60,
        dueAt: due,
        questionTypes: {'multiple_choice'},
        solutionRequired: true,
        solutionPages: 4,
      );
      body = api.bodies['POST /teacher/test/generate']! as Map;
      expect(body['solution_pages'], 4);
      expect(body['pass_score'], 60);
      expect(body['question_types'], ['multiple_choice']);
      expect(body['due_at'], '2026-09-20T18:00:00.000Z');
    });

    test('the PDF is downloaded with the key by default', () async {
      final api = FakeApiClient({'POST /teacher/test/t1/pdf': <int>[37, 80, 68, 70]});
      final bytes = await TeacherRepository(api).testPdf('t1');
      expect(bytes, [37, 80, 68, 70]);
      expect(api.bodies['POST /teacher/test/t1/pdf'], {'test_id': 't1', 'with_key': true});
    });

    test('scans upload one file per call; assign and correct post their ids', () async {
      final api = FakeApiClient({
        'POST /teacher/test/t1/scan': {'ok': true},
        'GET /teacher/test/t1/scan': [
          {'id': 's1', 'state': 'unmatched'},
        ],
        'POST /teacher/scan/assign': null,
        'POST /teacher/scan/correct': null,
      });
      final repo = TeacherRepository(api);
      await repo.uploadScan('t1', '/x.jpg');
      expect(api.bodies['POST /teacher/test/t1/scan'], '/x.jpg');
      expect((await repo.scans('t1')).single.isMatched, isFalse);
      await repo.assignScan('s1', 'st1');
      expect(api.bodies['POST /teacher/scan/assign'], {'scan_id': 's1', 'student_test_id': 'st1'});
      await repo.correctScan('s1', {'1': 'B'});
      expect(api.bodies['POST /teacher/scan/correct'], {'scan_id': 's1', 'answers': {'1': 'B'}});
    });

    test('attendance sends a date-only lesson date and wire statuses', () async {
      final api = FakeApiClient({'POST /teacher/attendance': null});
      await TeacherRepository(api).markAttendance(
        groupId: 'g',
        lessonDate: DateTime(2026, 3, 7, 15, 45),
        records: const [AttendanceMark(studentId: 's', status: AttendanceStatus.late)],
      );
      expect(api.bodies['POST /teacher/attendance'], {
        'group_id': 'g',
        'lesson_date': '2026-03-07',
        'records': [
          {'student_id': 's', 'status': 'late'},
        ],
      });
    });

    test('knowledge uploads carry title and kind beside the photos', () async {
      final api = FakeApiClient({
        'POST /teacher/knowledge/source': {'id': 'k', 'state': 'queued'},
        'POST /teacher/knowledge/source/paging': {
          'data': [
            {'id': 'k'},
          ],
        },
        'POST /teacher/knowledge/source/k/retry': null,
        'DELETE /teacher/knowledge/source/k': null,
        'GET /teacher/knowledge/source/k': {'id': 'k', 'knowledge': []},
      });
      final repo = TeacherRepository(api);
      await repo.uploadKnowledge(title: 'Quiz', kind: 'worked', paths: ['/a.jpg']);
      expect(api.bodies['POST /teacher/knowledge/source'], {
        'files': ['/a.jpg'],
        'title': 'Quiz',
        'kind': 'worked',
      });
      expect((await repo.knowledgeSources()).single.id, 'k');
      expect(api.bodies['POST /teacher/knowledge/source/paging'], {'page': 1, 'limit': 50});
      await repo.retryKnowledge('k');
      await repo.deleteKnowledge('k');
      expect((await repo.knowledgeSource('k')).items, isEmpty);
      expect(api.calls, contains('DELETE /teacher/knowledge/source/k'));
    });

    test('publish returns how many students were notified; answers are corrected by slot', () async {
      final api = FakeApiClient({
        'POST /teacher/test/t/publish': {'notified': 14},
        'POST /teacher/test/t/student/st/correct': {'score': 90, 'correct_count': 9, 'total': 10},
        'GET /teacher/test/t/student/st': {'student': {'full_name': 'A'}, 'questions': []},
        'GET /teacher/test/t/paper': {'variant_mode': 'same', 'common': []},
        'GET /teacher/test/t/paper/st': {'student': {'full_name': 'A'}, 'questions': []},
      });
      final repo = TeacherRepository(api);
      expect(await repo.publishTest('t'), 14);
      final r = await repo.correctAnswers('t', 'st', {'1': 'A', '2': null});
      expect(r.score, 90);
      expect(api.bodies['POST /teacher/test/t/student/st/correct'], {
        'answers': {'1': 'A', '2': null},
      });
      expect((await repo.studentAnswers('t', 'st')).fullName, 'A');
      expect((await repo.paperOverview('t')).isSame, isTrue);
      expect((await repo.studentPaper('t', 'st')).fullName, 'A');
    });

    test('a server error surfaces as the ApiException the screen shows', () async {
      final api = FakeApiClient({
        'POST /teacher/test/generate': ApiException(message: 'Bu guruh sizga biriktirilmagan', code: 20713),
      });
      expect(
        () => TeacherRepository(api).generate(
          topicId: 't',
          groupIds: ['x'],
          questionCount: 5,
          difficulty: TestDifficulty.easy,
          timeLimitMin: 5,
        ),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 20713)),
      );
    });
  });

  group('auth repository', () {
    test('phones are normalised before they are sent', () {
      expect(normalizePhone('+998 90 123 45 67'), '998901234567');
      expect(normalizePhone('901234567'), '998901234567');
      expect(normalizePhone('8998901234567'), '998901234567');
      expect(normalizePhone('12345'), '12345');
    });

    test('a login without tokens is an ApiException, not a crash', () async {
      final api = FakeApiClient({'POST /auth/login': {'user': {'id': 'u'}}});
      expect(
        () => AuthRepository(api).login(phone: '901234567', password: 'p'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 502)),
      );
      expect(api.bodies['POST /auth/login'], {'phone': '998901234567', 'password': 'p'});
    });

    test('logout sends only the tokens it has', () async {
      final api = FakeApiClient({'POST /auth/logout': null, 'POST /auth/change-password': null});
      final repo = AuthRepository(api);
      await repo.logout(refreshToken: 'r', fcmToken: '');
      expect(api.bodies['POST /auth/logout'], {'refresh_token': 'r'});
      await repo.changePassword(currentPassword: 'a', newPassword: 'b');
      expect(api.bodies['POST /auth/change-password'], {'current_password': 'a', 'new_password': 'b'});
    });
  });

  group('profile repository', () {
    test('an oversized avatar fails before any upload', () async {
      final api = FakeApiClient({});
      expect(
        () => ProfileRepository(api).uploadAvatar('/a.jpg', sizeBytes: ProfileRepository.maxAvatarBytes + 1),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 413)),
      );
      expect(api.calls, isEmpty);
    });

    test('the avatar url is read from avatar_url or url', () async {
      final api = FakeApiClient({'POST /profile/avatar': {'url': 'http://x/a.png'}});
      expect(await ProfileRepository(api).uploadAvatar('/a.jpg', sizeBytes: 10), 'http://x/a.png');
    });

    test('checkout accepts only payme and click', () async {
      final api = FakeApiClient({
        'POST /subscription/checkout': {'payment_url': 'https://pay', 'transaction_id': 'tx'},
      });
      final repo = ProfileRepository(api);
      expect(() => repo.checkout('paypal'), throwsA(isA<ApiException>()));
      final session = await repo.checkout('click');
      expect(session.paymentUrl, 'https://pay');
      expect(api.bodies['POST /subscription/checkout'], {'provider': 'click'});
    });

    test('mark-read without ids marks everything, by ref marks the twin', () async {
      final api = FakeApiClient({'POST /notification/read': null, 'DELETE /fcm-token': null});
      final repo = ProfileRepository(api);
      await repo.markRead();
      expect(api.bodies['POST /notification/read'], <String, dynamic>{});
      await repo.markReadByRef('test_assigned', 't1');
      expect(api.bodies['POST /notification/read'], {'type': 'test_assigned', 'ref_id': 't1'});
      await repo.unregisterDevice('tok');
      expect(api.bodies['DELETE /fcm-token'], {'token': 'tok'});
    });

    test('an update trims the name and sends the language', () async {
      final api = FakeApiClient({'PUT /profile': {'user': {'id': 'u', 'full_name': 'Ali'}}});
      await ProfileRepository(api).update(fullName: '  Ali  ', language: 'ru');
      expect(api.bodies['PUT /profile'], {'full_name': 'Ali', 'language': 'ru'});
    });
  });
}
