import 'package:flutter_test/flutter_test.dart';
import 'package:stepix/data/repositories/profile_repository.dart';

import '../fake_api_client.dart';

void main() {
  test('settings sends the version in the query, which is where the server reads it', () async {
    final api = FakeApiClient({'GET /settings': settingsJson});

    await ProfileRepository(api).settings();

    expect((api.bodies['GET /settings']! as Map)['version'], isNotEmpty);
  });

  test('an empty update reads the profile instead of PUTting nothing', () async {
    final api = FakeApiClient({'GET /profile': identityJson()});

    await ProfileRepository(api).update();

    expect(api.calls, ['GET /profile']);
  });

  test('a device registers with its platform, so the push is built for the right OS', () async {
    final api = FakeApiClient({'POST /fcm-token': {'registered': true}});

    await ProfileRepository(api).registerDevice('t1');

    expect((api.bodies['POST /fcm-token']! as Map)['platform'], isNotEmpty);
  });

  test('the notification page size is clamped to what the API accepts', () async {
    final api = FakeApiClient({'GET /notification': {'total': 0, 'unread': 0, 'data': []}});

    await ProfileRepository(api).notifications(page: 0, limit: 500);

    final query = api.bodies['GET /notification']! as Map;
    expect(query['page'], 1);
    expect(query['limit'], 100);
  });
}
