@Tags(['golden'])
library;

import 'package:flutter/material.dart';
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
}
