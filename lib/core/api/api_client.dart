import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_store.dart';
import 'api_exception.dart';
import 'envelope.dart';

/// Everything the repositories need from the network.
///
/// Repositories depend on this, never on Dio, so a repository test is a plain
/// unit test with a fake client and no HTTP stack at all.
abstract class ApiClient {
  /// Returns the `data` member of the success envelope.
  Future<dynamic> get(String path, {Map<String, dynamic>? query});

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query});

  Future<dynamic> put(String path, {Object? body});

  Future<dynamic> delete(String path, {Object? body});

  /// Multipart upload — used only by `POST /profile/avatar`.
  Future<dynamic> upload(String path, {required String field, required String filePath});
}

/// Per-request context the API contract requires on every call.
class ApiConfig {
  ApiConfig({
    required this.baseUrl,
    required this.appVersion,
    required this.platform,
    this.language = 'uz',
  });

  final String baseUrl;
  final String appVersion;

  /// `ios` or `android`. Sent verbatim as `X-Platform`.
  final String platform;

  /// `uz` · `ru` · `en`. Resolves every `_i18n` column server-side, which is
  /// why the client never ships translations of server-owned strings.
  String language;
}

/// Called when the refresh token is rejected and the session is unrecoverable.
typedef OnSessionExpired = FutureOr<void> Function();

