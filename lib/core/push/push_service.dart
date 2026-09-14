import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart' show homeFor;
import '../../data/repositories/profile_repository.dart';
import '../../features/profile/notification_target.dart';
import '../../l10n/strings.dart';
import '../session/session_controller.dart';

/// Runs in its own isolate when a push arrives with the app in the background.
/// The system tray already shows the `notification` block; there is nothing
/// else to do, but FCM requires a registered handler.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

/// Firebase Cloud Messaging, as far as the app is concerned.
///
/// Push is optional: until `google-services.json` / `GoogleService-Info.plist`
/// are added, [init] fails quietly and every method here is a no-op. The feed
/// (`GET /notification`) stays the source of truth either way.
class PushService {
  PushService(this._profiles);

  final ProfileRepository _profiles;

  bool _enabled = false;
  String? _token;
  bool _registered = false;
  RemoteMessage? _pendingOpen;

  SessionController? _session;
  GoRouter? _router;
  GlobalKey<ScaffoldMessengerState>? _messenger;
  final _subs = <StreamSubscription<dynamic>>[];

  /// Ticks whenever a push arrives in the foreground or is opened, so screens
  /// showing notification state can reload.
  final ValueNotifier<int> received = ValueNotifier(0);

  bool get enabled => _enabled;

  /// The device's current FCM token — passed to logout so the server forgets
  /// this phone.
  String? get token => _token;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
      _enabled = true;
    } catch (e) {
      debugPrint('Push disabled (no Firebase config): $e');
    }
  }

  /// Called once the router and messenger exist (from the root widget).
  void attach({
    required SessionController session,
    required GoRouter router,
    required GlobalKey<ScaffoldMessengerState> messenger,
  }) {
    _session = session;
    _router = router;
    _messenger = messenger;
    if (!_enabled) return;

    session.addListener(_onSession);
    _subs
      ..add(FirebaseMessaging.onMessage.listen(_onForeground))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen(_onOpened))
      ..add(FirebaseMessaging.instance.onTokenRefresh.listen(_onToken));
    unawaited(FirebaseMessaging.instance.getInitialMessage().then((m) {
      if (m != null) _onOpened(m, coldStart: true);
    }).catchError((Object _) {}));
    _onSession();
  }

  void detach() {
    _session?.removeListener(_onSession);
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    _session = null;
    _router = null;
    _messenger = null;
  }

  void _onSession() {
    final session = _session;
    if (session == null) return;
    if (session.status == SessionStatus.signedIn) {
      if (!_registered) {
        _registered = true;
        unawaited(_registerDevice());
      }
      final pending = _pendingOpen;
      if (pending != null) {
        _pendingOpen = null;
        _onOpened(pending, coldStart: true);
      }
    } else if (!session.isAuthenticated) {
      _registered = false;
    }
  }

  Future<void> _registerDevice() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) await _onToken(token);
    } catch (e) {
      debugPrint('Push token registration failed: $e');
    }
  }

  Future<void> _onToken(String token) async {
    _token = token;
    if (_session?.status != SessionStatus.signedIn) return;
    try {
      await _profiles.registerDevice(token);
    } catch (e) {
      debugPrint('POST /fcm-token failed: $e');
    }
  }

  void _onForeground(RemoteMessage message) {
    received.value++;
    final session = _session;
    final messenger = _messenger?.currentState;
    if (session == null || messenger == null || !session.isAuthenticated) return;

    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;
    final s = S(session.user?.language ?? 'uz');
    final canOpen = _targetOf(message) != null;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (body.isNotEmpty) Text(body),
          ],
        ),
        action: canOpen
            ? SnackBarAction(label: s.openAction, onPressed: () => _onOpened(message))
            : null,
      ));
  }

  String? _targetOf(RemoteMessage message) => notificationTarget(
        '${message.data['type'] ?? ''}',
        message.data['ref_id']?.toString(),
        teacher: _session?.isTeacher ?? false,
      );

  /// A tapped push: mark its row read, then go where the feed row would.
  void _onOpened(RemoteMessage message, {bool coldStart = false}) {
    final session = _session;
    final router = _router;
    if (session == null || router == null) return;
    if (session.status != SessionStatus.signedIn) {
      // Cold start before `/auth/me` answered — replay once signed in.
      _pendingOpen = message;
      return;
    }

    final type = '${message.data['type'] ?? ''}';
    final ref = message.data['ref_id']?.toString();
    if (type.isNotEmpty && ref != null && ref.isNotEmpty) {
      unawaited(_profiles.markReadByRef(type, ref).catchError((Object _) {}));
    }
    received.value++;

    final target = _targetOf(message);
    if (target == null) return;
    if (coldStart) router.go(homeFor(session));
    unawaited(router.push(target));
  }
}
