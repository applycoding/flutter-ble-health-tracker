import 'package:flutter_test/flutter_test.dart';
import 'package:pulsekeep/domain/models/device_models.dart';
import 'package:pulsekeep/domain/models/heart_rate_measurement.dart';
import 'package:pulsekeep/domain/models/sync_models.dart';
import 'package:pulsekeep/domain/repositories/heart_rate_repository.dart';

import '../support/fakes.dart';
import '../support/memory_reading_store.dart';

void main() {
  const device = HeartRateDevice(
    id: 'strap-1',
    name: 'Strap',
    kind: DeviceKind.ble,
  );
  const measurement = HeartRateMeasurement(
    bpm: 72,
    sensorContact: SensorContact.detected,
    rrIntervalsMs: [833],
  );

  test('keeps readings local when Firebase is not configured', () async {
    final store = MemoryReadingStore();
    final remote = FakeHeartRateRemote(configured: false);
    final repository = _repository(store: store, remote: remote);

    final saved = await repository.record(
      measurement: measurement,
      device: device,
    );
    final outcome = await repository.syncPending();

    expect(saved.synced, isFalse);
    expect(saved.bpm, 72);
    expect(remote.pushed, isEmpty);
    expect(outcome.phase, SyncPhase.localOnly);
    expect(outcome.pending, 1);
    expect((await store.pending()).single.id, saved.id);
  });

  test('pushes pending readings and marks them synced when online', () async {
    final store = MemoryReadingStore();
    final remote = FakeHeartRateRemote();
    final repository = _repository(store: store, remote: remote);
    await repository.record(measurement: measurement, device: device);
    await repository.record(
      measurement: const HeartRateMeasurement(
        bpm: 80,
        sensorContact: SensorContact.detected,
      ),
      device: device,
    );

    final outcome = await repository.syncPending();

    expect(outcome.phase, SyncPhase.synced);
    expect(outcome.pending, 0);
    expect(remote.pushed.map((reading) => reading.bpm), [72, 80]);
    expect(await store.pending(), isEmpty);
  });

  test('does not push while offline and retries after the failure', () async {
    final store = MemoryReadingStore();
    final remote = FakeHeartRateRemote(fail: true);
    final network = FakeNetworkStatus();
    final repository = _repository(
      store: store,
      remote: remote,
      network: network,
    );
    await repository.record(measurement: measurement, device: device);

    network.online = false;
    final offline = await repository.syncPending();
    expect(offline.phase, SyncPhase.offline);
    expect(remote.pushed, isEmpty);

    network.online = true;
    final failed = await repository.syncPending();
    expect(failed.phase, SyncPhase.failed);
    expect(await store.pending(), hasLength(1));

    remote.fail = false;
    final synced = await repository.syncPending();
    expect(synced.phase, SyncPhase.synced);
    expect(remote.pushed, hasLength(1));
  });

  test('shares one in-flight sync between callers', () async {
    final store = MemoryReadingStore();
    final remote = FakeHeartRateRemote();
    final repository = _repository(store: store, remote: remote);
    await repository.record(measurement: measurement, device: device);

    final first = repository.syncPending();
    final second = repository.syncPending();
    expect(identical(first, second), isTrue);
    await Future.wait([first, second]);
    expect(remote.pushed, hasLength(1));
  });
}

HeartRateRepository _repository({
  required MemoryReadingStore store,
  required FakeHeartRateRemote remote,
  FakeNetworkStatus? network,
}) {
  return HeartRateRepository(
    local: store,
    remote: remote,
    network: network ?? FakeNetworkStatus(),
    ids: SequentialIds(),
    clock: MutableClock(),
  );
}
