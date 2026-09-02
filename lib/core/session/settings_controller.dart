import 'package:flutter/foundation.dart';

import '../../data/models/profile_models.dart';
import '../../data/repositories/profile_repository.dart';
import '../api/api_exception.dart';

/// `GET /settings` — the support links, the store version and the one flag that
/// can wall the app: `force_update`.
///
/// The flag is decided server-side from `X-App-Version`; the client only obeys
/// it. Comparing version strings on the device means shipping the fix for the
/// comparison in a build that is already too old to install.
class SettingsController extends ChangeNotifier {
  SettingsController(this._profile);

  final ProfileRepository _profile;

  AppSettings? _settings;
  bool _loading = false;

  AppSettings? get settings => _settings;

  /// False until the answer is in. An unreachable settings endpoint must never
  /// lock a student out of a test they can still submit.
  bool get forceUpdate => _settings?.forceUpdate ?? false;

  /// Called once the session is authenticated — the endpoint is behind auth.
  Future<void> ensureLoaded() async {
    if (_loading || _settings != null) return;
    await reload();
  }

  Future<void> reload() async {
    _loading = true;
    try {
      _settings = await _profile.settings();
      notifyListeners();
    } on ApiException {
      // Left null on purpose: see [forceUpdate].
    } finally {
      _loading = false;
    }
  }

  /// Dropped on sign-out so the next user on the device re-reads the flag
  /// rather than inheriting the previous session's answer.
  void clear() {
    _settings = null;
    notifyListeners();
  }
}
