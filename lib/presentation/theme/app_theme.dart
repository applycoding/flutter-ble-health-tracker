import 'package:flutter/material.dart';

import '../../domain/models.dart';

abstract final class PulseColors {
  static const ink = Color(0xFF14110E);
  static const inkRaised = Color(0xFF211C18);
  static const line = Color(0xFF3C342C);
  static const paper = Color(0xFFF3EEE6);
  static const paperMuted = Color(0xFFB7AA9C);
  static const signal = Color(0xFFE24A3B);
  static const moss = Color(0xFF8EAE78);
  static const amber = Color(0xFFE2A15A);
}

ThemeData buildPulseTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: PulseColors.signal,
    brightness: Brightness.dark,
  ).copyWith(
    surface: PulseColors.ink,
    primary: PulseColors.signal,
    onPrimary: const Color(0xFF2B0E0B),
    secondary: PulseColors.amber,
    onSecondary: const Color(0xFF2A1C0C),
    onSurface: PulseColors.paper,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: PulseColors.ink,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Figtree',
      bodyColor: PulseColors.paper,
      displayColor: PulseColors.paper,
    ),
    cardTheme: const CardThemeData(
      color: PulseColors.inkRaised,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
        side: BorderSide(color: PulseColors.line),
      ),
    ),
    dividerColor: PulseColors.line,
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: PulseColors.inkRaised,
      indicatorColor: Color(0x33E24A3B),
      selectedIconTheme: IconThemeData(color: PulseColors.paper),
      unselectedIconTheme: IconThemeData(color: PulseColors.paperMuted),
      selectedLabelTextStyle: TextStyle(color: PulseColors.paper, fontSize: 12),
      unselectedLabelTextStyle: TextStyle(color: PulseColors.paperMuted, fontSize: 12),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: PulseColors.inkRaised,
      indicatorColor: Color(0x33E24A3B),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return PulseColors.ink;
        return PulseColors.paperMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return PulseColors.moss;
        return PulseColors.line;
      }),
    ),
  );
}

Color phaseColor(WearablePhase phase) => switch (phase) {
      WearablePhase.streaming => PulseColors.moss,
      WearablePhase.scanning || WearablePhase.connecting => PulseColors.amber,
      WearablePhase.error => PulseColors.signal,
      WearablePhase.idle || WearablePhase.stopped => PulseColors.paperMuted,
    };

Color outcomeColor(SyncOutcome? outcome) => switch (outcome) {
      SyncOutcome.synced || SyncOutcome.upToDate => PulseColors.moss,
      SyncOutcome.offline || SyncOutcome.notConfigured => PulseColors.amber,
      SyncOutcome.failed => PulseColors.signal,
      null => PulseColors.paperMuted,
    };
