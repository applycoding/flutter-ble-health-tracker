import 'dart:async';

import '../../domain/models.dart';
import '../../domain/ports.dart';
import 'demo_heart_wave.dart';

/// Simulated strap. It advertises nothing and emits parsed 0x2A37 values on a timer.
class MockWearableClient implements WearableClient {
  MockWearableClient({
    this.interval = const Duration(seconds: 1),
    int seed = 42,
  }) : _wave = DemoHeartWave(seed: seed);

  final Duration interval;
  final DemoHeartWave _wave;
  final _status = StreamController<WearableStatus>.broadcast();
  final _samples = StreamController<HeartRateSample>.broadcast();
  final _scans = StreamController<List<DiscoveredWearable>>.broadcast();
  Timer? _timer;

  static const deviceId = 'demo-pulseband';
  static const deviceName = 'PulseBand Demo';

  @override
  Stream<WearableStatus> get status => _status.stream;

  @override
  Stream<List<DiscoveredWearable>> get scanResults => _scans.stream;

  @override
  Stream<HeartRateSample> get samples => _samples.stream;

  @override
  Future<void> start() async {
    _timer?.cancel();
    _emit(
      const WearableStatus(
        phase: WearablePhase.streaming,
        deviceName: deviceName,
        message: 'Simulated 0x2A37 notifications from PulseBand Demo.',
      ),
    );
    _emitSample();
    _timer = Timer.periodic(interval, (_) => _emitSample());
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _emit(
      const WearableStatus(
        phase: WearablePhase.stopped,
        deviceName: deviceName,
        message: 'Simulated strap paused.',
      ),
    );
  }

  @override
  Future<void> connect(DiscoveredWearable device) async {
    await start();
  }

  void _emitSample() {
    if (_samples.isClosed) return;
    final measurement = _wave.next();
    _samples.add(
      HeartRateSample(
        bpm: measurement.bpm,
        recordedAt: DateTime.now(),
        deviceId: deviceId,
        deviceName: deviceName,
        source: ReadingSource.demo,
        energyExpendedKj: measurement.energyExpendedKj,
        rrIntervalsMs: measurement.rrIntervalsMs,
        sensorContactSupported: measurement.sensorContactSupported,
        sensorContactDetected: measurement.sensorContactDetected,
      ),
    );
  }

  void _emit(WearableStatus status) {
    if (!_status.isClosed) _status.add(status);
  }
}
