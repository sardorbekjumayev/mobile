import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../../core/session/settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/profile_models.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';

/// M1 — the last neutral surface in the app. Everything after sign-in is
/// painted in the center's own brand.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // `GET /settings` is public and already fetched at boot, so the counts are
    // usually there by the time this screen paints. When they are not, the row
    // is simply absent — it never occupies space with placeholders.
    final stats = context.watch<SettingsController>().settings?.stats;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 34),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _HeroMark(),
                    const SizedBox(height: 24),
                    Text(
                      s.welcomeTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Text(
                        s.welcomeBody,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.muted),
                      ),
                    ),
                    if (stats != null && !stats.isEmpty) ...[
                      const SizedBox(height: 24),
                      _StatsRow(stats: stats),
                    ],
                  ],
                ),
              ),
              BrandButton(
                label: s.welcomeCta,
                onPressed: () => context.go('/login/phone'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Stepix mark — its own yellow dot is what stops it reading as a plain
/// rounded square, so unlike the template this hero was traced from, there is
/// no separate satellite blob layered on top of it.
class _HeroMark extends StatelessWidget {
  const _HeroMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: AppShapes.splashOf(150),
        boxShadow: AppShapes.buttonShadow(AppColors.blue),
      ),
      child: SvgPicture.asset('assets/images/stepix-mark.svg'),
    );
  }
}

/// Students · tests · centers, platform-wide and counted rather than claimed.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final PlatformStats stats;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      key: const Key('welcome-stats'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Stat(value: stats.students, label: s.statStudents),
        const SizedBox(width: 20),
        _Stat(value: stats.tests, label: s.statTests),
        const SizedBox(width: 20),
        _Stat(value: stats.centers, label: s.statCenters),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          compactCount(value),
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontFamilyFallback: AppFonts.displayFallback,
            fontSize: 23,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.faint)),
      ],
    );
  }
}

/// `1240` → `1.2k`. Three columns of a centred row have room for four glyphs;
/// a platform with six-figure numbers would otherwise push them into each other.
String compactCount(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final k = n / 1000;
    return k >= 10 ? '${k.round()}k' : '${k.toStringAsFixed(1)}k';
  }
  final m = n / 1000000;
  return m >= 10 ? '${m.round()}M' : '${m.toStringAsFixed(1)}M';
}
