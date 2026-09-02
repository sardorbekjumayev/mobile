import 'package:flutter/foundation.dart';

import '../../data/models/session_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../storage/token_store.dart';

enum SessionStatus {
  /// Before [SessionController.restore] has finished — the splash screen.
  unknown,
  signedOut,

  /// Signed in, but `must_change_password` blocks every other screen.
  mustChangePassword,
  signedIn,

  /// A wall the user cannot climb by signing in again: the account is blocked
  /// or the center is suspended. Distinct from [signedOut] so the app shows an
  /// explanation instead of a login form that will fail identically.
  locked,
}

/// The one piece of state every screen depends on.
class SessionController extends ChangeNotifier {
  SessionController({
    required AuthRepository auth,
    required TokenStore tokens,
    required ApiConfig config,
  })  : _auth = auth,
        _tokens = tokens,
        _config = config;

  final AuthRepository _auth;
  final TokenStore _tokens;
  final ApiConfig _config;

  SessionStatus _status = SessionStatus.unknown;
  Identity? _identity;
  String? _lockReason;

  SessionStatus get status => _status;

  Identity? get identity => _identity;

  AppUser? get user => _identity?.user;

  CenterBrand? get center => _identity?.center;

  /// Why the app is showing a wall rather than a login form.
  String? get lockReason => _lockReason;

  bool get isTeacher => user?.role.isTeacher ?? false;

  bool get isAuthenticated =>
      _status == SessionStatus.signedIn || _status == SessionStatus.mustChangePassword;

  /// Cold start: if a token pair survived, ask the server who it belongs to.
  /// A stale cache is exactly how a suspension fails to take effect.
  Future<void> restore() async {
    final stored = await _tokens.read();
    if (stored == null) {
      _set(SessionStatus.signedOut);
      return;
    }
    try {
      _apply(await _auth.me());
    } on ApiException catch (e) {
      if (e.isBlocked || e.isCenterSuspended) {
        _lock(e.message);
      } else if (e.isNetwork) {
        // Offline on launch is not a signed-out user. Keep the tokens and let
        // the first successful call settle it.
        _set(SessionStatus.signedOut);
      } else {
        await _tokens.clear();
        _set(SessionStatus.signedOut);
      }
    }
  }

  Future<void> signIn({required String phone, required String password}) async {
    final result = await _auth.login(phone: phone, password: password);
    await _tokens.write(result.tokens);
    _apply(result.identity);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _auth.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    final current = _identity;
    if (current != null) {
      _identity = current.copyWith(user: current.user.copyWith(mustChangePassword: false));
    }
    _set(SessionStatus.signedIn);
  }

  Future<void> signOut({String? fcmToken}) async {
    try {
      await _auth.logout(fcmToken: fcmToken);
    } on ApiException {
      // A logout that cannot reach the server still has to clear the device.
      // Leaving a token behind because the network blipped is worse than an
      // orphaned allowlist entry that expires on its own.
    }
    await _tokens.clear();
    _identity = null;
    _lockReason = null;
    _set(SessionStatus.signedOut);
  }

  /// Called by the API client when a refresh token is rejected.
  Future<void> expire() async {
    await _tokens.clear();
    _identity = null;
    _set(SessionStatus.signedOut);
  }

  /// Language is per-user and travels on `Accept-Language`, which resolves
  /// every `_i18n` column server-side.
  void setLanguage(String language) {
    _config.language = language;
    final current = _identity;
    if (current != null) {
      _identity = current.copyWith(user: current.user.copyWith(language: language));
    }
    notifyListeners();
  }

  void updateUser(AppUser user) {
    final current = _identity;
    if (current == null) return;
    _identity = current.copyWith(user: user);
    notifyListeners();
  }

  void _apply(Identity identity) {
    _identity = identity;
    _config.language = identity.user.language;
    _lockReason = null;
    _set(identity.user.mustChangePassword
        ? SessionStatus.mustChangePassword
        : SessionStatus.signedIn);
  }

  void _lock(String reason) {
    _lockReason = reason;
    _identity = null;
    _set(SessionStatus.locked);
  }

  void _set(SessionStatus status) {
    _status = status;
    notifyListeners();
  }
}
