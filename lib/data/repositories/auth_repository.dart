import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
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
      'phone': normalizePhone(phone),
      'password': password,
    }));
    final tokens = tokensFromJson(data);
    if (tokens == null) {
      // Was a `StateError`, which is an assertion about our own code and travels
      // as an unhandled crash. Every login call site already catches
      // [ApiException] and shows its message; a malformed login response has to
      // arrive as one of those, not as a red screen.
      throw ApiException(
        message: 'Serverdan noto\'g\'ri javob keldi. Birozdan so\'ng qayta urining.',
        statusCode: 502,
      );
    }
    return LoginResult(tokens: tokens, identity: Identity.fromJson(data));
  }

  /// Called on every cold start rather than trusting cached state — which is
  /// how a block or a suspension takes effect within one app launch.
  Future<Identity> me() async => Identity.fromJson(asMap(await _api.get('/auth/me')));

  /// Required on first login when `must_change_password` is true. Clears the
  /// flag and revokes **every** session, this device's included — which is why
  /// [SessionController.changePassword] signs back in immediately afterwards
  /// rather than keeping a token pair the server has already thrown away.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _api.post('/auth/change-password', body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });

  /// Signs out **this device only**, and drops its FCM row.
  ///
  /// [refreshToken] is what makes it this device only: omitting it makes the
  /// server fall back to `revokeAll`, so signing out on a phone would also
  /// sign the user out on their tablet and on any teacher machine they left
  /// open. Without the FCM half, a shared phone keeps receiving the previous
  /// user's pushes.
  Future<void> logout({String? refreshToken, String? fcmToken}) =>
      _api.post('/auth/logout', body: {
        if (refreshToken != null && refreshToken.isNotEmpty) 'refresh_token': refreshToken,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      });
}

/// `+998 90 123 45 67`, `998901234567`, `901234567` → `998901234567`.
///
/// The server normalises too, but only after validation: a number the user
/// pasted with spaces in it would otherwise come back as `20111 phone invalid`
/// and read like a wrong password.
String normalizePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  // A leading 0 or 8 is the trunk prefix people type out of habit: 8998…
  if (digits.length == 13 && (digits.startsWith('0') || digits.startsWith('8'))) {
    digits = digits.substring(1);
  }
  if (digits.length == 9) return '998$digits';
  return digits;
}
