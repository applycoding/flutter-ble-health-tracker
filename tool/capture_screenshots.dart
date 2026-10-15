import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsekeep/data/simulator/simulated_heart_rate_gateway.dart';
import 'package:pulsekeep/domain/models/heart_rate_measurement.dart';
import 'package:pulsekeep/domain/models/heart_rate_reading.dart';
import 'package:pulsekeep/domain/repositories/heart_rate_repository.dart';
import 'package:pulsekeep/presentation/app.dart';
import 'package:pulsekeep/presentation/providers.dart';

import '../test/support/fakes.dart';
import '../test/support/memory_reading_store.dart';

void main() {
  testWidgets('capture README screenshots', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gateway = SimulatedHeartRateGateway(
      random: Random(7),
      replayCount: 28,
    );
    final store = MemoryReadingStore();
    final repository = HeartRateRepository(
      local: store,
      remote: FakeHeartRateRemote(configured: false),
      network: FakeNetworkStatus(),
      ids: SequentialIds(),
      clock: MutableClock(DateTime.now().toUtc()),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heartRateRepositoryProvider.overrideWithValue(repository),
          simulatedGatewayProvider.overrideWithValue(gateway),
        ],
        child: const PulseKeepApp(),
      ),
    );
    await tester.pump();
    await _save('scan');

    await tester.tap(find.byKey(const Key('connect-sim-pulsekeep')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _save('monitor');

    await tester.tap(find.byTooltip('Disconnect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final now = DateTime.now();
    const samples = [64, 71, 76, 82, 88];
    for (var i = 0; i < samples.length; i++) {
      await store.insert(
        HeartRateReading(
          id: 'shot-$i',
          bpm: samples[i],
          recordedAt: now.subtract(Duration(seconds: (samples.length - i) * 12)),
          sourceId: SimulatedHeartRateGateway.device.id,
          sourceName: SimulatedHeartRateGateway.device.name,
          synced: false,
          sensorContact: SensorContact.detected,
          rrIntervalsMs: const [820],
        ),
      );
    }

    expect(find.byKey(const Key('history-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Sync now'), findsOneWidget);
    await _save('history');

    await tester.pumpWidget(const SizedBox.shrink());
    await gateway.dispose();
    await store.close();
  });
}

Future<void> _save(String name) {
  return expectLater(
    find.byKey(const Key('screenshot-root')),
    matchesGoldenFile('../docs/screenshots/$name.png'),
  );
}
