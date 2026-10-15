import 'package:pulse_ledger/domain/models.dart';

HeartRateReading reading({
  int? id,
  int bpm = 72,
  DateTime? recordedAt,
  bool synced = false,
  String? remoteId,
}) {
  return HeartRateReading(
    id: id,
    bpm: bpm,
    recordedAt: recordedAt ?? DateTime.utc(2026, 10, 15, 12),
    deviceId: 'demo-pulseband',
    deviceName: 'PulseBand Demo',
    source: ReadingSource.demo,
    synced: synced,
    remoteId: remoteId,
    energyExpendedKj: 3,
    rrIntervalsMs: const [833],
    sensorContactSupported: true,
    sensorContactDetected: true,
  );
}

HeartRateSample sample({
  int bpm = 72,
  DateTime? recordedAt,
}) {
  final stored = reading(bpm: bpm, recordedAt: recordedAt);
  return HeartRateSample(
    bpm: stored.bpm,
    recordedAt: stored.recordedAt,
    deviceId: stored.deviceId,
    deviceName: stored.deviceName,
    source: stored.source,
    energyExpendedKj: stored.energyExpendedKj,
    rrIntervalsMs: stored.rrIntervalsMs,
    sensorContactSupported: stored.sensorContactSupported,
    sensorContactDetected: stored.sensorContactDetected,
  );
}
