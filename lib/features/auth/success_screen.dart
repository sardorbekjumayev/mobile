import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/session/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';

/// M3b — the first screen painted in the center's brand.
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final session = context.watch<SessionController>();
    final brand = context.brand;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(34, 0, 34, 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: brand.gradient,
                  borderRadius: AppShapes.splashOf(120),
                  boxShadow: AppShapes.buttonShadow(brand.primary),
                ),
                child: const Icon(Icons.check_rounded, size: 52, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                s.successTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 9),
              Text(
                session.center?.name ?? s.successBody,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              BrandButton(
                label: s.openStepix,
                onPressed: () => context.go(session.isTeacher ? '/teacher/home' : '/student/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
