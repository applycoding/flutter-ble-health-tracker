import 'dart:math' as math;

import '../../domain/models.dart';
import 'heart_rate_parser.dart';

/// Builds plausible Heart Rate Measurement packets and parses them back, so
/// demo mode exercises the same decoder as a live 0x2A37 notification.
class DemoHeartWave {
  DemoHeartWave({int seed = 42}) : _random = math.Random(seed);

  final math.Random _random;
  int _bpm = 68;
  int _energyKj = 0;
  int _tick = 0;

  HeartRateMeasurement next() {
    _tick += 1;
    final cycle = math.sin(_tick / 8) * 5;
    final drift = math.sin(_tick / 23) * 3;
    final noise = (_random.nextDouble() - 0.5) * 2;
    var target = 70 + cycle + drift + noise;
    if (_tick % 48 > 43) {
      target += 18;
    }
    _bpm = (_bpm * 0.72 + target * 0.28).round().clamp(54, 156);
    _energyKj = (_energyKj + 1) & 0xffff;
    final rrMs = 60000 / _bpm;
    final bytes = encodeHeartRateMeasurement(
      bpm: _bpm,
      sensorContactSupported: true,
      sensorContactDetected: true,
      energyExpendedKj: _energyKj,
      rrIntervalsMs: [rrMs, rrMs * 1.01],
    );
    return parseHeartRateMeasurement(bytes);
  }
}
