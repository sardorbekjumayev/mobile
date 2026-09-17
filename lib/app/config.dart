import 'package:flutter/foundation.dart';

/// Build-time configuration. Everything here is a `--dart-define`, so one build
/// script produces a staging APK and a release one without a code change:
///
/// ```sh
/// flutter build apk --release \
///   --dart-define=STEPIX_API_BASE_URL=https://api.stepix.uz/v1
/// ```
class AppConfig {
  const AppConfig._();

  /// The mobile API behind nginx TLS. Its own Nest app on its own port — the
  /// panels' APIs are not reachable from the phone and never should be.
  ///
  /// **HTTPS is the default, including in debug.** Two reasons it is not a
  /// localhost address any more: a release APK has no cleartext permission at
  /// all (see `network_security_config.xml`), and `10.0.2.2` only exists inside
  /// the Android emulator — on a real phone it resolves to nothing, which the
  /// app could only report as "internet aloqasi yo'q".
  ///
  /// To work against a laptop instead, pass the address explicitly:
  ///
  /// ```sh
  /// flutter run --dart-define=STEPIX_API_BASE_URL=http://10.0.2.2:3003/v1   # emulator
  /// flutter run --dart-define=STEPIX_API_BASE_URL=http://192.168.1.50:3003/v1  # LAN phone
  /// ```
  ///
  /// A LAN address over plain HTTP also needs its own `<domain>` entry in
  /// `android/app/src/main/res/xml/network_security_config.xml`; only the
  /// emulator hosts are permitted there out of the box.
  static const _defaultBaseUrl = 'https://api.stepix.uz/v1';

  static String get baseUrl {
    const override = String.fromEnvironment('STEPIX_API_BASE_URL');
    final raw = override.isNotEmpty ? override : _defaultBaseUrl;
    // A trailing slash makes Dio resolve `/auth/login` against the host root
    // and drop `/v1` — a 404 that reads like a missing endpoint.
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// The center panel's public origin — where static documents such as the
  /// solution-sheet sample live. On this deployment the API and the panel are
  /// sibling hosts (`api.<domain>` / `panel.<domain>`), so the panel origin is
  /// derived from [baseUrl] unless `STEPIX_PANEL_URL` names it outright.
  static String get centerPanelUrl {
    const override = String.fromEnvironment('STEPIX_PANEL_URL');
    if (override.isNotEmpty) {
      return override.endsWith('/') ? override.substring(0, override.length - 1) : override;
    }
    final api = Uri.parse(baseUrl);
    final host = api.host.startsWith('api.') ? 'panel.${api.host.substring(4)}' : api.host;
    return Uri(scheme: api.scheme, host: host, port: api.hasPort ? api.port : null).toString();
  }

  /// The printable sample of the worked-solution sheet convention.
  static String get solutionSampleUrl => '$centerPanelUrl/yechim-varagi-namuna.pdf';

  /// True when [baseUrl] is not TLS — the one case where a failure is more
  /// likely to be the dev machine than the phone's connection.
  static bool get isInsecureBaseUrl => !baseUrl.startsWith('https://');

  /// Sent as `X-App-Version` on every request, and as `?version=` on
  /// `GET /settings` — the server compares it against `min_supported_version`
  /// and answers with `force_update`; the client never compares version
  /// strings itself.
  static const appVersion =
      String.fromEnvironment('STEPIX_APP_VERSION', defaultValue: '1.0.0');

  /// `X-Platform`, verbatim.
  ///
  /// Read from [defaultTargetPlatform] rather than `dart:io`, which does not
  /// exist on web and would break that build on the import line alone.
  static String get platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      final other => other.name.toLowerCase(),
    };
  }
}
