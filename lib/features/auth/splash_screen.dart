import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Shown while [SessionController.restore] asks `/auth/me` who the stored
/// tokens belong to.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 110,
          height: 110,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: context.brand.gradient,
            borderRadius: AppShapes.splash,
          ),
          child: const Icon(Icons.bolt_rounded, size: 48, color: Colors.white),
        ),
      ),
    );
  }
}
