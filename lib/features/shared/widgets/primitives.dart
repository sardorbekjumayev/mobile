import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';

/// The white rounded panel every screen is built out of.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppShapes.cardRadius,
    this.color = AppColors.surface,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        boxShadow: AppShapes.shadow1,
      ),
      child: child,
    );
    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: body,
    );
  }
}

/// The design's gradient pill — primary action on every screen.
class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final enabled = onPressed != null && !busy;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: AppShapes.pillRadius,
          child: Ink(
            decoration: BoxDecoration(
              gradient: brand.gradient,
              borderRadius: AppShapes.pillRadius,
              boxShadow: enabled ? AppShapes.buttonShadow(brand.primary) : null,
            ),
            child: Container(
              width: expand ? double.infinity : null,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 9),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary action — "Ученики", "Ок", the attention-row buttons.
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, this.onPressed, this.dense = false});

  final String label;
  final VoidCallback? onPressed;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppShapes.pillRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppShapes.pillRadius,
        child: Container(
          padding: dense
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: AppShapes.pillRadius,
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: dense ? 11.5 : 12,
              fontWeight: FontWeight.w600,
              color: AppColors.body,
            ),
          ),
        ),
      ),
    );
  }
}

/// `border-radius:50% 50% 50% 15px` — the avatar shape used all over the app.
class BlobAvatar extends StatelessWidget {
  const BlobAvatar({
    super.key,
    required this.text,
    this.size = 44,
    this.background = AppColors.blueTint,
    this.foreground = AppColors.blueDark,
    this.gradient,
    this.icon,
  });

  final String text;
  final double size;
  final Color background;
  final Color foreground;
  final Gradient? gradient;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: gradient == null ? background : null,
        gradient: gradient,
        borderRadius: AppShapes.blob,
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.44, color: foreground)
          : Text(
              text,
              style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
    );
  }
}

/// Small rounded label: streak, role, state.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.background = AppColors.blueTint,
    this.foreground = AppColors.blueDark,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: AppShapes.chipRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: foreground),
          ),
        ],
      ),
    );
  }
}

/// The circular "средний балл" gauge on the student home screen.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 96, this.color});

  final int score;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ring = color ?? context.brand.primary;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.track,
              valueColor: AlwaysStoppedAnimation(ring),
            ),
          ),
          Text(
            '$score',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: size * 0.22),
          ),
        ],
      ),
    );
  }
}

/// Full-screen states: spinner, failure with retry, and "nothing here yet".
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry, this.retryLabel});

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BlobAvatar(
              text: '',
              icon: Icons.cloud_off_rounded,
              size: 56,
              background: AppColors.clayTint,
              foreground: AppColors.clay,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.body),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              GhostButton(label: retryLabel ?? 'Retry', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      radius: AppShapes.tileRadius,
      child: Column(
        children: [
          if (icon != null) ...[
            BlobAvatar(
              text: '',
              icon: icon,
              size: 48,
              background: AppColors.blueTint2,
              foreground: AppColors.blueLight1,
            ),
            const SizedBox(height: 14),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, height: 1.55, color: AppColors.faint),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
