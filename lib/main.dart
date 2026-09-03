import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/config.dart';
import 'app/stepix_app.dart';
import 'core/api/api_client.dart';
import 'core/session/session_controller.dart';
import 'core/session/settings_controller.dart';
import 'core/storage/token_store.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/student_repository.dart';
import 'data/repositories/teacher_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Month names in three languages — `DateFormat('d MMM')` throws without them
  // for anything but `en`.
  await initializeDateFormatting();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final config = ApiConfig(
    baseUrl: AppConfig.baseUrl,
    appVersion: AppConfig.appVersion,
    platform: AppConfig.platform,
  );
  final tokens = SecureTokenStore();

  // The session is built before the client so the client can hand it a rejected
  // refresh token; the client is built before the session's repository, so the
  // wiring is closed with a setter rather than a constructor argument.
  late final SessionController session;
  final api = DioApiClient(
    config: config,
    tokenStore: tokens,
    onSessionExpired: () => session.expire(),
  );
  final profiles = ProfileRepository(api);
  final auth = AuthRepository(api);
  session = SessionController(auth: auth, tokens: tokens, config: config);

  // Asks `/auth/me` who the stored tokens belong to before the first frame that
  // could show a home screen — a cached role is exactly how a suspension fails
  // to take effect.
  unawaited(session.restore());

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiConfig>.value(value: config),
        Provider<TokenStore>.value(value: tokens),
        Provider<ApiClient>.value(value: api),
        Provider(create: (_) => StudentRepository(api)),
        Provider(create: (_) => TeacherRepository(api)),
        Provider<ProfileRepository>.value(value: profiles),
        // The phone screen calls `/auth/lookup` before there is a session, so
        // the repository is a provider rather than a private field of one.
        Provider<AuthRepository>.value(value: auth),
        ChangeNotifierProvider<SessionController>.value(value: session),
        ChangeNotifierProvider(create: (_) => SettingsController(profiles)),
      ],
      child: const StepixApp(),
    ),
  );
}
