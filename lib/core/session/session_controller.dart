import 'package:flutter/foundation.dart';

import '../../data/models/session_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../storage/token_store.dart';

enum SessionStatus {
  /// Before [SessionController.restore] has finished — the splash screen.
  unknown,

  /// A stored token pair exists but `/auth/me` could not be reached. Not the
  /// same as [signedOut]: the user is still signed in as far as the device is
  /// concerned, and showing them a login form would be a lie they cannot act
  /// on — the login POST would fail on the same dead connection.
  offline,

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
  String? _offlineReason;
  Future<void>? _restoring;

  SessionStatus get status => _status;

  Identity? get identity => _identity;

  AppUser? get user => _identity?.user;

  CenterBrand? get center => _identity?.center;

  /// Why the app is showing a wall rather than a login form.
  String? get lockReason => _lockReason;

  /// The network message behind [SessionStatus.offline], shown on the splash
  /// screen next to a retry button.
  String? get offlineReason => _offlineReason;

  bool get isTeacher => user?.role.isTeacher ?? false;

  bool get isAuthenticated =>
      _status == SessionStatus.signedIn || _status == SessionStatus.mustChangePassword;

  /// Cold start: if a token pair survived, ask the server who it belongs to.
  /// A stale cache is exactly how a suspension fails to take effect.
  ///
  /// Deduplicated: the splash screen's retry button and the app's own boot call
  /// can both land here, and two `/auth/me` calls racing each other can rotate
  /// the refresh token twice and revoke the family.
  Future<void> restore() => _restoring ??= _restore().whenComplete(() => _restoring = null);

  Future<void> _restore() async {
    final stored = await _tokens.read();
    if (stored == null) {
      _set(SessionStatus.signedOut);
      return;
    }
    try {
      _apply(await _auth.me());
    } on ApiException catch (e) {
      if (e.isLockedOut) {
        _lock(e.message);
      } else if (e.isNetwork) {
        // Offline on launch is not a signed-out user. The tokens stay, and the
        // splash screen offers a retry instead of dropping the user onto a
        // welcome screen whose only button would fail the same way.
        _offlineReason = e.message;
        _set(SessionStatus.offline);
      } else {
        // 401 with a rejected refresh token, a deleted account, a 404 — the
        // pair is genuinely worthless.
        await _tokens.clear();
        _set(SessionStatus.signedOut);
      }
    } catch (_) {
      // A shape the models could not read. Not a reason to throw the session
      // away, but not a reason to trust it either.
      _offlineReason = null;
      _set(SessionStatus.signedOut);
    }
  }

  Future<void> signIn({required String phone, required String password}) async {
    try {
      final result = await _auth.login(phone: phone, password: password);
      await _tokens.write(result.tokens);
      _apply(result.identity);
    } on ApiException catch (e) {
      // A blocked user and a suspended center both answer `403` to the login
      // itself. Without this the app would keep showing the error under the
      // password field and let them try again forever; `/locked` explains what
      // actually happened and who can undo it.
      if (e.isLockedOut) _lock(e.message);
      rethrow;
    }
  }

  /// Changing the password revokes **every** session server-side, this device's
  /// refresh token included — so the pair in secure storage is dead the moment
  /// the call succeeds.
  ///
  /// Keeping it would leave the app working until the access token expired and
  /// then sign the user out with no explanation, typically an hour later and in
  /// the middle of something. So we sign straight back in with the new password
  /// and store the fresh pair.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final phone = _identity?.user.phone;

    await _auth.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (phone != null) {
      try {
        final result = await _auth.login(phone: phone, password: newPassword);
        await _tokens.write(result.tokens);
        _apply(result.identity);
        return;
      } on ApiException {
        // The password did change — only the re-login failed, on a network
        // blip or a race. Sending the user to the login screen with their new
        // password is honest and recoverable; leaving them on a revoked token
        // is neither.
        await _tokens.clear();
        _identity = null;
        _set(SessionStatus.signedOut);
        return;
      }
    }

    final current = _identity;
    if (current != null) {
      _identity = current.copyWith(user: current.user.copyWith(mustChangePassword: false));
    }
    _set(SessionStatus.signedIn);
  }

  Future<void> signOut({String? fcmToken}) async {
    // Read before the clear: the server needs this exact refresh token to know
    // which device is leaving. Without it, it revokes every session the user
    // holds — and signing out of a phone would sign them out of every other
    // device they own.
    final stored = await _tokens.read();
    try {
      await _auth.logout(refreshToken: stored?.refresh, fcmToken: fcmToken);
    } catch (_) {
      // A logout that cannot reach the server still has to clear the device.
      // Leaving a token behind because the network blipped is worse than an
      // orphaned allowlist entry that expires on its own. Catching everything,
      // not just ApiException: a malformed response must not strand the user in
      // a session they asked to end.
    }
    await _tokens.clear();
    _identity = null;
    _lockReason = null;
    _offlineReason = null;
    _set(SessionStatus.signedOut);
  }

  /// Called by the API client when a refresh token is rejected.
  Future<void> expire() async {
    await _tokens.clear();
    _identity = null;
    // Both cleared: a stale lock reason would put the user in front of the
    // "your center is suspended" wall on their next, entirely valid, sign-in.
    _lockReason = null;
    _offlineReason = null;
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
    _offlineReason = null;
    _set(identity.user.mustChangePassword
        ? SessionStatus.mustChangePassword
        : SessionStatus.signedIn);
  }

  void _lock(String reason) {
    _lockReason = reason;
    _identity = null;
    _offlineReason = null;
    _set(SessionStatus.locked);
  }

  void _set(SessionStatus status) {
    _status = status;
    notifyListeners();
  }
}