class DioApiClient implements ApiClient {
  DioApiClient({
    required this.config,
    required TokenStore tokenStore,
    Dio? dio,
    this.onSessionExpired,
  })  : _tokens = tokenStore,
        dio = dio ?? Dio() {
    this.dio.options
      ..baseUrl = config.baseUrl
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 30)
      // Envelopes arrive with a 4xx status too, and the filter's body is the
      // only place the business code lives. Let every status through and read
      // the envelope instead of guessing from the status line.
      ..validateStatus = (_) => true;
  }

  final Dio dio;
  final ApiConfig config;
  final TokenStore _tokens;
  final OnSessionExpired? onSessionExpired;

  /// In flight refresh, shared by every request that hit a 401 at once. Without
  /// it, a home screen firing four parallel GETs rotates the refresh token four
  /// times and revokes its own family.
  Future<AuthTokens?>? _refreshing;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  @override
  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query}) =>
      _send('POST', path, body: body, query: query);

  @override
  Future<dynamic> put(String path, {Object? body}) => _send('PUT', path, body: body);

  @override
  Future<dynamic> delete(String path, {Object? body}) => _send('DELETE', path, body: body);

  @override
  Future<dynamic> upload(String path, {required String field, required String filePath}) async {
    final form = FormData.fromMap({field: await MultipartFile.fromFile(filePath)});
    return _send('POST', path, body: form);
  }

  Future<Map<String, dynamic>> _headers({bool withAuth = true}) async {
    final headers = <String, dynamic>{
      'Accept': 'application/json',
      'Accept-Language': config.language,
      'X-App-Version': config.appVersion,
      'X-Platform': config.platform,
    };
    if (withAuth) {
      final tokens = await _tokens.read();
      if (tokens != null) headers['Authorization'] = 'Bearer ${tokens.access}';
    }
    return headers;
  }

  /// The two endpoints that must never trigger a token refresh.
  ///
  /// `/auth/login` answers `401` for a wrong password, and `/auth/refresh`
  /// answers `401` for a rejected refresh token. Refreshing in response to
  /// either is at best a wasted round trip and at worst an infinite loop.
  static bool _isAuthEndpoint(String path) =>
      path.endsWith('/auth/login') || path.endsWith('/auth/refresh');

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool allowRetry = true,
    bool allowNetworkRetry = true,
  }) async {
    final Response<dynamic> response;
    try {
      response = await dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method, headers: await _headers()),
      );
    } on DioException catch (e) {
      // A phone handing the radio back from Wi-Fi to LTE drops exactly one
      // connection. Retrying it once turns a visible "internet aloqasi yo'q"
      // into a request the user never noticed — but only where a repeat is
      // harmless: a re-sent POST could submit a test twice.
      if (allowNetworkRetry && _isTransient(e) && _isIdempotent(method)) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        return _send(
          method,
          path,
          body: body,
          query: query,
          allowRetry: allowRetry,
          allowNetworkRetry: false,
        );
      }
      throw ApiException.network(_networkMessage(e));
    }

    final envelope = _envelopeOf(response);

    if (envelope.isSuccess) return envelope.data;

    final failure = envelope.toException(httpStatus: response.statusCode ?? envelope.statusCode);

    // One retry, and only for a genuinely expired access token. A wrong
    // password, a blocked user and a suspended center all arrive as 401/403
    // too, and none of them is fixed by a new token — see
    // [ApiException.isUnauthenticated].
    if (failure.isUnauthenticated && allowRetry && !_isAuthEndpoint(path)) {
      final refreshed = await _refresh();
      if (refreshed != null) {
        return _send(method, path, body: body, query: query, allowRetry: false);
      }
      await onSessionExpired?.call();
    }

    throw failure;
  }

  /// Failures where the request never reached the server, so repeating it
  /// cannot duplicate anything server-side.
  static bool _isTransient(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  static bool _isIdempotent(String method) => method == 'GET' || method == 'DELETE';

  Envelope _envelopeOf(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('statusCode')) {
      return Envelope.fromJson(data);
    }
    // A gateway or proxy answered instead of the API — 502 HTML, an empty body.
    // Synthesise an envelope so callers see one exception type either way.
    final status = response.statusCode ?? 0;
    return Envelope(
      statusCode: status,
      code: status >= 200 && status < 300 ? 0 : 10000,
      message: response.statusMessage ?? 'Xatolik yuz berdi',
      data: data,
    );
  }

  /// Rotating refresh, deduplicated across concurrent callers.
  Future<AuthTokens?> _refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<AuthTokens?> _doRefresh() async {
    final current = await _tokens.read();
    if (current == null) return null;

    final Response<dynamic> response;
    try {
      response = await dio.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': current.refresh},
        options: Options(headers: await _headers(withAuth: false)),
      );
    } on DioException {
      // The network is down, not the session. Keep the tokens so the next
      // launch on a working connection still signs in.
      return null;
    }

    final envelope = _envelopeOf(response);
    if (!envelope.isSuccess || envelope.data is! Map<String, dynamic>) {
      await _tokens.clear();
      return null;
    }

    final data = envelope.data as Map<String, dynamic>;
    final tokens = tokensFromJson(data);
    if (tokens == null) {
      await _tokens.clear();
      return null;
    }
    await _tokens.write(tokens);
    return tokens;
  }

  static String _networkMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server javob bermadi. Internetni tekshirib, qayta urining.';
      case DioExceptionType.connectionError:
        return 'Internet aloqasi yo\'q.';
      case DioExceptionType.cancel:
        return 'So\'rov bekor qilindi.';
      case DioExceptionType.badCertificate:
        // Almost always a proxy or a phone whose clock is wrong, not the API.
        return 'Xavfsiz ulanish o\'rnatilmadi. Telefon sanasi va vaqtini tekshiring.';
      default:
        return 'Tarmoq xatosi. Qayta urining.';
    }
  }
}

/// Reads the `access_token` / `refresh_token` / `expires_in` triple that both
/// `/auth/login` and `/auth/refresh` return.
AuthTokens? tokensFromJson(Map<String, dynamic> json) {
  final access = json['access_token']?.toString();
  final refresh = json['refresh_token']?.toString();
  if (access == null || refresh == null || access.isEmpty || refresh.isEmpty) return null;
  final expiresIn = json['expires_in'];
  final seconds = expiresIn is num ? expiresIn.toInt() : int.tryParse('$expiresIn');
  return AuthTokens(
    access: access,
    refresh: refresh,
    expiresAt: seconds == null ? null : DateTime.now().add(Duration(seconds: seconds)),
  );
}
