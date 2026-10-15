import 'package:flutter_test/flutter_test.dart';
import 'package:pulsekeep/data/local/sqlite_reading_store.dart';
import 'package:pulsekeep/domain/models/heart_rate_measurement.dart';
import 'package:pulsekeep/domain/models/heart_rate_reading.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('stores, orders, and marks readings synced', () async {
    final store = await SqliteReadingStore.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(store.close);

    final older = _reading(
      id: 'a',
      bpm: 61,
      at: DateTime.utc(2026, 10, 15, 12),
      rr: const [980],
    );
    final newer = _reading(
      id: 'b',
      bpm: 88,
      at: DateTime.utc(2026, 10, 15, 12, 1),
    );
    await store.insert(older);
    await store.insert(newer);

    final recent = await store.recent();
    expect(recent.map((reading) => reading.id), ['b', 'a']);
    expect(recent.last.rrIntervalsMs, [980]);
    expect(recent.last.sensorContact, SensorContact.detected);

    expect((await store.pending()).map((reading) => reading.id), ['a', 'b']);
    final before = await store.stats();
    expect(before.count, 2);
    expect(before.pending, 2);
    expect(before.minBpm, 61);
    expect(before.maxBpm, 88);
    expect(before.averageBpm, 75);

    await store.markSynced(['a']);
    expect((await store.pending()).map((reading) => reading.id), ['b']);
    expect((await store.stats()).pending, 1);
  });
}

HeartRateReading _reading({
  required String id,
  required int bpm,
  required DateTime at,
  List<int> rr = const [],
}) {
  return HeartRateReading(
    id: id,
    bpm: bpm,
    recordedAt: at,
    sourceId: 'strap',
    sourceName: 'Strap',
    synced: false,
    sensorContact: SensorContact.detected,
    rrIntervalsMs: rr,
  );
}
