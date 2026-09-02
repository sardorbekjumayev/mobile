import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/session/session_controller.dart';
import '../../core/session/settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/profile_repository.dart';
import '../../l10n/strings.dart';
import 'profile_screen.dart' show ProfileRow;

/// The two account actions that are reachable from more than one screen, kept
/// in one place so the confirm dialog and the language list cannot drift.

String languageName(String code) => switch (code) {
      'ru' => 'Русский',
      'en' => 'English',
      _ => 'O\'zbekcha',
    };

/// Language is per-user and travels on `Accept-Language`, which resolves every
/// `_i18n` column server-side — so it is saved to the profile rather than kept
/// on the device. A student who signs in on a second phone keeps their language.
Future<void> pickLanguage(BuildContext context) async {
  final session = context.read<SessionController>();
  final current = session.user?.language ?? 'uz';

  final picked = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          for (final code in S.supported)
            ProfileRow(
              icon: code == current ? Icons.check_circle_rounded : Icons.circle_outlined,
              label: languageName(code),
              onTap: () => context.pop(code),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (picked == null || picked == current || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final failed = S.of(context).somethingWentWrong;
  // Applied locally first so the sheet closes into the new language; the PUT
  // makes it stick for the next device.
  session.setLanguage(picked);
  try {
    final updated = await context.read<ProfileRepository>().update(language: picked);
    session.updateUser(updated.user);
  } catch (_) {
    session.setLanguage(current);
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}

/// Signing out clears the device even when the call fails: leaving a token
/// behind because the network blipped is worse than an orphaned allowlist row
/// that expires on its own.
Future<void> confirmSignOut(BuildContext context) async {
  final s = S.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppShapes.tileRadius),
      title: Text(s.logoutConfirm, style: Theme.of(context).textTheme.titleMedium),
      actions: [
        TextButton(onPressed: () => context.pop(false), child: Text(s.cancel)),
        TextButton(
          onPressed: () => context.pop(true),
          child: Text(s.logout, style: const TextStyle(color: AppColors.clay)),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;
  final settings = context.read<SettingsController>();
  await context.read<SessionController>().signOut();
  settings.clear();
}
