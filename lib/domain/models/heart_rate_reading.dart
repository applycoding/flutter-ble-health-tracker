import 'heart_rate_measurement.dart';

/// A BPM sample persisted locally and, when configured, pushed to Firestore.
final class HeartRateReading {
  const HeartRateReading({
    required this.id,
    required this.bpm,
    required this.recordedAt,
    required this.sourceId,
    required this.sourceName,
    required this.synced,
    required this.sensorContact,
    this.energyExpended,
    this.rrIntervalsMs = const [],
  });

  final String id;
  final int bpm;
  final DateTime recordedAt;
  final String sourceId;
  final String sourceName;
  final bool synced;
  final SensorContact sensorContact;
  final int? energyExpended;
  final List<int> rrIntervalsMs;

  HeartRateReading copyWith({bool? synced}) {
    return HeartRateReading(
      id: id,
      bpm: bpm,
      recordedAt: recordedAt,
      sourceId: sourceId,
      sourceName: sourceName,
      synced: synced ?? this.synced,
      sensorContact: sensorContact,
      energyExpended: energyExpended,
      rrIntervalsMs: rrIntervalsMs,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HeartRateReading &&
        other.id == id &&
        other.bpm == bpm &&
        other.recordedAt == recordedAt &&
        other.sourceId == sourceId &&
        other.sourceName == sourceName &&
        other.synced == synced &&
        other.sensorContact == sensorContact &&
        other.energyExpended == energyExpended &&
        _sameInts(other.rrIntervalsMs, rrIntervalsMs);
  }

  @override
  int get hashCode => Object.hash(
    id,
    bpm,
    recordedAt,
    sourceId,
    sourceName,
    synced,
    sensorContact,
    energyExpended,
    Object.hashAll(rrIntervalsMs),
  );
}

bool _sameInts(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Aggregates over every stored reading, not just the visible page.
final class ReadingStats {
  const ReadingStats({
    required this.count,
    required this.pending,
    this.minBpm,
    this.maxBpm,
    this.averageBpm,
  });

  static const empty = ReadingStats(count: 0, pending: 0);

  final int count;
  final int pending;
  final int? minBpm;
  final int? maxBpm;
  final int? averageBpm;
}

final class HistorySnapshot {
  const HistorySnapshot({required this.recent, required this.stats});

  final List<HeartRateReading> recent;
  final ReadingStats stats;
}
