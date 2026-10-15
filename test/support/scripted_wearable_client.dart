import 'dart:async';

import 'package:pulse_ledger/domain/models.dart';
import 'package:pulse_ledger/domain/ports.dart';

class ScriptedWearableClient implements WearableClient {
  final _status = StreamController<WearableStatus>.broadcast();
  final _samples = StreamController<HeartRateSample>.broadcast();
  final _scans = StreamController<List<DiscoveredWearable>>.broadcast();

  void emit(HeartRateSample sample) {
    _samples.add(sample);
  }

  void emitDevices(List<DiscoveredWearable> devices) {
    _scans.add(devices);
  }

  @override
  Stream<WearableStatus> get status => _status.stream;

  @override
  Stream<List<DiscoveredWearable>> get scanResults => _scans.stream;

  @override
  Stream<HeartRateSample> get samples => _samples.stream;

  @override
  Future<void> start() async {
    _status.add(
      const WearableStatus(
        phase: WearablePhase.streaming,
        deviceName: 'Scripted strap',
        message: 'Scripted stream.',
      ),
    );
  }

  @override
  Future<void> stop() async {
    _status.add(
      const WearableStatus(
        phase: WearablePhase.stopped,
        message: 'Scripted stream stopped.',
      ),
    );
  }

  @override
  Future<void> connect(DiscoveredWearable device) async {
    _status.add(
      WearableStatus(
        phase: WearablePhase.streaming,
        deviceName: device.name,
        message: 'Connected to ${device.name}.',
      ),
    );
  }
}
