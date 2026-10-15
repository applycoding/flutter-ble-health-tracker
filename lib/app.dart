import 'package:flutter/material.dart';

import 'presentation/shell/app_shell.dart';
import 'presentation/theme/app_theme.dart';

class PulseLedgerApp extends StatelessWidget {
  const PulseLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = buildPulseTheme();
    return MaterialApp(
      title: 'Pulse Ledger',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      home: const AppShell(),
    );
  }
}
