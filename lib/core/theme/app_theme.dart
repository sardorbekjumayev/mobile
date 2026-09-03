import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the app's [ThemeData] around a center's brand colour.
///
/// The login response carries `brand_primary` / `brand_dark`; until it lands
/// the app wears the neutral Stepix blue. The login screen is deliberately the
/// last neutral surface — everything after it is painted by the center.
class AppTheme {
  const AppTheme._();

  static ThemeData of({Color? primary, Color? primaryDark}) {
    final blue = primary ?? AppColors.blue;
    final blueDark = primaryDark ?? AppColors.blueDark;

    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.light,
    ).copyWith(
      primary: blue,
      onPrimary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.clay,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Transparent so [AmbientBackground], mounted once in `MaterialApp.builder`,
      // shows through every screen including pushed detail routes. Painting the
      // background per screen instead means forty chances for one of them to be
      // the flat colour.
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: AppFonts.body,
      fontFamilyFallback: AppFonts.bodyFallback,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.body),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      textTheme: _textTheme,
      dividerTheme: const DividerThemeData(color: AppColors.track, thickness: 1, space: 1),
      extensions: <ThemeExtension<dynamic>>[BrandColors(primary: blue, dark: blueDark)],
    );
  }

  static const _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: AppFonts.display,
      fontFamilyFallback: AppFonts.displayFallback,
      fontSize: 38,
      height: 1.05,
      letterSpacing: -1.1,
      fontWeight: FontWeight.w400,
      color: AppColors.ink,
    ),
    displayMedium: TextStyle(
      fontFamily: AppFonts.display,
      fontFamilyFallback: AppFonts.displayFallback,
      fontSize: 31,
      height: 1.1,
      letterSpacing: -0.8,
      fontWeight: FontWeight.w400,
      color: AppColors.ink,
    ),
    displaySmall: TextStyle(
      fontFamily: AppFonts.display,
      fontFamilyFallback: AppFonts.displayFallback,
      fontSize: 28,
      letterSpacing: -0.7,
      fontWeight: FontWeight.w400,
      color: AppColors.ink,
    ),
    headlineMedium: TextStyle(
      fontFamily: AppFonts.display,
      fontFamilyFallback: AppFonts.displayFallback,
      fontSize: 24,
      letterSpacing: -0.5,
      fontWeight: FontWeight.w500,
      color: AppColors.ink,
    ),
    titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
    titleSmall: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink),
    bodyLarge: TextStyle(fontSize: 14, height: 1.6, color: AppColors.body),
    bodyMedium: TextStyle(fontSize: 13, height: 1.5, color: AppColors.body),
    bodySmall: TextStyle(fontSize: 11.5, color: AppColors.faint),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 10.5, color: AppColors.faint),
  );
}

/// The center's brand pair, reachable from any widget via `Theme.of`.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({required this.primary, required this.dark});

  final Color primary;
  final Color dark;

  /// The gradient the design uses on every primary button and hero card:
  /// `linear-gradient(150deg, var(--blue-m), var(--blue-d))`.
  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, dark],
      );

  @override
  BrandColors copyWith({Color? primary, Color? dark}) =>
      BrandColors(primary: primary ?? this.primary, dark: dark ?? this.dark);

  @override
  BrandColors lerp(covariant BrandColors? other, double t) {
    if (other == null) return this;
    return BrandColors(
      primary: Color.lerp(primary, other.primary, t)!,
      dark: Color.lerp(dark, other.dark, t)!,
    );
  }
}

extension BrandContext on BuildContext {
  BrandColors get brand =>
      Theme.of(this).extension<BrandColors>() ??
      const BrandColors(primary: AppColors.blue, dark: AppColors.blueDark);
}
