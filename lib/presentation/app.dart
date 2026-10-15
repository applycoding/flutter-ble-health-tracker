import 'package:flutter/material.dart';

import 'history/history_page.dart';
import 'monitor/monitor_page.dart';
import 'scan/scan_page.dart';
import 'theme/pulse_theme.dart';

class PulseKeepApp extends StatelessWidget {
  const PulseKeepApp({super.key});

  static const monitorRoute = '/monitor';
  static const historyRoute = '/history';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseKeep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      builder: (context, child) {
        return RepaintBoundary(
          key: const Key('screenshot-root'),
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (_) => const ScanPage(),
        monitorRoute: (_) => const MonitorPage(),
        historyRoute: (_) => const HistoryPage(),
      },
    );
  }
}
