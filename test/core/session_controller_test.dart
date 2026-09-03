import 'package:flutter_test/flutter_test.dart';
import 'package:stepix/core/api/api_client.dart';
import 'package:stepix/core/api/api_exception.dart';
import 'package:stepix/core/session/session_controller.dart';
import 'package:stepix/core/storage/token_store.dart';
import 'package:stepix/data/repositories/auth_repository.dart';

import '../fake_api_client.dart';

/// The session state machine, tested without a widget tree: every one of these
/// is a way the app used to strand a user who had done nothing wrong.
void main() {
  ({SessionController session, InMemoryTokenStore store, ApiConfig config}) build(
    FakeApiClient api, {
    AuthTokens? tokens,
  }) {
    final store = InMemoryTokenStore();
    if (tokens != null) store.write(tokens);
    final config = ApiConfig(baseUrl: 'http://test/v1', appVersion: '1.0.0', platform: 'android');
    return (
      session: SessionController(auth: AuthRepository(api), tokens: store, config: config),
      store: store,
      config: config,
    );
  }

  group('restore', () {
    test('an unreachable server leaves the session offline, with its tokens', () async {
      final api = FakeApiClient({'GET /auth/me': ApiException.network('Internet aloqasi yo\'q.')});
      final s = build(api, tokens: signedInTokens);

      await s.session.restore();

      expect(s.session.status, SessionStatus.offline);
      expect(s.session.offlineReason, 'Internet aloqasi yo\'q.');
      // The point of the whole state: signing the user out here would have
      // meant asking them to log in over the connection that just failed.
      expect(await s.store.read(), isNotNull);
    });

    test('a retry after the connection returns lands in the signed-in state', () async {
      final api = FakeApiClient({'GET /auth/me': ApiException.network('yo\'q')});
      final s = build(api, tokens: signedInTokens);
      await s.session.restore();
      expect(s.session.status, SessionStatus.offline);

      api.responses['GET /auth/me'] = identityJson();
      await s.session.restore();

      expect(s.session.status, SessionStatus.signedIn);
      expect(s.session.user?.fullName, 'Ali Valiyev');
    });

    test('a rejected token pair is thrown away', () async {
      final api = FakeApiClient({
        'GET /auth/me': ApiException(message: 'expired', statusCode: 401, code: 20104),
      });
      final s = build(api, tokens: signedInTokens);

      await s.session.restore();

      expect(s.session.status, SessionStatus.signedOut);
      expect(await s.store.read(), isNull);
    });

    test('a suspended center is a wall, not a logout', () async {
      final api = FakeApiClient({
        'GET /auth/me': ApiException(message: 'Markaz to\'xtatilgan', statusCode: 403, code: 20203),
      });
      final s = build(api, tokens: signedInTokens);

      await s.session.restore();

      expect(s.session.status, SessionStatus.locked);
      expect(s.session.lockReason, 'Markaz to\'xtatilgan');
    });
  });

  group('signIn', () {
    test('a blocked account locks rather than looping on the password field', () async {
      final api = FakeApiClient({
        'POST /auth/login': ApiException(message: 'Bloklangansiz', statusCode: 403, code: 20106),
      });
      final s = build(api);

      await expectLater(
        s.session.signIn(phone: '998901234567', password: 'x'),
        throwsA(isA<ApiException>()),
      );
      expect(s.session.status, SessionStatus.locked);
    });

    test('a wrong password leaves the session alone', () async {
      final api = FakeApiClient({
        'POST /auth/login': ApiException(message: 'Parol xato', statusCode: 401, code: 20105),
      });
      final s = build(api);

      await expectLater(
        s.session.signIn(phone: '998901234567', password: 'x'),
        throwsA(isA<ApiException>()),
      );
      expect(s.session.status, SessionStatus.unknown);
      expect(s.session.lockReason, isNull);
    });
  });

  test('changing the password re-authenticates, because the server revoked the pair', () async {
    final api = FakeApiClient({
      'GET /auth/me': identityJson(mustChangePassword: true),
      'POST /auth/change-password': {'changed': true},
      'POST /auth/login': {
        'access_token': 'a2',
        'refresh_token': 'r2',
        'expires_in': 3600,
        ...identityJson(),
      },
    });
    final s = build(api, tokens: signedInTokens);
    await s.session.restore();
    expect(s.session.status, SessionStatus.mustChangePassword);

    await s.session.changePassword(currentPassword: 'old', newPassword: 'newpass1');

    expect(s.session.status, SessionStatus.signedIn);
    // The old pair would have been dead the moment change-password returned.
    expect((await s.store.read())?.refresh, 'r2');
  });

  test('signing out names this device rather than revoking every session', () async {
    final api = FakeApiClient({
      'GET /auth/me': identityJson(),
      'POST /auth/logout': {'logged_out': true},
    });
    final s = build(api, tokens: const AuthTokens(access: 'a', refresh: 'this-device'));
    await s.session.restore();

    await s.session.signOut(fcmToken: 'fcm-1');

    final body = api.bodies['POST /auth/logout']! as Map<String, dynamic>;
    expect(body['refresh_token'], 'this-device');
    expect(body['fcm_token'], 'fcm-1');
    expect(await s.store.read(), isNull);
    expect(s.session.status, SessionStatus.signedOut);
  });

  test('a logout the network ate still clears the device', () async {
    final api = FakeApiClient({
      'GET /auth/me': identityJson(),
      'POST /auth/logout': ApiException.network('yo\'q'),
    });
    final s = build(api, tokens: signedInTokens);
    await s.session.restore();

    await s.session.signOut();

    expect(await s.store.read(), isNull);
    expect(s.session.status, SessionStatus.signedOut);
  });
}
