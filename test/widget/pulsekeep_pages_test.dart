import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsekeep/data/simulator/simulated_heart_rate_gateway.dart';
import 'package:pulsekeep/domain/failures/app_failure.dart';
import 'package:pulsekeep/domain/models/device_models.dart';
import 'package:pulsekeep/domain/models/heart_rate_measurement.dart';
import 'package:pulsekeep/domain/ports.dart';
import 'package:pulsekeep/domain/repositories/heart_rate_repository.dart';
import 'package:pulsekeep/presentation/app.dart';
import 'package:pulsekeep/presentation/providers.dart';

import '../support/fakes.dart';
import '../support/memory_reading_store.dart';

void main() {
  testWidgets('connects the simulator and shows a live BPM', (tester) async {
    final gateway = SimulatedHeartRateGateway(
      random: Random(1),
      interval: const Duration(milliseconds: 20),
      replayCount: 8,
    );
    final bundle = _bundle();
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        bundle,
        extra: [simulatedGatewayProvider.overrideWithValue(gateway)],
      ),
    );
    await tester.pump();

    expect(find.text('Portfolio demo'), findsOneWidget);
    expect(find.textContaining('Not a medical device'), findsOneWidget);
    expect(find.text('PulseKeep Simulator'), findsOneWidget);

    await tester.tap(find.byKey(const Key('connect-sim-pulsekeep')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('bpm-value')), findsOneWidget);
    expect(find.text('Resting'), findsOneWidget);
    expect(find.text('On-device only'), findsOneWidget);

    await tester.tap(find.text('Run'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('Hard'), findsOneWidget);

    final saved = await bundle.store.recent();
    expect(saved, isNotEmpty);
    expect(saved.every((reading) => reading.synced), isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await gateway.dispose();
  });

  testWidgets('shows a bluetooth failure without a radio', (tester) async {
    final central = _OffRadioGateway();
    final bundle = _bundle();
    await tester.pumpWidget(
      _app(
        bundle,
        extra: [bluetoothGatewayProvider.overrideWithValue(central)],
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Bluetooth'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Bluetooth is off'), findsOneWidget);
    await tester.tap(find.byKey(const Key('scan-button')));
    await tester.pump();
    expect(find.byKey(const Key('scan-error')), findsOneWidget);
    expect(find.textContaining('Bluetooth is off'), findsWidgets);
  });

  testWidgets('history lists stored readings and explains the empty case', (
    tester,
  ) async {
    final bundle = _bundle();
    await tester.pumpWidget(_app(bundle));
    await tester.pump();
    await tester.tap(find.byKey(const Key('history-button')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('history-empty')), findsOneWidget);
    expect(find.textContaining('Firebase is not configured'), findsOneWidget);

    await bundle.repository.record(
      measurement: const HeartRateMeasurement(
        bpm: 77,
        sensorContact: SensorContact.detected,
      ),
      device: SimulatedHeartRateGateway.device,
    );
    await tester.pump();

    expect(find.text('77'), findsWidgets);
    expect(find.text('On device'), findsOneWidget);
    expect(find.byKey(const Key('history-empty')), findsNothing);

    await tester.tap(find.byKey(const Key('sync-button')));
    await tester.pump();
    expect(find.textContaining('Firebase is not configured'), findsWidgets);
  });
}

class _Bundle {
  _Bundle({
    required this.store,
    required this.repository,
    required this.remote,
  });

  final MemoryReadingStore store;
  final HeartRateRepository repository;
  final FakeHeartRateRemote remote;
}

_Bundle _bundle() {
  final store = MemoryReadingStore();
  final remote = FakeHeartRateRemote(configured: false);
  final repository = HeartRateRepository(
    local: store,
    remote: remote,
    network: FakeNetworkStatus(),
    ids: SequentialIds(),
    clock: MutableClock(DateTime.now().toUtc()),
  );
  return _Bundle(store: store, repository: repository, remote: remote);
}

Widget _app(_Bundle bundle, {List<Override> extra = const []}) {
  return ProviderScope(
    overrides: [
      heartRateRepositoryProvider.overrideWithValue(bundle.repository),
      ...extra,
    ],
    child: const PulseKeepApp(),
  );
}

final class _OffRadioGateway implements HeartRateGateway {
  @override
  bool get canChangeActivity => false;

  @override
  Stream<RadioStatus> watchRadio() async* {
    yield RadioStatus.off;
  }

  @override
  Stream<List<HeartRateDevice>> watchDevices() async* {
    yield const [];
  }

  @override
  Stream<LinkStatus> watchLink() => const Stream.empty();

  @override
  Stream<HeartRateMeasurement> watchMeasurements() => const Stream.empty();

  @override
  Stream<String> watchWarnings() => const Stream.empty();

  @override
  Future<void> startScan() async {
    throw const BluetoothOffFailure(
      'Bluetooth is off. Turn it on to scan for a heart-rate strap.',
    );
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(HeartRateDevice device) async {}

  @override
  Future<void> disconnect() async {}

  @override
  void setActivity(ActivityProfile profile) {}

  @override
  Future<void> dispose() async {}
}
