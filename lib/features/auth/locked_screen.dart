import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/session/session_controller.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';

/// The wall behind error codes `20106` (user blocked) and `20203` (center
/// suspended).
///
/// Both are `403`, and both are shown as an explanation rather than a login
/// form: signing in again cannot help, and a client that keeps offering the
/// form sends the user round a loop against a wall they cannot climb.
class LockedScreen extends StatelessWidget {
  const LockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final session = context.watch<SessionController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(34, 0, 34, 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BlobAvatar(
                text: '',
                icon: Icons.lock_outline_rounded,
                size: 88,
                background: AppColors.clayTint,
                foreground: AppColors.clay,
              ),
              const SizedBox(height: 22),
              Text(
                s.lockedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                session.lockReason ?? s.somethingWentWrong,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              GhostButton(
                label: s.backToLogin,
                onPressed: () async {
                  await session.signOut();
                  if (context.mounted) context.go('/welcome');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
