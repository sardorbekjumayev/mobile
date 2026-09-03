import 'package:flutter_test/flutter_test.dart';
import 'package:stepix/core/api/api_exception.dart';
import 'package:stepix/data/repositories/auth_repository.dart';

import '../fake_api_client.dart';

void main() {
  test('every shape a phone is typed in reaches the API as 998XXXXXXXXX', () {
    expect(normalizePhone('901234567'), '998901234567');
    expect(normalizePhone('+998 90 123 45 67'), '998901234567');
    expect(normalizePhone('998-90-123-45-67'), '998901234567');
    expect(normalizePhone('8998901234567'), '998901234567');
  });

  test('a login response with no token pair fails as an ApiException, not a crash', () async {
    final api = FakeApiClient({'POST /auth/login': identityJson()});

    await expectLater(
      AuthRepository(api).login(phone: '998901234567', password: 'x'),
      throwsA(isA<ApiException>()),
    );
  });

  test('logout names the device by its refresh token', () async {
    final api = FakeApiClient({'POST /auth/logout': {'logged_out': true}});

    await AuthRepository(api).logout(refreshToken: 'r1', fcmToken: 'f1');

    expect(api.bodies['POST /auth/logout'], {'refresh_token': 'r1', 'fcm_token': 'f1'});
  });

  test('an absent fcm token is left out of the body rather than sent as null', () async {
    final api = FakeApiClient({'POST /auth/logout': {'logged_out': true}});

    await AuthRepository(api).logout(refreshToken: 'r1');

    expect(api.bodies['POST /auth/logout'], {'refresh_token': 'r1'});
  });
}
