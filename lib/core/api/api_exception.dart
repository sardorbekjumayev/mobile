/// Error codes the client has to act on rather than merely display.
///
/// See `02-API-MOBILE.md` §1. Everything else is shown as the server's own
/// translated `message` — the backend resolves `translation.ERROR.{code}`
/// against `Accept-Language`, so re-translating it here would only produce a
/// second, staler copy of the same string.
class ErrorCodes {
  const ErrorCodes._();

  /// Wrong phone **or** wrong password. Deliberately one code for both halves:
  /// splitting them turns the login form into a phone-number oracle.
  static const wrongCredentials = 20105;

  /// The user was blocked by their center. A `403`, not a `401` — retrying
  /// with a fresh token will not help.
  static const userBlocked = 20106;

  /// No bearer token, or one the server will not accept. The only 401 a token
  /// refresh can actually fix, alongside [tokenExpired].
  static const unauthorized = 10002;

  /// The access token's lifetime ran out. Refreshable.
  static const tokenExpired = 20104;

  /// A refresh token that is not in the allowlist. Presented twice means stolen
  /// once, so the server revokes the whole family — this session is over and no
  /// second refresh will bring it back.
  static const refreshInvalid = 20103;

  /// A center admin or super admin signing into the student/teacher app. Also a
  /// `401`, and also unfixable by a refresh: the account simply does not belong
  /// to this app.
  static const wrongRoleForApp = 20110;

  /// `must_change_password` is still true. A `403` — the session is valid, the
  /// user is just standing in front of one screen.
  static const passwordChangeRequired = 20107;

  /// New password fails the strength rule.
  static const passwordWeak = 20108;

  /// New password is the old one.
  static const passwordSame = 20109;

  /// The center is suspended. Not the user's fault; the client says
  /// "contact your learning center" rather than showing a login error.
  static const centerSuspended = 20203;

  /// A second submit for the same attempt. The first submission stands.
  static const testAlreadySubmitted = 20802;
}

/// A failure that carries the server's own envelope.
///
/// [code] is the business code from the error envelope (`0` when the failure
/// never reached the API — a socket timeout has no business code).
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode = 0,
    this.code = 0,
    this.path,
  });

  /// Nothing reached the server: DNS, TLS, timeout, airplane mode.
  factory ApiException.network(String message) =>
      ApiException(message: message, statusCode: 0, code: 0);

  final String message;
  final int statusCode;
  final int code;
  final String? path;

  /// True only for a 401 a **token refresh could actually fix**.
  ///
  /// The API answers `401` for four different things, and only two of them are
  /// about the token:
  ///
  /// * `10002` / `20104` — missing or expired access token. Refreshable.
  /// * `20105` — wrong phone or password. There is no session yet; refreshing
  ///   is meaningless and calling `onSessionExpired` on a failed login wiped
  ///   the session of a user who was merely mistyping their password.
  /// * `20110` — the account belongs to a panel, not to this app. A new token
  ///   would be refused for exactly the same reason.
  ///
  /// A `403` with [ErrorCodes.userBlocked] or [ErrorCodes.centerSuspended] is
  /// also explicitly not this: treating those as an expired token logs the user
  /// out in a loop against a wall they cannot climb.
  bool get isUnauthenticated =>
      statusCode == 401 &&
      !isWrongCredentials &&
      !isWrongRoleForApp &&
      !isBlocked &&
      !isCenterSuspended;

  /// The session is unrecoverable — the refresh token itself was rejected.
  bool get isRefreshRejected => code == ErrorCodes.refreshInvalid;

  bool get isWrongRoleForApp => code == ErrorCodes.wrongRoleForApp;

  /// Blocked user or suspended center: a wall, not a login error.
  bool get isLockedOut => isBlocked || isCenterSuspended;

  bool get isBlocked => code == ErrorCodes.userBlocked;

  bool get isCenterSuspended => code == ErrorCodes.centerSuspended;

  bool get isWrongCredentials => code == ErrorCodes.wrongCredentials;

  bool get isNetwork => statusCode == 0;

  /// The module the code belongs to, e.g. `20802` → `20800` (student test).
  int get block => code == 0 ? 0 : (code ~/ 100) * 100;

  @override
  String toString() => 'ApiException($statusCode/$code): $message';
}
