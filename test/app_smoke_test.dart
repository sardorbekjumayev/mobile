import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stepix/app/stepix_app.dart';
import 'package:stepix/core/api/api_client.dart';
import 'package:stepix/core/api/api_exception.dart';
import 'package:stepix/core/session/session_controller.dart';
import 'package:stepix/core/session/settings_controller.dart';
import 'package:stepix/core/storage/token_store.dart';
import 'package:stepix/data/repositories/auth_repository.dart';
import 'package:stepix/data/repositories/profile_repository.dart';
import 'package:stepix/data/repositories/student_repository.dart';
import 'package:stepix/data/repositories/teacher_repository.dart';

import 'fake_api_client.dart';

/// Boots the real widget tree — router, shell and all — against a fake client.
Future<void> pumpApp(
  WidgetTester tester, {
  required FakeApiClient api,
  AuthTokens? tokens,
}) async {
  final store = InMemoryTokenStore();
  if (tokens != null) await store.write(tokens);

  final config = ApiConfig(baseUrl: 'http://test/v1', appVersion: '1.0.0', platform: 'android');
  final profiles = ProfileRepository(api);
  final session = SessionController(
    auth: AuthRepository(api),
    tokens: store,
    config: config,
  );
  unawaited(session.restore());

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ApiConfig>.value(value: config),
        Provider<ApiClient>.value(value: api),
        Provider(create: (_) => StudentRepository(api)),
        Provider(create: (_) => TeacherRepository(api)),
        Provider<ProfileRepository>.value(value: profiles),
        Provider<AuthRepository>(create: (_) => AuthRepository(api)),
        ChangeNotifierProvider<SessionController>.value(value: session),
        ChangeNotifierProvider(create: (_) => SettingsController(profiles)),
      ],
      child: const StepixApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a device with no tokens lands on the welcome screen', (tester) async {
    await pumpApp(tester, api: FakeApiClient(const {}));

    expect(find.textContaining('Tezroq'), findsOneWidget);
    expect(find.textContaining('Raqam bilan'), findsOneWidget);
  });

  testWidgets('a signed-in device with no connection waits, with a retry', (tester) async {
    final api = FakeApiClient({
      'GET /auth/me': ApiException.network('Internet aloqasi yo\'q.'),
      'GET /settings': settingsJson,
    });

    await pumpApp(tester, api: api, tokens: signedInTokens);

    // Not the welcome screen: its only button posts to the same dead API.
    expect(find.textContaining('Raqam bilan'), findsNothing);
    expect(find.text('Ulanish yo\'q'), findsOneWidget);
    expect(find.byKey(const Key('splash-retry')), findsOneWidget);

    api.responses['GET /auth/me'] = identityJson();
    api.responses['GET /home'] = {'greeting': 'day', 'empty_state': 'no_group'};
    api.responses['GET /group'] = const [];
    await tester.tap(find.byKey(const Key('splash-retry')));
    await tester.pumpAndSettle();

    expect(find.text('Ali'), findsOneWidget);
  });

  testWidgets('a stored session restores straight into the student shell', (tester) async {
    final api = FakeApiClient({
      'GET /auth/me': identityJson(),
      'GET /settings': settingsJson,
      'GET /home': {'greeting': 'day', 'empty_state': 'no_group'},
      'GET /group': const [],
    });

    await pumpApp(
      tester,
      api: api,
      tokens: signedInTokens,
    );

    expect(find.text('Reyting'), findsOneWidget);
    expect(find.text('Ali'), findsOneWidget);
    // No group yet is said in words rather than drawn as a wall of zeroes.
    expect(find.textContaining('guruhga qo\'shishmagan'), findsOneWidget);
  });

  testWidgets('a teacher gets the teacher shell, not the student one', (tester) async {
    final api = FakeApiClient({
      'GET /auth/me': identityJson(role: 'teacher'),
      'GET /settings': settingsJson,
      'GET /teacher/home': {
        'kpis': {'groups': 2, 'students': 31, 'tests_this_month': 4, 'avg_score': 72},
        'attention': const [],
      },
      'GET /teacher/group': const [],
    });

    await pumpApp(
      tester,
      api: api,
      tokens: signedInTokens,
    );

    expect(find.text('Guruhlar'), findsWidgets);
    expect(find.text('Reyting'), findsNothing);
  });

  testWidgets('a forced password change blocks the rest of the app', (tester) async {
    final api = FakeApiClient({
      'GET /auth/me': identityJson(mustChangePassword: true),
      'GET /settings': settingsJson,
    });

    await pumpApp(
      tester,
      api: api,
      tokens: signedInTokens,
    );

    expect(find.text('Yangi parol qo\'ying'), findsOneWidget);
    // The home endpoint is never reached while the flag stands.
    expect(api.calls.contains('GET /home'), isFalse);
  });
}
