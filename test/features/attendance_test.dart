import 'package:flutter_test/flutter_test.dart';

import '../app_smoke_test.dart' show pumpApp;
import '../fake_api_client.dart';

/// The register, against the payload the live API actually returns.
///
/// The shapes here were copied from `GET /v1/teacher/group/:id` on the running
/// server rather than from the models — a test written against our own reader
/// cannot catch a field the server never sends.
void main() {
  const groupId = '01a04871-4060-7efb-a9a0-f3f9b0dabf66';

  Map<String, dynamic> liveGroupDetail() => {
        'id': groupId,
        'name': 'Matematika · 9-sinf',
        'subject': 'Matematika',
        'level': '9',
        'room': '301',
        'schedule': [
          {'day': 3, 'start': '18:00', 'end': '19:30'},
        ],
        'capacity': 15,
        'seats_taken': 2,
        'students': [
          {
            'id': '01a04871-4546-7426-ba30-a1bf88d945e9',
            'full_name': 'Madina Saidova',
            'avg_score': null,
            'tests': 0,
            'attendance_pct': null,
            'engagement': 'new',
            'last_seen_at': null,
          },
          {
            'id': '01a04871-4584-749b-afb6-7b792a471e99',
            'full_name': 'Temur Sultonov',
            'avg_score': null,
            'tests': 0,
            'attendance_pct': null,
            'engagement': 'new',
            'last_seen_at': null,
          },
        ],
      };

  FakeApiClient teacherApi() => FakeApiClient({
        'GET /auth/me': identityJson(role: 'teacher'),
        'GET /settings': settingsJson,
        'GET /teacher/home': {'kpis': {}, 'attention': []},
        'GET /teacher/group': [liveGroupDetail()],
        'GET /teacher/group/$groupId': liveGroupDetail(),
        'POST /teacher/attendance': {'marked': 2, 'lesson_date': '2026-09-03'},
      });

  Future<void> openRegister(WidgetTester tester, FakeApiClient api) async {
    await pumpApp(tester, api: api, tokens: signedInTokens);
    // "Guruhlar" is also a KPI label on the teacher's home screen; the tab is
    // the last one in the tree.
    await tester.tap(find.text('Guruhlar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yo\'qlama').first);
    await tester.pumpAndSettle();
  }

  testWidgets('the roster renders every student the API sent', (tester) async {
    final api = teacherApi();
    await openRegister(tester, api);

    expect(find.text('Madina Saidova'), findsOneWidget);
    expect(find.text('Temur Sultonov'), findsOneWidget);
  });

  testWidgets('saving posts one record per student and leaves the screen', (tester) async {
    final api = teacherApi();
    await openRegister(tester, api);

    // One absence in a full room — the case the "untouched means present"
    // default exists for.
    await tester.tap(find.text('Kelmadi').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yo\'qlamani saqlash'));
    await tester.pumpAndSettle();

    final body = api.bodies['POST /teacher/attendance']! as Map<String, dynamic>;
    expect(body['group_id'], groupId);
    expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(body['lesson_date'] as String), isTrue);

    final records = body['records'] as List;
    expect(records, hasLength(2));
    expect((records.first as Map)['status'], 'absent');
    expect((records.last as Map)['status'], 'present');
  });
}
