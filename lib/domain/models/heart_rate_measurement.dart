/// Whether the sensor reported contact, per the Heart Rate Measurement flags.
enum SensorContact { notSupported, notDetected, detected }

/// One decoded Heart Rate Measurement packet (characteristic 0x2A37).
final class HeartRateMeasurement {
  const HeartRateMeasurement({
    required this.bpm,
    required this.sensorContact,
    this.energyExpended,
    this.rrIntervalsMs = const [],
  });

  final int bpm;
  final SensorContact sensorContact;

  /// Energy expended in kilojoules, when the packet includes it.
  final int? energyExpended;

  /// RR-intervals converted from 1/1024 s units to milliseconds.
  final List<int> rrIntervalsMs;
}
