import 'package:flutter/material.dart';

import '../../domain/models/device_models.dart';

abstract final class PulseColors {
  static const background = Color(0xFF0B1020);
  static const surface = Color(0xFF171E33);
  static const line = Color(0xFF2C3554);
  static const text = Color(0xFFF4F6FB);
  static const muted = Color(0xFF9AA3C2);
  static const heart = Color(0xFFFF4D6A);
  static const heartDeep = Color(0xFF9F1239);
  static const mint = Color(0xFF3DDC97);
  static const amber = Color(0xFFFFC14D);
  static const blue = Color(0xFF8EB4FF);
}

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      surface: PulseColors.surface,
      primary: PulseColors.heart,
      onPrimary: Colors.white,
      secondary: PulseColors.mint,
      onSecondary: Color(0xFF062117),
      onSurface: PulseColors.text,
      error: PulseColors.heart,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: PulseColors.background,
      fontFamily: 'IBM Plex Sans',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'IBM Plex Sans',
        bodyColor: PulseColors.text,
        displayColor: PulseColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PulseColors.background,
        foregroundColor: PulseColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: PulseColors.heart,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return PulseColors.heart.withValues(alpha: 0.18);
            }
            return PulseColors.surface;
          }),
          foregroundColor: const WidgetStatePropertyAll(PulseColors.text),
          side: const WidgetStatePropertyAll(
            BorderSide(color: PulseColors.line),
          ),
        ),
      ),
    );
  }
}

Color zoneColor(HeartRateZone zone) {
  switch (zone) {
    case HeartRateZone.resting:
      return PulseColors.blue;
    case HeartRateZone.easy:
      return PulseColors.mint;
    case HeartRateZone.moderate:
      return PulseColors.amber;
    case HeartRateZone.hard:
      return PulseColors.heart;
    case HeartRateZone.peak:
      return PulseColors.heartDeep;
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PulseColors.line),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class AppFrame extends StatelessWidget {
  const AppFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: child,
      ),
    );
  }
}
