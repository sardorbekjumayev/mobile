// `Badge` here is the model in `rank_models.dart` — Material's own
// `Badge` widget (the dot on an icon) is not used anywhere in the app.
import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/launcher.dart';
import '../../data/models/profile_models.dart';
import '../../data/models/rank_models.dart';
import '../../data/models/session_models.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/analytics_cards.dart';
import '../shared/widgets/async_view.dart';
import '../shared/widgets/badges_card.dart';
import '../shared/widgets/primitives.dart';
import 'account_actions.dart';

/// M11 — `GET /profile`, plus `GET /progress` and `GET /badge` for a student.
///
/// A teacher gets the identity half only: progress and badges are student
/// endpoints and answer `403` for anyone else, so asking for them here would
/// turn a teacher's own profile into an error screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final profiles = context.read<ProfileRepository>();
    final students = context.read<StudentRepository>();
    final teacher = session.isTeacher;

    return AsyncView<_ProfileBundle>(
      load: () async {
        final profile = await profiles.profile();
        // Progress and badges are student endpoints and answer `403` for anyone
        // else, so a teacher's own profile stops at the identity half.
        if (teacher) return _ProfileBundle(profile);
        return _ProfileBundle(
          profile,
          progress: await students.progress(),
          badges: await students.badges(),
          subscription: await _subscriptionOrNull(profiles),
        );
      },
      builder: (context, bundle, refresh) => _ProfileBody(bundle: bundle, onChanged: refresh),
    );
  }

  /// Model A centers have no subscription row and the endpoint is not part of
  /// their deployment. A student there sees the rest of the profile rather than
  /// a failure caused by a section they should never have seen.
  static Future<Subscription?> _subscriptionOrNull(ProfileRepository profiles) async {
    try {
      return await profiles.subscription();
    } on ApiException {
      return null;
    }
  }
}

class _ProfileBundle {
  const _ProfileBundle(this.profile, {this.progress, this.badges, this.subscription});

  final UserProfile profile;
  final StudentProgress? progress;
  final List<Badge>? badges;
  final Subscription? subscription;
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.bundle, required this.onChanged});

  final _ProfileBundle bundle;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final session = context.watch<SessionController>();
    final profile = bundle.profile;
    final teacher = session.isTeacher;
    final progress = bundle.progress;
    final badges = bundle.badges;
    final subscription = bundle.subscription;
    final skills = progress == null ? null : SkillsCard.fromSkills(progress.skills);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(s.profile, style: Theme.of(context).textTheme.displaySmall),
            ),
            Material(
              color: AppColors.surface,
              shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
              child: InkWell(
                onTap: () => context.push('/settings'),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.settings_outlined, size: 18, color: AppColors.muted),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _IdentityCard(
          profile: profile,
          teacher: teacher,
          onRename: () => _rename(context, profile.user),
        ),
        if (subscription != null && subscription.required_) ...[
          const SizedBox(height: 12),
          _SubscriptionCard(subscription: subscription),
        ],
        if (progress != null && progress.trend.isNotEmpty) ...[
          const SizedBox(height: 12),
          TrendCard(trend: progress.trend, color: context.brand.primary),
        ],
        if (skills != null && !skills.isEmpty) ...[
          const SizedBox(height: 12),
          skills,
        ],
        if (badges != null && badges.isNotEmpty) ...[
          const SizedBox(height: 12),
          BadgesCard(badges: badges),
        ],
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            children: [
              ProfileRow(
                icon: Icons.notifications_none_rounded,
                label: s.notifications,
                onTap: () => context.push('/notifications'),
              ),
              ProfileRow(
                icon: Icons.translate_rounded,
                label: s.language,
                value: languageName(session.user?.language ?? s.lang),
                onTap: () => pickLanguage(context),
              ),
              ProfileRow(
                icon: Icons.settings_outlined,
                label: s.settings,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _LogoutButton(),
      ],
    );
  }

  /// The one editable field on this screen. Phone, role and group membership
  /// belong to the center — letting a student change the number they log in
  /// with is an account-transfer feature nobody asked for.
  Future<void> _rename(BuildContext context, AppUser user) async {
    final s = S.of(context);
    final controller = TextEditingController(text: user.fullName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppShapes.tileRadius),
        title: Text(s.fullName, style: Theme.of(context).textTheme.titleMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface2,
            border: const OutlineInputBorder(
              borderRadius: AppShapes.fieldRadius,
              borderSide: BorderSide.none,
            ),
            hintText: s.fullName,
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(s.cancel)),
          TextButton(
            onPressed: () => context.pop(controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty || name == user.fullName) return;
    if (!context.mounted) return;

    final session = context.read<SessionController>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await context.read<ProfileRepository>().update(fullName: name);
      session.updateUser(updated.user);
      await onChanged();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile, required this.teacher, required this.onRename});

  final UserProfile profile;
  final bool teacher;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final brand = context.brand;
    final user = profile.user;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      radius: const BorderRadius.all(Radius.circular(30)),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // The teacher app is violet throughout; only a student's screens
              // wear the center's own brand colour.
              gradient: teacher
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.violet, AppColors.violetDark],
                    )
                  : brand.gradient,
              borderRadius: AppShapes.splash,
              boxShadow: AppShapes.buttonShadow(teacher ? AppColors.violet : brand.primary),
            ),
            child: Text(
              user.initials,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRename,
                tooltip: s.edit,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 17, color: AppColors.faint),
              ),
            ],
          ),
          Text(
            [
              teacher ? s.teacherRole : s.student,
              if (profile.centerName != null) profile.centerName!,
              user.phone,
            ].join(' · '),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.muted),
          ),
          // A teacher's numbers live on their home screen's KPI row; repeating
          // them here would be the only place the two could disagree.
          if (!teacher) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _Stat(value: '${profile.testsTaken}', label: s.testsTaken)),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    value: profile.avgScore == null ? '—' : '${profile.avgScore}',
                    label: s.avgScore,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _Stat(value: '${profile.streakDays}', label: s.streak)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.faint),
          ),
        ],
      ),
    );
  }
}

