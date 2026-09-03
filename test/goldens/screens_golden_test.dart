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
}
