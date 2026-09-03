import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/session/session_controller.dart';
import '../core/session/settings_controller.dart';
import '../core/theme/ambient_background.dart';
import '../core/theme/app_theme.dart';
import '../l10n/strings.dart';
import 'router.dart';

/// The root widget: one router, and a theme painted by the user's own center.
///
/// The login screens are deliberately the last neutral surface in the app —
/// `brand_primary` and `brand_dark` arrive with the login response, and every
/// screen after it wears the center's colours.
class StepixApp extends StatefulWidget {
  const StepixApp({super.key});

  @override
  State<StepixApp> createState() => _StepixAppState();
}

class _StepixAppState extends State<StepixApp> {
  late final SessionController _session;
  late final SettingsController _settings;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _session = context.read<SessionController>();
    _settings = context.read<SettingsController>();
    // Built once: a GoRouter rebuilt on every frame would drop the navigation
    // stack under the user's feet.
    _router = createRouter(session: _session, settings: _settings);
    // `GET /settings` is public, so the force-update gate can be read before
    // anyone signs in. Waiting for a session meant a build too old to talk to
    // the API showed a login form instead of the update screen — and the login
    // was the request that would fail.
    _settings.ensureLoaded();
    _session.addListener(_onSession);
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _router.dispose();
    super.dispose();
  }

  /// A retry for the boot-time read: the first attempt runs before there is a
  /// connection to speak of, and [SettingsController.ensureLoaded] is a no-op
  /// once the answer is in.
  void _onSession() {
    if (_session.isAuthenticated) _settings.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final center = session.center;
    final language = session.user?.language ?? 'uz';

    // Dates are formatted by `DateFormat` all over the app, and it reads this
    // rather than a locale passed at each call site.
    Intl.defaultLocale = language;

    return MaterialApp.router(
      title: 'Stepix',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.of(primary: center?.brandPrimary, primaryDark: center?.brandDark),
      locale: Locale(language),
      supportedLocales: S.supported.map(Locale.new),
      localizationsDelegates: const [
        StringsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Uzbek and Russian both run long; a phone set to 200% text scale should
      // wrap, not clip the design's cards to unreadable stubs.
      builder: (context, child) => AmbientBackground(
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.4,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
