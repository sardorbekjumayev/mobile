import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepix/core/api/api_exception.dart';

import '../app_smoke_test.dart' show pumpApp;
import '../fake_api_client.dart';
import '../widget_harness.dart';

/// Account screens and the walls: settings, language, sign-out, notifications,
/// a blocked account, a forced update and the password screens.
void main() {
  usePhoneView();

  Map<String, dynamic> profileStubs() => {
        ...studentStubs(),
        'GET /profile': {'user': identityJson()['user'], 'center_name': 'Stepix Center', 'tests_taken': 3},
        'GET /progress': {'trend': [], 'skills': []},
        'GET /badge': const [],
        'GET /subscription': {'required': false},
      };

  testWidgets('choosing a language saves it and repaints the app in it', (tester) async {
    final api = FakeApiClient({
      ...profileStubs(),
      'PUT /profile': {
        'user': {...(identityJson()['user'] as Map<String, dynamic>), 'language': 'ru'},
      },
    });
    await pumpApp(tester, api: api, tokens: signedInTokens);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Til'), 200);
    expect(find.text('O\'zbekcha'), findsOneWidget);
    await tester.tap(find.text('Til'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();

    expect(api.bodies['PUT /profile'], {'language': 'ru'});
    expect(find.text('Профиль'), findsWidgets);
  });

  // The dialog used to dispose its controller while still animating out, which
  // broke the frame on Save and the rename never reached the server.
  testWidgets('renaming saves the new name and shows it', (tester) async {
    final renamed = {...(identityJson()['user'] as Map<String, dynamic>), 'full_name': 'Vali Aliyev'};
    final api = FakeApiClient({
      ...profileStubs(),
      'PUT /profile': {'user': renamed},
    });
    await pumpApp(tester, api: api, tokens: signedInTokens);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Vali Aliyev ');
    // What the server answers once the rename has landed.
    api.responses['GET /profile'] = {'user': renamed, 'center_name': 'Stepix Center', 'tests_taken': 3};
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();

    expect(api.bodies['PUT /profile'], {'full_name': 'Vali Aliyev'});
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Vali Aliyev'), findsOneWidget);
  });

  testWidgets('a failed language save rolls back', (tester) async {
    final api = FakeApiClient({
      ...profileStubs(),
      'PUT /profile': ApiException(message: 'x', statusCode: 500),
    });
    await pumpApp(tester, api: api, tokens: signedInTokens);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Til'), 200);
    await tester.tap(find.text('Til'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Profil'), findsWidgets);
    expect(find.text('Xatolik yuz berdi'), findsOneWidget);
  });

  testWidgets('signing out asks, then clears the device back to welcome', (tester) async {
    final api = FakeApiClient({...profileStubs(), 'POST /auth/logout': null});
    await pumpApp(tester, api: api, tokens: signedInTokens);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Hisobdan chiqish'), 200);
    await tester.tap(find.text('Hisobdan chiqish'));
    await tester.pumpAndSettle();
    expect(find.text('Hisobdan chiqasizmi?'), findsOneWidget);
    await tester.tap(find.text('Bekor qilish'));
    await tester.pumpAndSettle();
    expect(api.calls, isNot(contains('POST /auth/logout')));

    await tester.tap(find.text('Hisobdan chiqish'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Hisobdan chiqish'));
    await tester.pumpAndSettle();
    expect(api.bodies['POST /auth/logout'], {'refresh_token': 'r'});
    expect(find.textContaining('Raqam bilan'), findsOneWidget);
  });

  testWidgets('settings shows the version and support rows', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        ...studentStubs(),
        'GET /settings': {...settingsJson, 'latest_version': '1.2.0', 'support_telegram': 'https://t.me/x'},
      }),
    );
    await goTo(tester, '/settings');
    expect(find.text('Parolni o\'zgartirish'), findsOneWidget);
    expect(find.text('Yordam'), findsOneWidget);
    expect(find.text('Maxfiylik siyosati'), findsOneWidget);
    expect(find.text('1.0.0 → 1.2.0'), findsOneWidget);

    await tester.tap(find.text('Parolni o\'zgartirish'));
    await tester.pumpAndSettle();
    expect(find.text('Yangi parol qo\'ying'), findsOneWidget);
    // Voluntary change keeps a way back.
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('a notification row opens what it is about and mark-all clears the rest', (tester) async {
    // It lands on a failed result, whose score hero overflows at 390px.
    useWideView(tester);
    final reads = <Object?>[];
    final api = FakeApiClient({
      ...studentStubs(),
      'GET /notification': {
        'total': 2,
        'unread': 1,
        'data': [
          {'id': 'n1', 'type': 'test_graded', 'title': 'Baholandi', 'body': '', 'is_read': false, 'ref_id': 't1'},
          {'id': 'n2', 'type': 'invoice_paid', 'title': 'To\'landi', 'body': 'b', 'is_read': true},
        ],
      },
      'POST /notification/read': (Object? body) {
        reads.add(body);
        return null;
      },
      'GET /test/t1/result': {'title': 'Unit 4', 'score': 70, 'questions': []},
    });
    await pumpApp(tester, api: api, tokens: signedInTokens);
    await goTo(tester, '/notifications');
    // Opening the feed marks the visible unread rows.
    expect(reads.first, {
      'ids': ['n1'],
    });

    await tester.tap(find.text('Hammasini o\'qilgan deb belgilash'));
    await tester.pumpAndSettle();
    // Mark-all sends no ids — the whole feed.
    expect(reads, anyElement(equals(<String, dynamic>{})));

    await tester.tap(find.text('Baholandi'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('GET /test/t1/result'));
    expect(find.text('Natija'), findsOneWidget);
  });

  testWidgets('an empty feed says there is nothing', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        ...studentStubs(),
        'GET /notification': {'total': 0, 'unread': 0, 'data': []},
      }),
    );
    await goTo(tester, '/notifications');
    expect(find.text('Bildirishnomalar yo\'q'), findsOneWidget);
    expect(find.text('Hammasini o\'qilgan deb belgilash'), findsNothing);
  });

  testWidgets('a blocked account gets an explanation, not a login form', (tester) async {
    final api = FakeApiClient({
      'GET /auth/me': ApiException(message: 'Hisobingiz bloklangan', statusCode: 403, code: ErrorCodes.userBlocked),
      'GET /settings': settingsJson,
      'POST /auth/logout': null,
    });
    await pumpApp(tester, api: api, tokens: signedInTokens);

    expect(find.text('Kirish yopiq'), findsOneWidget);
    expect(find.text('Hisobingiz bloklangan'), findsOneWidget);
    await tester.tap(find.text('Kirish sahifasiga'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Raqam bilan'), findsOneWidget);
  });

  testWidgets('a build the API no longer supports is walled off with no way around', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        ...studentStubs(),
        'GET /settings': {...settingsJson, 'force_update': true, 'latest_version': '2.0.0'},
      }),
    );
    expect(find.text('Ilovani yangilang'), findsWidgets);
    expect(find.text('Versiya: 2.0.0'), findsOneWidget);
    expect(find.text('Reyting'), findsNothing);
  });

  group('forced password change', () {
    Future<void> open(WidgetTester tester, FakeApiClient api) async {
      await pumpApp(tester, api: api, tokens: signedInTokens);
      expect(find.text('Yangi parol qo\'ying'), findsOneWidget);
    }

    FakeApiClient api() => FakeApiClient({
          'GET /auth/me': identityJson(mustChangePassword: true),
          'GET /settings': settingsJson,
        });

    testWidgets('a short password is refused before any request', (tester) async {
      final a = api();
      await open(tester, a);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'old-pass');
      await tester.enterText(fields.at(1), 'short');
      await tester.enterText(fields.at(2), 'short');
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();
      expect(find.text('Parol kamida 8 ta belgidan iborat bo\'lsin'), findsOneWidget);
      expect(a.calls, isNot(contains('POST /auth/change-password')));
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('mismatched passwords are refused', (tester) async {
      final a = api();
      await open(tester, a);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'longenough1');
      await tester.enterText(fields.at(2), 'longenough2');
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();
      expect(find.text('Parollar mos kelmadi'), findsOneWidget);
    });

    testWidgets('the server\'s refusal is shown as its own message', (tester) async {
      final a = api()
        ..responses['POST /auth/change-password'] =
            ApiException(message: 'Joriy parol noto\'g\'ri', statusCode: 400, code: 20108);
      await open(tester, a);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'wrong-old');
      await tester.enterText(fields.at(1), 'longenough1');
      await tester.enterText(fields.at(2), 'longenough1');
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();
      expect(a.bodies['POST /auth/change-password'], {
        'current_password': 'wrong-old',
        'new_password': 'longenough1',
      });
      expect(find.text('Joriy parol noto\'g\'ri'), findsOneWidget);
    });
  });

  testWidgets('wrong credentials show the message and the admin hint', (tester) async {
    final api = FakeApiClient({
      'GET /settings': settingsJson,
      'POST /auth/login': ApiException(
        message: 'Telefon yoki parol noto\'g\'ri',
        statusCode: 401,
        code: ErrorCodes.wrongCredentials,
      ),
    });
    await pumpApp(tester, api: api);
    await goReplace(tester, '/login/password', extra: '998901234567');

    expect(find.text('+998 90 123 45 67'), findsNothing);
    expect(find.textContaining('90 123 45 67'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.pump();
    await tester.tap(find.text('Kirish'));
    await tester.pumpAndSettle();

    expect(api.bodies['POST /auth/login'], {'phone': '998901234567', 'password': 'secret'});
    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(find.byKey(const Key('login-admin-hint')), findsOneWidget);
  });

  testWidgets('a successful sign-in lands on the success screen, then the shell', (tester) async {
    final api = FakeApiClient({
      'GET /settings': settingsJson,
      'POST /auth/login': {
        ...identityJson(),
        'access_token': 'a',
        'refresh_token': 'r',
        'expires_in': 900,
      },
      'GET /home': {'greeting': 'day', 'empty_state': 'no_group'},
      'GET /group': const [],
    });
    await pumpApp(tester, api: api);
    await goReplace(tester, '/login/password', extra: '998901234567');

    await tester.enterText(find.byType(TextField), 'secret');
    await tester.pump();
    await tester.tap(find.text('Kirish'));
    await tester.pumpAndSettle();

    expect(find.text('Xush kelibsiz!'), findsOneWidget);
    expect(find.text('Stepix Center'), findsOneWidget);
    await tester.tap(find.text('Stepix\'ni ochish'));
    await tester.pumpAndSettle();
    expect(find.text('Reyting'), findsOneWidget);
  });
}
