import 'package:flutter/foundation.dart';

/// Build-time configuration. Everything here is a `--dart-define`, so one build
/// script produces a staging APK and a release one without a code change:
///
/// ```sh
/// flutter build apk --dart-define=STEPIX_API_BASE_URL=https://api.stepix.uz/v1
/// ```
class AppConfig {
  const AppConfig._();

  /// The mobile API, which is its own Nest app on its own port — the panels'
  /// APIs are not reachable from the phone and never should be.
  ///
  /// The default is the emulator's route to the host machine: `10.0.2.2` on
  /// Android, `localhost` on everything else. A physical device on the same
  /// Wi-Fi needs the machine's LAN address passed in explicitly.
  static String get baseUrl {
    const override = String.fromEnvironment('STEPIX_API_BASE_URL');
    if (override.isNotEmpty) return override;
    final host = platform == 'android' ? '10.0.2.2' : 'localhost';
    return 'http://$host:3003/v1';
  }

  /// Sent as `X-App-Version` on every request. The server compares it against
  /// `min_supported_version` and answers with `force_update` — the client never
  /// compares version strings itself.
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
