import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/session/session_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/strings.dart';
import 'primitives.dart';

/// The greeting row at the top of both home screens: avatar, name, and one
/// role-specific trailing element.
class UserHeader extends StatelessWidget {
  const UserHeader({super.key, this.greetingKey, this.trailing});

  /// `morning` · `day` · `evening`, straight from `GET /home`. Computing it on
  /// the device would use the phone's clock, which is not the center's.
  final String? greetingKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final session = context.watch<SessionController>();
    final user = session.user;
    final teacher = session.isTeacher;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 18),
      child: Row(
        children: [
          BlobAvatar(
            text: user?.initials ?? '',
            background: teacher ? AppColors.violetTint : AppColors.blueTint,
            foreground: teacher ? AppColors.violet : AppColors.blueDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.greeting(greetingKey ?? 'morning'),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
                ),
                Text(
                  user?.firstName ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[trailing!, const SizedBox(width: 10)],
          Material(
            color: AppColors.surface,
            shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
            child: InkWell(
              onTap: () => context.push('/notifications'),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.notifications_none_rounded, size: 18, color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
