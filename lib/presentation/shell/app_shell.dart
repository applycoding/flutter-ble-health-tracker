import 'package:flutter/material.dart';

import '../history/history_page.dart';
import '../monitor/monitor_page.dart';
import '../theme/app_theme.dart';

enum _Section { monitor, log }

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _section = _Section.monitor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        return Scaffold(
          backgroundColor: PulseColors.ink,
          body: SafeArea(
            child: Row(
              children: [
                if (wide) _rail(),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: IndexedStack(
                          index: _section.index,
                          children: const [MonitorPage(), HistoryPage()],
                        ),
                      ),
                      const _Disclaimer(),
                      if (!wide) _bar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rail() {
    return NavigationRail(
      selectedIndex: _section.index,
      onDestinationSelected: _select,
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.monitor_heart_outlined),
          label: Text('Monitor'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.menu_book_outlined),
          label: Text('Log'),
        ),
      ],
    );
  }

  Widget _bar() {
    return NavigationBar(
      selectedIndex: _section.index,
      onDestinationSelected: _select,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), label: 'Monitor'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Log'),
      ],
    );
  }

  void _select(int index) {
    setState(() => _section = _Section.values[index]);
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        'Portfolio demo. Not a medical device.',
        key: Key('medical-disclaimer'),
        textAlign: TextAlign.center,
        style: TextStyle(color: PulseColors.paperMuted, fontSize: 12),
      ),
    );
  }
}
