/// Where a stored beat came from.
enum ReadingSource {
  ble,
  demo;

  String get label => switch (this) {
        ReadingSource.ble => 'BLE',
        ReadingSource.demo => 'Demo',
      };

  static ReadingSource parse(String value) => switch (value) {
        'ble' => ReadingSource.ble,
        'demo' => ReadingSource.demo,
        _ => throw FormatException('Unknown reading source: $value'),
      };
}

/// Link state for either the simulated strap or a live adapter.
enum WearablePhase { idle, scanning, connecting, streaming, stopped, error }

/// Result of an attempt to flush the local queue.
enum SyncOutcome { synced, upToDate, offline, notConfigured, failed }

/// One persisted heart-rate sample. [id] is null only before insert.
class HeartRateReading {
  const HeartRateReading({
    required this.id,
    required this.bpm,
    required this.recordedAt,
    required this.deviceId,
    required this.deviceName,
    required this.source,
    required this.synced,
    required this.remoteId,
    required this.energyExpendedKj,
    required this.rrIntervalsMs,
    required this.sensorContactSupported,
    required this.sensorContactDetected,
  });

  final int? id;
  final int bpm;
  final DateTime recordedAt;
  final String deviceId;
  final String deviceName;
  final ReadingSource source;
  final bool synced;
  final String? remoteId;
  final int? energyExpendedKj;
  final List<double> rrIntervalsMs;
  final bool sensorContactSupported;
  final bool sensorContactDetected;
}

/// A beat observed from a wearable, before it is stored.
class HeartRateSample {
  const HeartRateSample({
    required this.bpm,
    required this.recordedAt,
    required this.deviceId,
    required this.deviceName,
    required this.source,
    required this.energyExpendedKj,
    required this.rrIntervalsMs,
    required this.sensorContactSupported,
    required this.sensorContactDetected,
  });

  final int bpm;
  final DateTime recordedAt;
  final String deviceId;
  final String deviceName;
  final ReadingSource source;
  final int? energyExpendedKj;
  final List<double> rrIntervalsMs;
  final bool sensorContactSupported;
  final bool sensorContactDetected;
}

/// Decoded Bluetooth Heart Rate Measurement (UUID 0x2A37).
class HeartRateMeasurement {
  const HeartRateMeasurement({
    required this.bpm,
    required this.sensorContactSupported,
    required this.sensorContactDetected,
    required this.energyExpendedKj,
    required this.rrIntervalsMs,
  });

  final int bpm;
  final bool sensorContactSupported;
  final bool sensorContactDetected;

  /// Optional Energy Expended field, in kilojoules, as defined by the spec.
  final int? energyExpendedKj;
  final List<double> rrIntervalsMs;
}

class HeartRateStats {
  const HeartRateStats({
    required this.min,
    required this.max,
    required this.average,
    required this.count,
  });

  static const empty = HeartRateStats(
    min: null,
    max: null,
    average: null,
    count: 0,
  );

  final int? min;
  final int? max;
  final int? average;
  final int count;

  factory HeartRateStats.from(List<HeartRateReading> readings) {
    if (readings.isEmpty) return empty;
    var minBpm = readings.first.bpm;
    var maxBpm = readings.first.bpm;
    var sum = 0;
    for (final reading in readings) {
      if (reading.bpm < minBpm) minBpm = reading.bpm;
      if (reading.bpm > maxBpm) maxBpm = reading.bpm;
      sum += reading.bpm;
    }
    return HeartRateStats(
      min: minBpm,
      max: maxBpm,
      average: (sum / readings.length).round(),
      count: readings.length,
    );
  }
}

class DiscoveredWearable {
  const DiscoveredWearable({
    required this.id,
    required this.name,
    required this.rssi,
  });

  final String id;
  final String name;
  final int? rssi;
}

class WearableStatus {
  const WearableStatus({
    required this.phase,
    required this.message,
    this.deviceName,
  });

  final WearablePhase phase;
  final String message;
  final String? deviceName;
}

class SyncReport {
  const SyncReport({
    required this.outcome,
    required this.message,
    this.count = 0,
    this.pending = 0,
  });

  final SyncOutcome outcome;
  final String message;
  final int count;
  final int pending;
}

class ReadingDay {
  const ReadingDay({required this.day, required this.readings});

  /// Local midnight for the group.
  final DateTime day;

  /// Newest first, matching the repository stream.
  final List<HeartRateReading> readings;
}

List<ReadingDay> groupReadingsByDay(List<HeartRateReading> newestFirst) {
  final groups = <DateTime, List<HeartRateReading>>{};
  final order = <DateTime>[];
  for (final reading in newestFirst) {
    final local = reading.recordedAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final bucket = groups[day];
    if (bucket == null) {
      groups[day] = [reading];
      order.add(day);
    } else {
      bucket.add(reading);
    }
  }
  return [
    for (final day in order) ReadingDay(day: day, readings: groups[day]!),
  ];
}