/// The design's one destructive action, in the one place it belongs.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Material(
      color: AppColors.clayTint,
      borderRadius: AppShapes.pillRadius,
      child: InkWell(
        borderRadius: AppShapes.pillRadius,
        onTap: () => confirmSignOut(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          child: Text(
            s.logout,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.clay,
            ),
          ),
        ),
      ),
    );
  }
}

/// Model B only, and a banner rather than a wall: a `past_due` subscription
/// blocks nothing for seven days. Locking a teenager out of their homework the
/// hour a card expires is how a payment problem becomes a support problem.
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final overdue = !subscription.isActive;

    return AppCard(
      color: overdue ? AppColors.sandTint : AppColors.surface,
      child: Row(
        children: [
          BlobAvatar(
            text: '',
            icon: overdue ? Icons.schedule_rounded : Icons.verified_outlined,
            size: 44,
            background: overdue ? AppColors.surface : AppColors.greenTint,
            foreground: overdue ? AppColors.sand : AppColors.green,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.planName ?? s.subscription,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subscription.inGrace
                      ? s.subscriptionGrace
                      : [
                          if (subscription.price != null) '${subscription.price} so\'m',
                          if (subscription.expiresAt != null)
                            '${subscription.expiresAt!.day}.${subscription.expiresAt!.month}.${subscription.expiresAt!.year}',
                        ].join(' · '),
                  style: const TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (overdue) ...[
            const SizedBox(width: 10),
            GhostButton(
              label: s.pay,
              dense: true,
              onPressed: () => _checkout(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _checkout(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final session = await context.read<ProfileRepository>().checkout('payme');
      if (!context.mounted) return;
      await openExternal(context, session.paymentUrl);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

/// A tappable settings/profile row. Shared with the settings screen so the two
/// lists cannot drift apart.
class ProfileRow extends StatelessWidget {
  const ProfileRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.clay : AppColors.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: AppShapes.tileRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 19, color: danger ? AppColors.clay : AppColors.muted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: color),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: const TextStyle(fontSize: 12.5, color: AppColors.faint),
              ),
            if (onTap != null && !danger) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.faint2),
            ],
          ],
        ),
      ),
    );
  }
}
