import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsekeep/domain/models/device_models.dart';
import 'package:pulsekeep/domain/models/heart_rate_measurement.dart';
import 'package:pulsekeep/domain/repositories/heart_rate_repository.dart';
import 'package:pulsekeep/presentation/monitor/monitor_controller.dart';
import 'package:pulsekeep/presentation/providers.dart';

import '../support/fakes.dart';
import '../support/memory_reading_store.dart';

void main() {
  test('persists at most one reading per second', () async {
    final store = MemoryReadingStore();
    final clock = MutableClock();
    final gateway = ScriptedGateway();
    final repository = HeartRateRepository(
      local: store,
      remote: FakeHeartRateRemote(configured: false),
      network: FakeNetworkStatus(),
      ids: SequentialIds(),
      clock: clock,
    );
    final container = ProviderContainer(
      overrides: [
        heartRateRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(clock),
        simulatedGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(gateway.dispose);
    addTearDown(container.dispose);

    container
        .read(selectedDeviceProvider.notifier)
        .select(
          const HeartRateDevice(
            id: 'scripted',
            name: 'Scripted',
            kind: DeviceKind.simulator,
          ),
        );
    await container.read(monitorControllerProvider.notifier).start();

    const beat = HeartRateMeasurement(
      bpm: 70,
      sensorContact: SensorContact.detected,
    );
    gateway.emit(beat);
    gateway.emit(
      const HeartRateMeasurement(
        bpm: 71,
        sensorContact: SensorContact.detected,
      ),
    );
    await _flush();
    expect(await store.recent(), hasLength(1));
    expect(container.read(monitorControllerProvider).bpm, 71);
    expect(container.read(monitorControllerProvider).window, hasLength(2));

    clock.current = clock.current.add(const Duration(seconds: 1));
    gateway.emit(
      const HeartRateMeasurement(
        bpm: 74,
        sensorContact: SensorContact.notDetected,
      ),
    );
    await _flush();
    expect(await store.recent(), hasLength(2));
    expect(container.read(monitorControllerProvider).savedCount, 2);
    expect(
      container.read(monitorControllerProvider).sensorContact,
      SensorContact.notDetected,
    );
  });
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
