import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_smoke_test.dart' show pumpApp;
import 'fake_api_client.dart';

/// The screens that were the last ones wired up: profile, notifications and the
/// teacher's test list.
void main() {
  testWidgets('the profile tab shows the identity, stats and badges', (tester) async {
    final api = FakeApiClient({
      'GET /auth/me': identityJson(),
      'GET /settings': settingsJson,
      'GET /home': {'greeting': 'day', 'empty_state': 'no_group'},
      'GET /group': const [],
      'GET /profile': {
        'user': identityJson()['user'],
        'center_name': 'Stepix Center',
        'tests_taken': 12,
        'avg_score': 78,
        'streak_days': 4,
      },
      'GET /progress': {
        'trend': [
          {'month': '2026-07', 'score': 71},
          {'month': '2026-08', 'score': 78},
        ],
        'skills': [
          {'skill': 'Reading', 'accuracy': 91, 'tone': 'strong'},
          {'skill': 'Grammar', 'accuracy': 52, 'tone': 'weak'},
        ],
      },
      'GET /badge': const [
        {'code': 'first_test', 'earned': true},
        {'code': 'tests_20', 'earned': false, 'progress': {'current': 12, 'target': 20}},
      ],
      // A Model A center has no subscription row; the section stays hidden.
      'GET /subscription': {'required': false, 'status': 'none'},
    });

    await pumpApp(tester, api: api, tokens: signedInTokens);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Ali Valiyev'), findsOneWidget);
    // Role, center and phone share one line on the design's identity card.
    expect(find.textContaining('+998901234567'), findsOneWidget);
    expect(find.textContaining('Stepix Center'), findsOneWidget);
    expect(find.text('78'), findsWidgets);
    expect(find.text('Obuna'), findsNothing);

    // Skills and badges sit below the fold; a ListView builds neither until the
    // viewport reaches them, and drops each again once it has passed.
    await tester.scrollUntilVisible(find.text('Grammar'), 200);
    expect(find.text('Reading'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Birinchi test'), 200);
    expect(find.text('12/20'), findsOneWidget);
  });

  testWidgets('the bell opens the notification feed', (tester) async {
    final api = FakeApiClient({
      'GET /auth/me': identityJson(),
      'GET /settings': settingsJson,
      'GET /home': {'greeting': 'day', 'empty_state': 'no_group'},
      'GET /group': const [],
      'GET /notification': {
        'total': 1,
        'unread': 1,
        'data': [
          {
            'id': 'n1',
            'type': 'test_assigned',
            'title': 'Yangi test',
            'body': 'IELTS Evening · Unit 4',
            'is_read': false,
            'created_at': '2026-08-28T10:00:00Z',
          },
        ],
      },
    });

    await pumpApp(tester, api: api, tokens: signedInTokens);
    await tester.tap(find.byIcon(Icons.notifications_none_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Yangi test'), findsOneWidget);
    expect(find.text('Hammasini o\'qilgan deb belgilash'), findsOneWidget);
  });

  testWidgets('the teacher test list shows submission progress', (tester) async {
    final api = FakeApiClient({
      'GET /auth/me': identityJson(role: 'teacher'),
      'GET /settings': settingsJson,
      'GET /teacher/home': {
        'kpis': {'groups': 1, 'students': 10, 'tests_this_month': 1, 'avg_score': 70},
        'attention': const [],
      },
      'GET /teacher/group': const [],
      'GET /teacher/test': const [
        {
          'id': 't1',
          'title': 'Unit 4 · Reading',
          'subject': 'Ingliz tili',
          'groups': [
            {'name': 'IELTS Evening'},
          ],
          'question_count': 20,
          'submitted_count': 7,
          'assigned_count': 12,
          'avg_score': 64,
        },
      ],
    });

    await pumpApp(tester, api: api, tokens: signedInTokens);
    await tester.tap(find.text('Testlar'));
    await tester.pumpAndSettle();

    expect(find.text('Unit 4 · Reading'), findsOneWidget);
    expect(find.text('7/12'), findsOneWidget);
    expect(find.text('64'), findsOneWidget);
  });
}
