import '../../core/api/api_client.dart';
import '../../core/util/json.dart';
import '../models/profile_models.dart';

class ProfileRepository {
  const ProfileRepository(this._api);

  final ApiClient _api;

  Future<UserProfile> profile() async =>
      UserProfile.fromJson(asMap(await _api.get('/profile')));

  Future<UserProfile> update({String? fullName, String? language}) async {
    final data = await _api.put('/profile', body: {
      if (fullName != null) 'full_name': fullName,
      if (language != null) 'language': language,
    });
    return UserProfile.fromJson(asMap(data));
  }

  Future<String?> uploadAvatar(String filePath) async {
    final data = asMap(await _api.upload('/profile/avatar', field: 'file', filePath: filePath));
    return asStringOrNull(data['avatar_url'] ?? data['url']);
  }

  Future<NotificationFeed> notifications({int page = 1, int limit = 20}) async =>
      NotificationFeed.fromJson(
        asMap(await _api.get('/notification', query: {'page': page, 'limit': limit})),
      );

  /// Omitting [ids] marks the whole feed read.
  Future<void> markRead({List<String>? ids}) =>
      _api.post('/notification/read', body: {if (ids != null) 'ids': ids});

  Future<void> registerDevice(String token) =>
      _api.post('/fcm-token', body: {'token': token});

  Future<void> unregisterDevice(String token) =>
      _api.delete('/fcm-token', body: {'token': token});

  Future<Subscription> subscription() async =>
      Subscription.fromJson(asMap(await _api.get('/subscription')));

  Future<CheckoutSession> checkout(String provider) async =>
      CheckoutSession.fromJson(asMap(await _api.post(
        '/subscription/checkout',
        body: {'provider': provider},
      )));

  Future<AppSettings> settings() async =>
      AppSettings.fromJson(asMap(await _api.get('/settings')));
}
