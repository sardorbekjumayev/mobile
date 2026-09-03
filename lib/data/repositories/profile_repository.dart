import '../../app/config.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/util/json.dart';
import '../models/profile_models.dart';

class ProfileRepository {
  const ProfileRepository(this._api);

  final ApiClient _api;

  /// The server's per-file ceiling. Checked here so an oversized photo fails
  /// with a sentence instead of a 413 whose body is nginx HTML — which the
  /// envelope reader can only report as "Xatolik yuz berdi".
  static const maxAvatarBytes = 8 * 1024 * 1024;

  Future<UserProfile> profile() async =>
      UserProfile.fromJson(asMap(await _api.get('/profile')));

  /// Both fields optional, but not both absent: the API validates with
  /// `forbidNonWhitelisted`, and an empty PUT is a round trip that can only
  /// return what the caller already had.
  Future<UserProfile> update({String? fullName, String? language}) async {
    final name = fullName?.trim();
    if ((name == null || name.isEmpty) && language == null) return profile();

    final data = await _api.put('/profile', body: {
      if (name != null && name.isNotEmpty) 'full_name': name,
      'language': ?language,
    });
    return UserProfile.fromJson(asMap(data));
  }

  Future<String?> uploadAvatar(String filePath, {int? sizeBytes}) async {
    if (sizeBytes != null && sizeBytes > maxAvatarBytes) {
      throw ApiException(
        message: 'Rasm hajmi 8 MB dan oshmasligi kerak.',
        statusCode: 413,
      );
    }
    final data = asMap(await _api.upload('/profile/avatar', field: 'file', filePath: filePath));
    return asStringOrNull(data['avatar_url'] ?? data['url']);
  }

  /// `limit` is capped server-side at 100; anything larger comes back as a
  /// validation error rather than a shorter page.
  Future<NotificationFeed> notifications({int page = 1, int limit = 20}) async =>
      NotificationFeed.fromJson(
        asMap(await _api.get('/notification', query: {
          'page': page < 1 ? 1 : page,
          'limit': limit.clamp(1, 100),
        })),
      );

  /// Omitting [ids] marks the whole feed read.
  Future<void> markRead({List<String>? ids}) =>
      _api.post('/notification/read', body: {
        if (ids != null && ids.isNotEmpty) 'ids': ids,
      });

  /// The platform travels with the token so the worker knows which FCM payload
  /// shape to send; without it every push is built for the wrong OS half the
  /// time.
  Future<void> registerDevice(String token) => _api.post('/fcm-token', body: {
        'token': token,
        'platform': AppConfig.platform,
      });

  Future<void> unregisterDevice(String token) =>
      _api.delete('/fcm-token', body: {'token': token});

  Future<Subscription> subscription() async =>
      Subscription.fromJson(asMap(await _api.get('/subscription')));

  /// `payme` or `click` — the only two the API's enum accepts.
  Future<CheckoutSession> checkout(String provider) async {
    if (provider != 'payme' && provider != 'click') {
      throw ApiException(message: 'To\'lov tizimi noto\'g\'ri: $provider', statusCode: 400);
    }
    return CheckoutSession.fromJson(asMap(await _api.post(
      '/subscription/checkout',
      body: {'provider': provider},
    )));
  }

  /// `GET /settings` — public, so it can be read before sign-in.
  ///
  /// The version goes in the **query string**, not just the `X-App-Version`
  /// header: the server reads `?version=` and falls back to a context field it
  /// never populates, so without this `force_update` was always `false` and the
  /// update gate could never fire.
  Future<AppSettings> settings() async => AppSettings.fromJson(
        asMap(await _api.get('/settings', query: {'version': AppConfig.appVersion})),
      );
}
