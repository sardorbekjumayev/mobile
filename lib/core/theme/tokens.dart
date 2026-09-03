import 'package:flutter/material.dart';

/// Design tokens lifted verbatim from `Stepix Mobile.dc.html` (`:root`).
///
/// The palette is the app's neutral skin. A center's own `brand_primary` /
/// `brand_dark` arrive with the login response and override [AppColors.blue]
/// and [AppColors.blueDark] from that moment on — see [AppTheme.of].
class AppColors {
  const AppColors._();

  // Surfaces
  static const bg = Color(0xFFEAF1F7);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF6FAFD);
  static const tint = Color(0xFFEEF4FD);
  static const track = Color(0xFFEEF3F9);
  static const track2 = Color(0xFFE4ECF5);
  static const line = Color(0xFFE6EDF4);

  // Text
  static const ink = Color(0xFF12263C);
  static const body = Color(0xFF48607A);
  static const muted = Color(0xFF66809A);
  static const faint = Color(0xFF93A6B8);
  static const faint2 = Color(0xFFA9BACB);

  // Brand blue ramp
  static const blue = Color(0xFF1F63D6);
  static const blueDark = Color(0xFF1A4FAE);
  static const blueMid = Color(0xFF2F74E8);
  static const blueLight1 = Color(0xFF6F9BEA);
  static const blueLight2 = Color(0xFF9DBEF2);
  static const blueLight5 = Color(0xFFD6E4FB);
  static const blueTint = Color(0xFFE7EFFC);
  static const blueTint2 = Color(0xFFF0F6FE);

  // Accents
  static const green = Color(0xFF2F7D52);
  static const greenLight = Color(0xFF7DBD97);
  static const greenTint = Color(0xFFE6F4EC);
  static const sand = Color(0xFF8A6534);
  static const sandLight = Color(0xFFE8C48D);
  static const sandTint = Color(0xFFFDF3E4);
  static const clay = Color(0xFFA2503F);
  static const clayTint = Color(0xFFFDECEA);
  /// The border for a clay-tinted card — one step darker than its fill.
  static const clayLight = Color(0xFFF6D2CC);
  static const violet = Color(0xFF6B4FD8);
  static const violetDark = Color(0xFF4735A0);
  static const violetTint = Color(0xFFEFEAFD);
}

/// Radii, shadows and spacing the design repeats on every card.
class AppShapes {
  const AppShapes._();

  static const cardRadius = BorderRadius.all(Radius.circular(28));
  static const tileRadius = BorderRadius.all(Radius.circular(26));
  static const fieldRadius = BorderRadius.all(Radius.circular(24));
  static const chipRadius = BorderRadius.all(Radius.circular(999));
  static const pillRadius = BorderRadius.all(Radius.circular(999));

  /// The design's signature lopsided avatar: `border-radius:50% 50% 50% 15px`.
  static const blob = BorderRadius.only(
    topLeft: Radius.circular(999),
    topRight: Radius.circular(999),
    bottomRight: Radius.circular(999),
    bottomLeft: Radius.circular(15),
  );

  /// `border-radius:44% 56% 52% 48%` — the welcome/profile splash shape.
  ///
  /// CSS percentages are of the box, so the shape only reads as a blob at the
  /// size it is drawn. The old fixed 36–42px radii were roughly a quarter of the
  /// 150px hero and produced a rounded square instead: [splashOf] scales them.
  static BorderRadius splashOf(double size) => BorderRadius.only(
        topLeft: Radius.circular(size * 0.44),
        topRight: Radius.circular(size * 0.56),
        bottomRight: Radius.circular(size * 0.52),
        bottomLeft: Radius.circular(size * 0.48),
      );

  /// The 110px splash-screen mark, precomputed so it stays `const`-friendly.
  static final splash = splashOf(110);

  static const List<BoxShadow> shadow1 = [
    BoxShadow(color: Color(0x0D12263C), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadow2 = [
    BoxShadow(color: Color(0x0D12263C), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x2612263C), blurRadius: 30, offset: Offset(0, 14)),
  ];

  static List<BoxShadow> buttonShadow(Color c) => [
        BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10)),
      ];
}

/// Fonts: `Newsreader` for display, `Figtree` for everything else.
///
/// Both ship inside the app (`assets/fonts`, declared in `pubspec.yaml`). They
/// used to be named here and bundled nowhere, so every device silently fell
/// through to the fallbacks below and the app rendered in Georgia and Roboto —
/// the single biggest reason it did not look like the template. The fallbacks
/// remain for the frame or two before the asset is resolved.
class AppFonts {
  const AppFonts._();

  static const display = 'Newsreader';
  static const body = 'Figtree';
  static const displayFallback = ['Georgia', 'serif'];
  static const bodyFallback = ['Roboto', 'system-ui', 'sans-serif'];
}
