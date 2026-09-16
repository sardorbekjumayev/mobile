import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A stored token pair. `null` [access] means "signed out".
class AuthTokens {
  const AuthTokens({required this.access, required this.refresh, this.expiresAt});

  final String access;
  final String refresh;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Where the token pair lives between launches.
///
/// An interface rather than a direct `FlutterSecureStorage` call so tests —
/// and the widget tree, which has no platform channel under `flutter test` —
/// can swap in [InMemoryTokenStore].
abstract class TokenStore {
  Future<AuthTokens?> read();

  Future<void> write(AuthTokens tokens);

  Future<void> clear();
}

/// Keychain on iOS, AES-GCM behind the Android keystore on Android.
///
/// The `encryptedSharedPreferences: true` flag is gone in
/// flutter_secure_storage 11: encryption is no longer opt-in, it is the only
/// mode, so the default options are the ones that flag used to select.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'stepix.access_token';
  static const _kRefresh = 'stepix.refresh_token';
  static const _kExpires = 'stepix.expires_at';

  /// Unreadable storage means "signed out", never a crash.
  ///
  /// The platform can refuse a read for reasons that have nothing to do with
  /// this app's logic: a keystore entry invalidated by a screen-lock change, a
  /// restored device backup, or — the case that brought this in — tokens
  /// written by an older encryption backend that the current one cannot open.
  /// Every one of those should drop the user on the login screen, not hold the
  /// splash screen forever, so the unreadable pair is wiped and treated as
  /// absent.
  @override
  Future<AuthTokens?> read() async {
    try {
      final access = await _storage.read(key: _kAccess);
      final refresh = await _storage.read(key: _kRefresh);
      if (access == null || refresh == null) return null;
      final expires = await _storage.read(key: _kExpires);
      return AuthTokens(
        access: access,
        refresh: refresh,
        expiresAt: expires == null ? null : DateTime.tryParse(expires),
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _kAccess, value: tokens.access);
    await _storage.write(key: _kRefresh, value: tokens.refresh);
    await _storage.write(
      key: _kExpires,
      value: tokens.expiresAt?.toIso8601String(),
    );
  }

  /// Best-effort: a delete that throws must not stop a sign-out.
  @override
  Future<void> clear() async {
    for (final key in const [_kAccess, _kRefresh, _kExpires]) {
      try {
        await _storage.delete(key: key);
      } catch (_) {
        /* nothing left to do — the next write overwrites it anyway */
      }
    }
  }
}

/// Non-persistent store used by tests and by the web build, where there is no
/// keychain worth the name.
class InMemoryTokenStore implements TokenStore {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
