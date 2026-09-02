import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/profile_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/primitives.dart';

/// M18 — `GET /notification` and `POST /notification/read`.
///
/// The feed is the source of truth, not the push: `07-INTEGRATIONS.md` §5 pairs
/// every push with a row here precisely because a push may have been dropped,
/// throttled or sent to a phone the user has since signed out of.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _view = GlobalKey<AsyncViewState<NotificationFeed>>();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final repo = context.read<ProfileRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(s.notifications)),
      body: AsyncView<NotificationFeed>(
        key: _view,
        load: () => repo.notifications(),
        builder: (context, feed, refresh) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (feed.unread > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GhostButton(
                    label: s.markAllRead,
                    dense: true,
                    onPressed: () => _markAll(context, refresh),
                  ),
                ),
              ),
            if (feed.items.isEmpty)
              EmptyView(message: s.noNotifications, icon: Icons.notifications_none_rounded)
            else
              for (final item in feed.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NotificationTile(
                    item: item,
                    onTap: () => _open(context, item),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAll(BuildContext context, Future<void> Function() refresh) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ProfileRepository>().markRead();
      await refresh();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Opening a row marks that row read and takes the user to whatever the
  /// notification is about — the ref the server put on it, never a guess.
  Future<void> _open(BuildContext context, AppNotification item) async {
    final session = context.read<SessionController>();
    final repo = context.read<ProfileRepository>();
    final target = _targetOf(item, teacher: session.isTeacher);

    if (!item.isRead) {
      try {
        await repo.markRead(ids: [item.id]);
        await _view.currentState?.refresh();
      } on ApiException {
        // A row that could not be marked read is still worth opening.
      }
    }
    if (target != null && context.mounted) context.push(target);
  }

  static String? _targetOf(AppNotification item, {required bool teacher}) {
    final ref = item.refId;
    if (ref == null) return null;
    return switch (item.type) {
      'test_assigned' || 'test_due_soon' when !teacher => '/student/test/$ref',
      'test_graded' || 'test_failed' when !teacher => '/student/test/$ref/result',
      'test_assigned' || 'test_graded' when teacher => '/teacher/test/$ref',
      _ => null,
    };
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  /// Title and body arrive already resolved from `_i18n` by `Accept-Language`;
  /// only the icon is the client's to choose.
  static (IconData, Color, Color) _look(String type) => switch (type) {
        'test_assigned' => (Icons.assignment_outlined, AppColors.blueTint, AppColors.blueDark),
        'test_graded' => (Icons.grading_rounded, AppColors.greenTint, AppColors.green),
        'test_due_soon' => (Icons.schedule_rounded, AppColors.sandTint, AppColors.sand),
        'test_failed' => (Icons.error_outline_rounded, AppColors.clayTint, AppColors.clay),
        'subscription_due' ||
        'invoice_issued' =>
          (Icons.receipt_long_outlined, AppColors.sandTint, AppColors.sand),
        'subscription_paid' ||
        'invoice_paid' =>
          (Icons.verified_outlined, AppColors.greenTint, AppColors.green),
        'center_suspended' => (Icons.lock_outline_rounded, AppColors.clayTint, AppColors.clay),
        'password_reset' => (Icons.key_outlined, AppColors.violetTint, AppColors.violet),
        _ => (Icons.campaign_outlined, AppColors.blueTint2, AppColors.blueLight1),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, background, foreground) = _look(item.type);

    return AppCard(
      radius: AppShapes.tileRadius,
      padding: const EdgeInsets.all(16),
      // Unread rows carry the tint; read ones fade back into the list.
      color: item.isRead ? AppColors.surface : AppColors.blueTint2,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlobAvatar(
            text: '',
            icon: icon,
            size: 40,
            background: background,
            foreground: foreground,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: const TextStyle(fontSize: 12, height: 1.45, color: AppColors.body),
                  ),
                ],
                if (item.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d MMM, HH:mm').format(item.createdAt!),
                    style: const TextStyle(fontSize: 10.5, color: AppColors.faint2),
                  ),
                ],
              ],
            ),
          ),
          if (!item.isRead)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
