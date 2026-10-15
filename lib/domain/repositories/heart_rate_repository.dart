import '../models/device_models.dart';
import '../models/heart_rate_measurement.dart';
import '../models/heart_rate_reading.dart';
import '../models/sync_models.dart';
import '../ports.dart';

/// Writes every reading to the local store first, then tries to sync.
///
/// A failed or unconfigured sync never drops the sample. Callers keep showing
/// live BPM even when the network or Firebase is unavailable.
final class HeartRateRepository {
  HeartRateRepository({
    required this._local,
    required this._remote,
    required this._network,
    required this._ids,
    required this._clock,
  });

  final ReadingStore _local;
  final HeartRateRemote _remote;
  final NetworkStatus _network;
  final ReadingIdFactory _ids;
  final Clock _clock;

  Future<SyncOutcome>? _inFlight;

  HeartRateRemote get remote => _remote;

  Future<HeartRateReading> record({
    required HeartRateMeasurement measurement,
    required HeartRateDevice device,
  }) async {
    final reading = HeartRateReading(
      id: _ids.next(),
      bpm: measurement.bpm,
      recordedAt: _clock.now().toUtc(),
      sourceId: device.id,
      sourceName: device.name,
      synced: false,
      sensorContact: measurement.sensorContact,
      energyExpended: measurement.energyExpended,
      rrIntervalsMs: measurement.rrIntervalsMs,
    );
    await _local.insert(reading);
    return reading;
  }

  Stream<HistorySnapshot> watchHistory({int limit = 200}) async* {
    yield await _snapshot(limit);
    await for (final _ in _local.changes) {
      yield await _snapshot(limit);
    }
  }

  Future<HistorySnapshot> _snapshot(int limit) async {
    final recent = await _local.recent(limit: limit);
    final stats = await _local.stats();
    return HistorySnapshot(recent: recent, stats: stats);
  }

  /// Pushes queued rows when Firebase is configured and a network is up.
  ///
  /// Concurrent callers share one in-flight attempt.
  Future<SyncOutcome> syncPending() {
    final existing = _inFlight;
    if (existing != null) return existing;
    late final Future<SyncOutcome> published;
    published = _syncPending().whenComplete(() {
      if (identical(_inFlight, published)) _inFlight = null;
    });
    _inFlight = published;
    return published;
  }

  Future<SyncOutcome> _syncPending() async {
    final before = await _local.stats();
    if (!_remote.isConfigured) {
      return SyncOutcome(
        phase: SyncPhase.localOnly,
        pending: before.pending,
        detail: _remote.statusDetail,
      );
    }
    if (!await _network.isOnline) {
      return SyncOutcome(
        phase: SyncPhase.offline,
        pending: before.pending,
        detail: 'Offline. Readings stay on this device.',
      );
    }
    if (before.pending == 0) {
      return const SyncOutcome(
        phase: SyncPhase.synced,
        pending: 0,
        detail: 'Nothing waiting to sync.',
      );
    }

    var pushed = 0;
    try {
      // Firestore batches cap at 500 writes. Stay under that, and cap the
      // number of round-trips so one tap cannot loop forever.
      for (var round = 0; round < 5; round++) {
        final batch = await _local.pending(limit: 400);
        if (batch.isEmpty) break;
        await _remote.push(batch);
        await _local.markSynced(batch.map((reading) => reading.id));
        pushed += batch.length;
      }
    } catch (_) {
      final pending = (await _local.stats()).pending;
      return SyncOutcome(
        phase: SyncPhase.failed,
        pending: pending,
        detail: 'Sync failed. Readings are still saved on this device.',
      );
    }

    final pending = (await _local.stats()).pending;
    if (pending > 0) {
      return SyncOutcome(
        phase: SyncPhase.syncing,
        pending: pending,
        detail: 'Synced $pushed. $pending still queued.',
      );
    }
    return SyncOutcome(
      phase: SyncPhase.synced,
      pending: 0,
      detail: 'Synced $pushed ${pushed == 1 ? 'reading' : 'readings'}.',
    );
  }
}
