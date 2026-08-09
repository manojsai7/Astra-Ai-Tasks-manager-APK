/// ASTRA — Material 3 Application Theme
///
/// Design direction: calm productivity, premium, minimal, professional.
/// Android-first, adaptive light and dark modes.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Indigo A400 seed colour for deep slate-blue/indigo M3 color schemes.
const Color _kSeedColor = Color(0xFF3D5AFE);

/// Returns the ASTRA [ThemeData] for the given [brightness].
ThemeData astraTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _kSeedColor,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,

    // System UI overlays for immersive Android status and navigation bar styling
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: scheme.surface,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: scheme.surface,
            ),
    ),

    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: const FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
