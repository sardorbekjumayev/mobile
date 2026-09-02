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

  /// True when the session is over and the user must sign in again.
  ///
  /// A `403` with [ErrorCodes.userBlocked] or [ErrorCodes.centerSuspended] is
  /// explicitly *not* this: treating those as an expired token logs the user
  /// out in a loop against a wall they cannot climb.
  bool get isUnauthenticated => statusCode == 401 && !isBlocked && !isCenterSuspended;

  bool get isBlocked => code == ErrorCodes.userBlocked;

  bool get isCenterSuspended => code == ErrorCodes.centerSuspended;

  bool get isWrongCredentials => code == ErrorCodes.wrongCredentials;

  bool get isNetwork => statusCode == 0;

  /// The module the code belongs to, e.g. `20802` → `20800` (student test).
  int get block => code == 0 ? 0 : (code ~/ 100) * 100;

  @override
  String toString() => 'ApiException($statusCode/$code): $message';
}
