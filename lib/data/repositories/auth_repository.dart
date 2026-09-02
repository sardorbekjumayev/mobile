import '../../core/api/api_client.dart';
import '../../core/storage/token_store.dart';
import '../../core/util/json.dart';
import '../models/session_models.dart';

class LoginResult {
  const LoginResult({required this.tokens, required this.identity});

  final AuthTokens tokens;
  final Identity identity;
}

class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  /// There is no OTP, no registration and no self-service reset: accounts are
  /// issued by the center and the phone is a login identifier, not a verified
  /// channel.
  Future<LoginResult> login({required String phone, required String password}) async {
    final data = asMap(await _api.post('/auth/login', body: {
      'phone': phone,
      'password': password,
    }));
    final tokens = tokensFromJson(data);
    if (tokens == null) {
      throw StateError('Login response carried no token pair');
    }
    return LoginResult(tokens: tokens, identity: Identity.fromJson(data));
  }

  /// Called on every cold start rather than trusting cached state — which is
  /// how a block or a suspension takes effect within one app launch.
  Future<Identity> me() async => Identity.fromJson(asMap(await _api.get('/auth/me')));

  /// Required on first login when `must_change_password` is true. Clears the
  /// flag and revokes every other session.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _api.post('/auth/change-password', body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });

  /// Also soft-deletes the device's FCM row. Without that, a shared phone keeps
  /// receiving the previous user's pushes.
  Future<void> logout({String? fcmToken}) => _api.post('/auth/logout', body: {
        if (fcmToken != null) 'fcm_token': fcmToken,
      });
}
