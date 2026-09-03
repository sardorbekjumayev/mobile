import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';

/// Shown while [SessionController.restore] asks `/auth/me` who the stored
/// tokens belong to — and, when that call cannot reach the server, shown with a
/// retry button instead.
///
/// The retry matters more than it looks: the alternative is dropping a user who
/// is already signed in onto the welcome screen, whose only button posts to the
/// same unreachable API. "Sign in again" is not an instruction anyone can
/// follow with no connection.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final offline = session.status == SessionStatus.offline;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: context.brand.gradient,
                    borderRadius: AppShapes.splash,
                  ),
                  child: const Icon(Icons.bolt_rounded, size: 48, color: Colors.white),
                ),
                if (offline) ...[
                  const SizedBox(height: 26),
                  Text(
                    S.of(context).offlineTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (session.offlineReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      session.offlineReason!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  BrandButton(
                    key: const Key('splash-retry'),
                    label: S.of(context).retry,
                    onPressed: session.restore,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
