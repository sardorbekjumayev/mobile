import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session/settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/launcher.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';

/// The wall behind `force_update` from `GET /settings`.
///
/// There is no dismiss button on purpose: the flag means the API has stopped
/// answering this build's requests the way it expects, and a "later" here is a
/// support ticket tomorrow.
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  static const _androidStore =
      'https://play.google.com/store/apps/details?id=uz.stepix.app';
  static const _iosStore = 'https://apps.apple.com/app/stepix/id0000000000';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = context.watch<SettingsController>().settings;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(34, 0, 34, 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BlobAvatar(
                text: '',
                icon: Icons.system_update_rounded,
                size: 88,
                background: AppColors.blueTint,
                foreground: AppColors.blueDark,
              ),
              const SizedBox(height: 22),
              Text(
                s.updateRequired,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                s.updateRequiredBody,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.muted),
              ),
              if (settings != null) ...[
                const SizedBox(height: 14),
                Text(
                  '${s.version}: ${settings.latestVersion}',
                  style: const TextStyle(fontSize: 12, color: AppColors.faint),
                ),
              ],
              const SizedBox(height: 28),
              BrandButton(
                label: s.updateRequired,
                icon: Icons.open_in_new_rounded,
                onPressed: () => openExternal(
                  context,
                  Theme.of(context).platform == TargetPlatform.iOS ? _iosStore : _androidStore,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
