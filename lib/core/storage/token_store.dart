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

/// Keychain on iOS, EncryptedSharedPreferences on Android.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _kAccess = 'stepix.access_token';
  static const _kRefresh = 'stepix.refresh_token';
  static const _kExpires = 'stepix.expires_at';

  @override
  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    if (access == null || refresh == null) return null;
    final expires = await _storage.read(key: _kExpires);
    return AuthTokens(
      access: access,
      refresh: refresh,
      expiresAt: expires == null ? null : DateTime.tryParse(expires),
    );
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

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kExpires);
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
