import 'package:drift/drift.dart';

import '../domain/models.dart';
import '../domain/ports.dart';
import 'local/app_database.dart';

class HeartRateRepositoryImpl implements HeartRateRepository {
  HeartRateRepositoryImpl({
    required this.database,
    required this.syncClient,
    required this.network,
    this.batchSize = 40,
  });

  final AppDatabase database;
  final HeartRateSyncClient syncClient;
  final NetworkGate network;
  final int batchSize;

  @override
  Stream<List<HeartRateReading>> watchAll({int limit = 300}) {
    return database.watchRecent(limit: limit).map(
          (rows) => [for (final row in rows) row.toReading()],
        );
  }

  @override
  Stream<int> watchPendingCount() => database.watchPendingCount();

  @override
  Future<HeartRateReading> record(HeartRateSample sample) async {
    if (sample.bpm < 0 || sample.bpm > 400) {
      throw ArgumentError.value(sample.bpm, 'bpm', 'expected 0–400');
    }
    final id = await database.insertSample(
      PulseSamplesCompanion(
        bpm: Value(sample.bpm),
        recordedAt: Value(sample.recordedAt),
        deviceId: Value(sample.deviceId),
        deviceName: Value(sample.deviceName),
        source: Value(sample.source.name),
        synced: const Value(false),
        energyExpendedKj: Value(sample.energyExpendedKj),
        rrIntervalsMs: Value(encodeRrIntervals(sample.rrIntervalsMs)),
        sensorContactSupported: Value(sample.sensorContactSupported),
        sensorContactDetected: Value(sample.sensorContactDetected),
      ),
    );
    return HeartRateReading(
      id: id,
      bpm: sample.bpm,
      recordedAt: sample.recordedAt,
      deviceId: sample.deviceId,
      deviceName: sample.deviceName,
      source: sample.source,
      synced: false,
      remoteId: null,
      energyExpendedKj: sample.energyExpendedKj,
      rrIntervalsMs: sample.rrIntervalsMs,
      sensorContactSupported: sample.sensorContactSupported,
      sensorContactDetected: sample.sensorContactDetected,
    );
  }

  @override
  Future<SyncReport> syncPending() async {
    final pending = await database.pendingRows(limit: batchSize);
    if (!network.isOnline) {
      return SyncReport(
        outcome: SyncOutcome.offline,
        pending: pending.length,
        message: pending.isEmpty
            ? 'Offline. Nothing is waiting to sync.'
            : 'Offline. ${_readings(pending.length)} queued locally.',
      );
    }
    if (pending.isEmpty) {
      return SyncReport(
        outcome: SyncOutcome.upToDate,
        message: 'Local log matches ${syncClient.targetLabel}.',
      );
    }

    final readings = [for (final row in pending) row.toReading()];
    try {
      final remoteIds = await syncClient.upload(readings);
      if (remoteIds.length != readings.length) {
        throw const SyncTransportException('Sync client returned an unexpected id count.');
      }
      await database.markSynced([
        for (var i = 0; i < readings.length; i++)
          (id: readings[i].id!, remoteId: remoteIds[i]),
      ]);
      final stillWaiting = await database.pendingRows(limit: batchSize);
      return SyncReport(
        outcome: SyncOutcome.synced,
        count: readings.length,
        pending: stillWaiting.length,
        message: 'Sent ${_readings(readings.length)} to ${syncClient.targetLabel}.',
      );
    } on SyncNotConfiguredException catch (error) {
      return SyncReport(
        outcome: SyncOutcome.notConfigured,
        pending: readings.length,
        message: error.message,
      );
    } on SyncException catch (error) {
      return SyncReport(
        outcome: SyncOutcome.failed,
        pending: readings.length,
        message: error.message,
      );
    }
  }
}

String encodeRrIntervals(List<double> values) {
  if (values.isEmpty) return '';
  return values.map((value) => value.toStringAsFixed(1)).join(',');
}

List<double> decodeRrIntervals(String raw) {
  if (raw.isEmpty) return const [];
  return [for (final part in raw.split(',')) double.parse(part)];
}

String _readings(int count) => count == 1 ? '1 reading' : '$count readings';

extension on PulseSampleRow {
  HeartRateReading toReading() {
    return HeartRateReading(
      id: id,
      bpm: bpm,
      recordedAt: recordedAt,
      deviceId: deviceId,
      deviceName: deviceName,
      source: ReadingSource.parse(source),
      synced: synced,
      remoteId: remoteId,
      energyExpendedKj: energyExpendedKj,
      rrIntervalsMs: decodeRrIntervals(rrIntervalsMs),
      sensorContactSupported: sensorContactSupported,
      sensorContactDetected: sensorContactDetected,
    );
  }
}
