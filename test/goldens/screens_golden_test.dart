@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_fonts.dart';
import '../app_smoke_test.dart' show pumpApp;
import '../fake_api_client.dart';

/// Renders the screens at the template's own 390x844 and compares them with a
/// checked-in image.
///
/// These are the only tests in the suite that can catch a design regression —
/// a finder-based test passes just as happily when the layout has collapsed or
/// the typeface silently changed.
void main() {
  setUpAll(loadAppFonts);

  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  });

  testWidgets('welcome', (tester) async {
    await pumpApp(tester, api: FakeApiClient({
      'GET /settings': {...settingsJson, 'stats': {'students': 80, 'tests': 39, 'centers': 92}},
    }));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('welcome.png'));
  });

  testWidgets('student home', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(),
        'GET /settings': settingsJson,
        // Copied from `GET /v1/home` on the running server. A fixture invented
        // from the model reads back exactly what the model expects and proves
        // nothing; the first draft of this one used `tests_done` and
        // `{day, value}`, neither of which the API has ever sent, and the
        // golden dutifully recorded a screen full of zeroes.
        'GET /home': {
          'greeting': 'day',
          'streak_days': 5,
          'next_test': {
            'id': 't1',
            'title': 'Ingliz tili · Unit 4',
            'question_count': 20,
            'time_limit_min': 25,
            'state': 'new',
          },
          'avg_score': 78,
          'avg_score_delta': 4,
          'metrics': [
            {'key': 'tests_taken', 'value': 12},
            {'key': 'best_score', 'value': 92},
            {'key': 'groups', 'value': 2},
          ],
          'week': [
            {'date': '2026-08-28', 'tests': 1},
            {'date': '2026-08-29', 'tests': 2},
            {'date': '2026-08-30', 'tests': 0},
            {'date': '2026-08-31', 'tests': 1},
            {'date': '2026-09-01', 'tests': 3},
            {'date': '2026-09-02', 'tests': 0},
            {'date': '2026-09-03', 'tests': 1},
          ],
          'rank': 4,
          'empty_state': null,
        },
        'GET /group': [
          {
            'id': 'g1',
            'name': 'IELTS Evening',
            'subject': 'Ingliz tili',
            'level': 'B2',
            'teacher': {'id': 'u9', 'full_name': 'Kamola Tashpulatova', 'avatar_url': null},
            'schedule': [
              {'day': 1, 'start': '18:00', 'end': '19:30'},
            ],
            'room': '204',
            'students_count': 12,
            'my_avg_score': 71,
          },
        ],
      }),
    );
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('student_home.png'));
  });

  testWidgets('teacher home', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(role: 'teacher'),
        'GET /settings': settingsJson,
        // Also copied from the running server.
        'GET /teacher/home': {
          'kpis': {
            'groups': 3,
            'students': 32,
            'tests_this_month': 4,
            'avg_score': 74,
          },
          'attention': [
            {
              'type': 'not_started',
              'test_id': 't1',
              'title': 'Uchburchaklar',
              'group_id': 'g1',
              'group_name': 'Matematika · 9-sinf',
              'count': 11,
              'due_at': null,
            },
            {
              'type': 'inactive',
              'student_id': 's1',
              'full_name': 'Temur Sultonov',
              'days': 11,
            },
          ],
        },
        'GET /teacher/group': [
          {
            'id': 'g1',
            'name': 'Matematika · 9-sinf',
            'subject': 'Matematika',
            'level': '9',
            'room': '301',
            'schedule': [
              {'day': 3, 'start': '18:00', 'end': '19:30'},
            ],
            'capacity': 15,
            'students_count': 11,
            'avg_score': 74,
          },
        ],
      }),
    );
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('teacher_home.png'));
  });

  testWidgets('student tests', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(),
        'GET /settings': settingsJson,
        'GET /home': {'greeting': 'day', 'empty_state': null, 'metrics': [], 'week': []},
        'GET /group': const [],
        // The paged envelope `GET /v1/test` actually returns, answered per
        // `state` — the pending tab asks twice, once for each state it merges.
        'GET /test': (Object? query) {
          final state = (query as Map?)?['state'];
          Map<String, dynamic> row(
            String id,
            String title,
            String subject,
            String group,
            String rowState, {
            int? score,
          }) =>
              {
                'id': id,
                'student_test_id': 'st_$id',
                'title': title,
                'subject': subject,
                'group_name': group,
                'question_count': 20,
                'time_limit_min': 30,
                'pass_score': 70,
                'due_at': null,
                'state': rowState,
                'score': score,
                'attempts_left': rowState == 'submitted' ? 0 : 1,
              };

          final rows = switch (state) {
            'in_progress' => [
                row('t2', 'Uchburchaklar', 'Matematika', 'Matematika · 9-sinf', 'in_progress'),
              ],
            'submitted' => [
                row('t3', 'Past simple', 'Ingliz tili', 'IELTS Evening', 'submitted', score: 88),
                row('t4', 'Articles', 'Ingliz tili', 'IELTS Evening', 'submitted', score: 64),
              ],
            _ => [row('t1', 'Present tenses', 'Ingliz tili', 'IELTS Evening', 'assigned')],
          };
          return {'total': rows.length, 'data': rows};
        },
      }),
    );
    await tester.tap(find.text('Testlar').last);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('student_tests.png'));
  });

  testWidgets('student rank', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(),
        'GET /settings': settingsJson,
        'GET /home': {'greeting': 'day', 'metrics': [], 'week': []},
        'GET /group': const [],
        'GET /leaderboard': {
          'my_rank': 4,
          'my_score': 78,
          'total_ranked': 26,
          'gap_to_next': 3,
          'leaders': [
            {'rank': 1, 'user_id': 'u1', 'full_name': 'Zarina Mirzayeva', 'score': 94, 'tests': 14, 'is_me': false},
            {'rank': 2, 'user_id': 'u2', 'full_name': 'Sardor Karimov', 'score': 89, 'tests': 11, 'is_me': false},
            {'rank': 3, 'user_id': 'u3', 'full_name': 'Nilufar Saidova', 'score': 81, 'tests': 9, 'is_me': false},
            {'rank': 4, 'user_id': 'u1x', 'full_name': 'Ali Valiyev', 'score': 78, 'tests': 12, 'is_me': true},
            {'rank': 5, 'user_id': 'u5', 'full_name': 'Jasur Tashpulatov', 'score': 74, 'tests': 8, 'is_me': false},
          ],
        },
        'GET /badge': const [
          {'code': 'first_test', 'earned': true},
          {'code': 'tests_5', 'earned': false, 'progress': {'current': 1, 'target': 5}},
        ],
      }),
    );
    await tester.tap(find.text('Reyting').last);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('student_rank.png'));
  });

  testWidgets('student profile', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(),
        'GET /settings': settingsJson,
        'GET /home': {'greeting': 'day', 'metrics': [], 'week': []},
        'GET /group': const [],
        // Flat, with the counts the endpoint now returns.
        'GET /profile': {
          ...identityJson()['user'] as Map<String, dynamic>,
          'center_name': 'Cambridge Learning Center',
          'groups_count': 2,
          'tests_taken': 12,
          'avg_score': 78,
          'streak_days': 5,
        },
        'GET /progress': {
          'trend': [
            {'month': '2026-07', 'score': 71},
            {'month': '2026-08', 'score': 78},
          ],
          'skills': [
            {'skill': 'Present Simple', 'accuracy': 75, 'attempts': 4, 'tone': 'ok'},
            {'skill': 'Present Perfect', 'accuracy': 50, 'attempts': 4, 'tone': 'weak'},
          ],
        },
        'GET /badge': const [
          {'code': 'first_test', 'earned': true},
          {'code': 'tests_5', 'earned': false, 'progress': {'current': 1, 'target': 5}},
        ],
        'GET /subscription': {'required': false},
      }),
    );
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('student_profile.png'));
  });

  testWidgets('teacher groups', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(role: 'teacher'),
        'GET /settings': settingsJson,
        'GET /teacher/home': {'kpis': {}, 'attention': []},
        'GET /teacher/group': [
          {
            'id': 'g1',
            'name': 'Matematika · 9-sinf',
            'subject': 'Matematika',
            'level': '9',
            'room': '301',
            'schedule': [
              {'day': 3, 'start': '18:00', 'end': '19:30'},
            ],
            'capacity': 15,
            'students_count': 11,
            'avg_score': 74,
            'attendance_pct': 88,
          },
          {
            'id': 'g2',
            'name': 'Algebra · 11-sinf',
            'subject': 'Matematika',
            'level': '11',
            'room': '204',
            'schedule': [
              {'day': 2, 'start': '16:00', 'end': '17:30'},
            ],
            'capacity': 15,
            'students_count': 15,
            'avg_score': 61,
            // Never marked: the card must show "—", not "0%".
            'attendance_pct': null,
          },
        ],
      }),
    );
    await tester.tap(find.text('Guruhlar').last);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('teacher_groups.png'));
  });

  testWidgets('test cover', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(),
        'GET /settings': settingsJson,
        'GET /home': {'greeting': 'day', 'metrics': [], 'week': []},
        'GET /group': const [],
        // `GET /v1/test/:id`, verbatim from the server.
        'GET /test/t1': {
          'id': 't1',
          'student_test_id': 'st1',
          'title': 'Present tenses',
          'subject': 'Ingliz tili',
          'topic': 'Present tenses',
          'group': {'id': 'g1', 'name': 'IELTS Evening'},
          'question_count': 20,
          'time_limit_min': 30,
          'pass_score': 70,
          'difficulty': 'mixed',
          'due_at': null,
          'state': 'assigned',
          'score': null,
          'attempts_left': 2,
          'allow_calculator': false,
        },
      }),
    );
    await goTo(tester, '/student/test/t1');
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('test_cover.png'));
  });

  testWidgets('test result', (tester) async {
    Map<String, dynamic> question(
      int position,
      String skill,
      int chosen,
      int answer,
    ) =>
        {
          'id': 'q$position',
          'position': position,
          'text': 'She ___ to school every day.',
          'skill': skill,
          'options': const ['go', 'goes', 'going', 'gone'],
          'figure': null,
          'chosen_index': chosen,
          'is_correct': chosen == answer,
          'answer_index': answer,
          'explanation': 'Present Simple, uchinchi shaxs birlik uchun -s qo\'shiladi.',
        };

    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(),
        'GET /settings': settingsJson,
        'GET /home': {'greeting': 'day', 'metrics': [], 'week': []},
        'GET /group': const [],
        'GET /test/t1/result': {
          'student_test_id': 'st1',
          'title': 'Present tenses',
          'score': 80,
          'correct_count': 16,
          'total': 20,
          'passed': true,
          'pass_score': 70,
          'submitted_at': '2026-09-02T14:12:00.000Z',
          'duration_sec': 1140,
          'show_answers': true,
          'show_explanation': true,
          'questions': [
            question(1, 'Present Simple', 1, 1),
            question(2, 'Present Continuous', 3, 1),
          ],
        },
      }),
    );
    await goTo(tester, '/student/test/t1/result');
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('test_result.png'));
  });
  testWidgets('test runner', (tester) async {
    Map<String, dynamic> question(int position, String skill, int? chosen) => {
          'id': 'q$position',
          'position': position,
          'text': 'She ___ to school every day.',
          'skill': skill,
          'options': const ['go', 'goes', 'going', 'gone'],
          'figure': null,
          'chosen_index': chosen,
          // `answer_index` and `explanation` are deliberately absent here —
          // the server does not ship them before submission, and a fixture
          // that included them would hide it if the client ever started
          // reading them.
        };

    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(),
        'GET /settings': settingsJson,
        'GET /home': {'greeting': 'day', 'metrics': [], 'week': []},
        'GET /group': const [],
        'POST /test/t1/start': {
          'student_test_id': 'st1',
          'attempt_no': 1,
          'expires_at': '2099-01-01T00:00:00.000Z',
          'time_limit_min': 30,
          'questions': [
            question(1, 'Present Simple', null),
            question(2, 'Present Continuous', null),
            question(3, 'Present Perfect', null),
          ],
        },
      }),
    );
    await goTo(tester, '/student/test/t1/run');
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('test_runner.png'));
  });
  testWidgets('student group detail', (tester) async {
    Map<String, dynamic> mate(String id, String name, String initials, {bool me = false}) =>
        {'id': id, 'full_name': name, 'initials': initials, 'is_me': me};

    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(),
        'GET /settings': settingsJson,
        'GET /home': {'greeting': 'day', 'metrics': [], 'week': []},
        'GET /group': const [],
        'GET /group/g1': {
          'id': 'g1',
          'name': 'IELTS Evening',
          'subject': 'Ingliz tili',
          'level': 'B2',
          'room': '204',
          'schedule': [
            {'day': 1, 'start': '18:00', 'end': '19:30'},
            {'day': 4, 'start': '18:00', 'end': '19:30'},
          ],
          'teacher': {'id': 'u9', 'full_name': 'Kamola Tashpulatova'},
          'classmates': [
            mate('u1', 'Ali Valiyev', 'AV', me: true),
            mate('u2', 'Zarina Ergasheva', 'ZE'),
            mate('u3', 'Sardor Nazarov', 'SN'),
          ],
        },
      }),
    );
    await goTo(tester, '/student/group/g1');
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('student_group.png'));
  });

  testWidgets('teacher tests', (tester) async {
    Map<String, dynamic> test(
      String id,
      String title,
      int assigned,
      int submitted,
      int? avg,
    ) =>
        {
          'id': id,
          'title': title,
          'subject': 'Matematika',
          'group': {'id': 'g1', 'name': 'Matematika · 9-sinf'},
          'question_count': 20,
          'due_at': null,
          'state': 'ready',
          'assigned': assigned,
          'submitted': submitted,
          'avg_score': avg,
        };

    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(role: 'teacher'),
        'GET /settings': settingsJson,
        'GET /teacher/home': {'kpis': {}, 'attention': []},
        'GET /teacher/group': const [],
        'GET /teacher/test': [
          test('t1', 'Natural sonlar', 11, 9, 76),
          test('t2', 'Uchburchaklar', 11, 0, null),
        ],
      }),
    );
    await tester.tap(find.text('Testlar').last);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('teacher_tests.png'));
  });

  testWidgets('notifications', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(),
        'GET /settings': settingsJson,
        'GET /home': {'greeting': 'day', 'metrics': [], 'week': []},
        'GET /group': const [],
        'GET /notification': {
          'total': 2,
          'unread': 1,
          'data': [
            {
              'id': 'n1',
              'type': 'test_assigned',
              'title': 'Yangi test',
              'body': 'IELTS Evening guruhiga "Present tenses" tayinlandi.',
              'ref_id': 't1',
              'is_read': false,
              'created_at': '2026-09-03T06:10:00.000Z',
            },
            {
              'id': 'n2',
              'type': 'result_ready',
              'title': 'Natija tayyor',
              'body': '"Past simple" testidan 88 ball oldingiz.',
              'ref_id': 't3',
              'is_read': true,
              'created_at': '2026-09-01T15:40:00.000Z',
            },
          ],
        },
      }),
    );
    await goTo(tester, '/notifications');
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('notifications.png'));
  });
  testWidgets('create test', (tester) async {
    Map<String, dynamic> topic(String id, int position, String name) =>
        {'id': id, 'position': position, 'name': name, 'hint': null, 'is_custom': false};

    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        'GET /auth/me': identityJson(role: 'teacher'),
        'GET /settings': settingsJson,
        'GET /teacher/home': {'kpis': {}, 'attention': []},
        // Copied from `GET /v1/teacher/program` on the running server.
        'GET /teacher/program': {
          'subject': {'id': 's1', 'name': 'Matematika'},
          'branches': [
            {
              'id': 'b1',
              'name': 'Arifmetika',
              'hint': null,
              'stage': 1,
              'topics': [
                topic('t1', 1, 'Natural sonlar'),
                topic('t2', 2, 'Oddiy kasrlar'),
              ],
            },
          ],
        },
        'GET /teacher/quota': {
          'used': 3,
          'limit': 20,
          'remaining': 17,
          'resets_at': '2026-10-01T00:00:00.000Z',
        },
        'GET /teacher/group': [
          {
            'id': 'g1',
            'name': 'Matematika · 9-sinf',
            'subject': 'Matematika',
            'level': '9',
            'room': '301',
            'schedule': const [],
            'capacity': 15,
            'students_count': 11,
            'avg_score': 74,
            'attendance_pct': 88,
          },
        ],
      }),
    );
    await goTo(tester, '/teacher/create-test');
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('create_test.png'));
  });
}

/// Drives the app's own router to a pushed route.
///
/// These two screens live above the tab shell and there is no tab that reaches
/// them, so a golden has to navigate the way the app does rather than by
/// building the widget directly — which would skip the router, the shell and
/// the theme the screen is actually drawn inside.
Future<void> goTo(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).push(location);
  await tester.pumpAndSettle();
}
