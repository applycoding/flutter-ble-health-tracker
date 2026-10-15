import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ledger/app.dart';
import 'package:pulse_ledger/application/monitor_state.dart';
import 'package:pulse_ledger/presentation/history/history_page.dart';
import 'package:pulse_ledger/presentation/monitor/monitor_page.dart';
import 'package:pulse_ledger/presentation/theme/app_theme.dart';

import 'support/app_harness.dart';
import 'support/samples.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offline beats queue locally and sync when the link returns', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final harness = AppHarness(online: false);
    addTearDown(harness.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: harness.container,
        child: const PulseLedgerApp(),
      ),
    );
    await tester.pumpAndSettle();

    harness.wearable.emit(sample(bpm: 72));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('medical-disclaimer')), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('bpm-value'))).data, '72');
    expect(find.textContaining('Offline'), findsWidgets);
    expect(harness.sync.uploaded, isEmpty);

    await tester.ensureVisible(find.byKey(const Key('online-switch')));
    await tester.tap(find.byKey(const Key('online-switch')));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(harness.sync.uploaded, hasLength(1));

    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    expect(find.text('Stored on this device'), findsOneWidget);
    expect(find.textContaining('Synced'), findsOneWidget);
  });

  testWidgets('a narrow window uses the bottom bar and live scan stays empty without a radio', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final harness = AppHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: harness.container,
        child: const PulseLedgerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.tap(find.text('Live BLE'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('scan-empty')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No monitors advertising 0x180D yet.'), findsOneWidget);
  });

  testWidgets('history shows a queued beat under today', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPulseTheme(),
        home: Scaffold(
          body: HistoryBody(
            now: DateTime(2026, 10, 15, 15),
            readings: [
              reading(id: 3, bpm: 64, recordedAt: DateTime(2026, 10, 15, 15, 4, 5)),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('15:04:05'), findsOneWidget);
    expect(find.text('PulseBand Demo · Demo · Queued'), findsOneWidget);
    expect(find.text('64'), findsOneWidget);
    expect(find.byKey(const Key('history-empty')), findsNothing);
  });

  testWidgets('the monitor explains an empty trace', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPulseTheme(),
        home: Scaffold(
          body: MonitorBody(
            state: MonitorState.initial(
              demoMode: true,
              online: true,
              syncTarget: 'mock cloud',
              firebaseConfigured: false,
            ),
            onDemoMode: (_) {},
            onOnline: (_) {},
            onSync: () async {},
            onStreaming: (_) {},
            onScan: () async {},
            onConnect: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('—'), findsWidgets);
    expect(find.text('The trace starts with the next beat.'), findsOneWidget);
    expect(find.text('mock cloud'), findsOneWidget);
  });
}
