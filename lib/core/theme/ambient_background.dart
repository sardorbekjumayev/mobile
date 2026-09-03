import 'package:flutter/material.dart';

import 'tokens.dart';

/// The template's background, behind every screen in the app.
///
/// `Stepix Mobile.dc.html` paints three things under its phone frame: a flat
/// `--bg`, two large radial washes in opposite corners, and two soft coloured
/// blobs. The app had only the flat colour, which is why side-by-side it read
/// as the same palette but not the same design — the washes are most of what
/// makes the surface look lit rather than printed.
///
/// **Static, where the template drifts.** The original animates both blobs on a
/// 13- and 17-second loop. An animation that never ends keeps the Flutter
/// scheduler awake for as long as the app is open — it costs battery on a
/// phone that spends most of its time showing a list, and it makes
/// `pumpAndSettle` in every widget test wait forever. At this scale and blur
/// the movement is close to invisible anyway; the colour is the part that
/// carries.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  /// `radial-gradient(900px 520px at 18% 4%, #dfeaf8, transparent 70%)`.
  static const _washTopLeft = Color(0xFFDFEAF8);

  /// `radial-gradient(760px 480px at 88% 96%, #e5efe8, transparent 72%)`.
  static const _washBottomRight = Color(0xFFE5EFE8);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.bg)),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.64, -0.92),
                radius: 1.15,
                colors: [_washTopLeft, Color(0x00DFEAF8)],
                stops: [0, 0.7],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.76, 0.92),
                radius: 1.0,
                colors: [_washBottomRight, Color(0x00E5EFE8)],
                stops: [0, 0.72],
              ),
            ),
          ),
        ),
        // The two blobs. Drawn as radial gradients rather than blurred boxes:
        // a `BackdropFilter` behind every screen is a full-screen blur on every
        // frame, and the soft stop is indistinguishable from it here.
        const _Blob(
          top: -110,
          right: -90,
          size: 300,
          color: AppColors.blueTint,
        ),
        const _Blob(
          bottom: -80,
          left: -80,
          size: 260,
          color: Color(0xFFE6F1EA),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.size,
    required this.color,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final double size;
  final Color color;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
              stops: const [0.35, 1],
            ),
          ),
        ),
      ),
    );
  }
}
