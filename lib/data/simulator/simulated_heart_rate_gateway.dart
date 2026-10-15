import 'dart:async';
import 'dart:math' as math;

import '../../domain/failures/app_failure.dart';
import '../../domain/models/device_models.dart';
import '../../domain/models/heart_rate_measurement.dart';
import '../../domain/ports.dart';

/// A heart-rate source with no radio and no Firebase.
///
/// The trace eases toward a rest, walk, or run level and adds a small
/// respiratory wave so the chart moves. It is not a physiological model.
final class SimulatedHeartRateGateway implements HeartRateGateway {
  SimulatedHeartRateGateway({
    math.Random? random,
    this.interval = const Duration(seconds: 1),
    this.replayCount = 24,
  }) : _random = random ?? math.Random();

  static const device = HeartRateDevice(
    id: 'sim-pulsekeep',
    name: 'PulseKeep Simulator',
    kind: DeviceKind.simulator,
    rssi: -42,
  );

  final Duration interval;
  final int replayCount;
  final math.Random _random;

  final StreamController<List<HeartRateDevice>> _devices =
      StreamController<List<HeartRateDevice>>.broadcast(sync: true);
  final StreamController<LinkStatus> _link =
      StreamController<LinkStatus>.broadcast(sync: true);
  final StreamController<HeartRateMeasurement> _measurements =
      StreamController<HeartRateMeasurement>.broadcast(sync: true);
  final StreamController<String> _warnings = StreamController<String>.broadcast(
    sync: true,
  );

  ActivityProfile _profile = ActivityProfile.rest;
  Timer? _timer;
  var _level = 68.0;
  var _tick = 0;
  var _connected = false;

  @override
  bool get canChangeActivity => true;

  @override
  Stream<RadioStatus> watchRadio() async* {
    yield RadioStatus.on;
  }

  @override
  Stream<List<HeartRateDevice>> watchDevices() async* {
    yield const [device];
    yield* _devices.stream;
  }

  @override
  Stream<LinkStatus> watchLink() => _link.stream;

  @override
  Stream<HeartRateMeasurement> watchMeasurements() => _measurements.stream;

  @override
  Stream<String> watchWarnings() => _warnings.stream;

  @override
  void setActivity(ActivityProfile profile) {
    _profile = profile;
  }

  @override
  Future<void> startScan() async {
    _devices.add(const [device]);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(HeartRateDevice device) async {
    if (device.id != SimulatedHeartRateGateway.device.id) {
      final failure = ConnectionFailure('Unknown simulated device.');
      _link.add(LinkFailed(failure.message));
      throw failure;
    }
    _timer?.cancel();
    _connected = true;
    _profile = ActivityProfile.rest;
    _level = 68;
    _tick = 0;
    _link.add(const LinkConnecting());
    for (var i = 0; i < replayCount; i++) {
      _emit(blend: 1);
    }
    _link.add(const LinkLive());
    _timer = Timer.periodic(interval, (_) => _emit(blend: 0.35));
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
    _connected = false;
    _link.add(const LinkDisconnected());
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _devices.close();
    await _link.close();
    await _measurements.close();
    await _warnings.close();
  }

  void _emit({required double blend}) {
    if (!_connected || _measurements.isClosed) return;
    final bpm = _nextBpm(blend);
    final rr = (60000 / bpm).round();
    _measurements.add(
      HeartRateMeasurement(
        bpm: bpm,
        sensorContact: SensorContact.detected,
        rrIntervalsMs: [rr],
      ),
    );
  }

  int _nextBpm(double blend) {
    final target = switch (_profile) {
      ActivityProfile.rest => 68.0,
      ActivityProfile.walk => 104.0,
      ActivityProfile.run => 148.0,
    };
    _level += (target - _level) * blend;
    _tick += 1;
    final wave = math.sin(_tick / 3) * 2.8;
    final noise = (_random.nextDouble() - 0.5) * 1.8;
    return (_level + wave + noise).round().clamp(42, 196);
  }
}
