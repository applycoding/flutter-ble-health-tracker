import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ledger/data/heart_rate_repository_impl.dart';
import 'package:pulse_ledger/data/local/app_database.dart';
import 'package:pulse_ledger/data/manual_network_gate.dart';
import 'package:pulse_ledger/data/remote/mock_sync_client.dart';
import 'package:pulse_ledger/domain/models.dart';
import 'package:pulse_ledger/domain/ports.dart';

import 'support/samples.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late ManualNetworkGate network;
  late MockSyncClient sync;
  late HeartRateRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    network = ManualNetworkGate();
    sync = MockSyncClient(latency: Duration.zero);
    repository = HeartRateRepositoryImpl(
      database: database,
      syncClient: sync,
      network: network,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('stores a reading before it is synced', () async {
    final stored = await repository.record(sample(bpm: 88, recordedAt: DateTime.utc(2026, 10, 15, 12, 4, 5)));
    final rows = await repository.watchAll().first;

    expect(stored.id, isNotNull);
    expect(rows, hasLength(1));
    expect(rows.single.bpm, 88);
    expect(rows.single.synced, isFalse);
    expect(rows.single.recordedAt.toUtc(), DateTime.utc(2026, 10, 15, 12, 4, 5));
    expect(rows.single.rrIntervalsMs.single, closeTo(833, 0.1));
    expect(await repository.watchPendingCount().first, 1);
  });

  test('returns the newest reading first', () async {
    await repository.record(sample(bpm: 60, recordedAt: DateTime.utc(2026, 10, 15, 12)));
    await repository.record(sample(bpm: 90, recordedAt: DateTime.utc(2026, 10, 15, 12, 1)));
    final rows = await repository.watchAll().first;
    expect(rows.map((row) => row.bpm), [90, 60]);
  });

  test('keeps the queue while offline and flushes it when the link returns', () async {
    network.setOnline(false);
    await repository.record(sample());
    final offline = await repository.syncPending();
    expect(offline.outcome, SyncOutcome.offline);
    expect(sync.uploaded, isEmpty);
    expect((await repository.watchAll().first).single.synced, isFalse);

    network.setOnline(true);
    final online = await repository.syncPending();
    expect(online.outcome, SyncOutcome.synced);
    expect(online.count, 1);
    expect(sync.uploaded, hasLength(1));
    final stored = (await repository.watchAll().first).single;
    expect(stored.synced, isTrue);
    expect(stored.remoteId, 'mock-${stored.id}');
    expect(await repository.watchPendingCount().first, 0);
  });

  test('a failed upload leaves the row queued', () async {
    await repository.record(sample());
    sync.failNext = true;
    final report = await repository.syncPending();
    expect(report.outcome, SyncOutcome.failed);
    expect((await repository.watchAll().first).single.synced, isFalse);
  });

  test('reports a missing Firebase configuration without marking rows synced', () async {
    final unconfigured = HeartRateRepositoryImpl(
      database: database,
      syncClient: const _UnconfiguredSync(),
      network: network,
    );
    await unconfigured.record(sample());
    final report = await unconfigured.syncPending();
    expect(report.outcome, SyncOutcome.notConfigured);
    expect((await repository.watchAll().first).single.synced, isFalse);
  });

  test('rejects a heart rate outside the stored range', () async {
    expect(() => repository.record(sample(bpm: 900)), throwsArgumentError);
  });
}

final class _UnconfiguredSync implements HeartRateSyncClient {
  const _UnconfiguredSync();

  @override
  String get targetLabel => 'Firestore (unset)';

  @override
  Future<List<String>> upload(List<HeartRateReading> readings) {
    throw const SyncNotConfiguredException('missing credentials');
  }
}
