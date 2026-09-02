import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';

/// M1 — the last neutral surface in the app. Everything after sign-in is
/// painted in the center's own brand.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final brand = context.brand;

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
                    Container(
                      width: 150,
                      height: 150,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: brand.gradient,
                        borderRadius: AppShapes.splash,
                        boxShadow: AppShapes.buttonShadow(brand.primary),
                      ),
                      child: const Icon(Icons.bolt_rounded, size: 62, color: Colors.white),
                    ),
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
