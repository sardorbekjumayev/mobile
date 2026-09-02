import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/config.dart';
import '../../core/session/settings_controller.dart';
import '../../core/util/launcher.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';
import 'profile_screen.dart' show ProfileRow;

/// M19 — `GET /settings`, plus the route to `POST /auth/change-password`.
///
/// Every link on this screen is one the server owns: a center that moves its
/// support channel changes one row in `GET /settings`, not the app in the
/// stores. Signing out lives on the profile screen, where the design puts it.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final config = context.watch<SettingsController>().settings;

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              children: [
                ProfileRow(
                  icon: Icons.lock_outline_rounded,
                  label: s.changePassword,
                  onTap: () => context.push('/change-password'),
                ),
                ProfileRow(
                  icon: Icons.notifications_none_rounded,
                  label: s.notifications,
                  onTap: () => context.push('/notifications'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              children: [
                // A row whose link the settings payload did not carry is shown
                // without a tap target rather than hidden: the user learns the
                // channel exists even while the URL is being set up.
                ProfileRow(
                  icon: Icons.support_agent_rounded,
                  label: s.support,
                  onTap: config?.supportTelegram == null
                      ? null
                      : () => openExternal(context, config!.supportTelegram),
                ),
                ProfileRow(
                  icon: Icons.description_outlined,
                  label: s.offer,
                  onTap: config?.offerPdfUrl == null
                      ? null
                      : () => openExternal(context, config!.offerPdfUrl),
                ),
                ProfileRow(
                  icon: Icons.privacy_tip_outlined,
                  label: s.privacy,
                  onTap: config?.privacyPdfUrl == null
                      ? null
                      : () => openExternal(context, config!.privacyPdfUrl),
                ),
                ProfileRow(
                  icon: Icons.info_outline_rounded,
                  label: s.version,
                  value: config == null || config.latestVersion == AppConfig.appVersion
                      ? AppConfig.appVersion
                      : '${AppConfig.appVersion} → ${config.latestVersion}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
