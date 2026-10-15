import 'dart:async';

import 'package:pulsekeep/domain/failures/app_failure.dart';
import 'package:pulsekeep/domain/models/device_models.dart';
import 'package:pulsekeep/domain/models/heart_rate_measurement.dart';
import 'package:pulsekeep/domain/models/heart_rate_reading.dart';
import 'package:pulsekeep/domain/ports.dart';

final class MutableClock implements Clock {
  MutableClock([DateTime? start])
    : current = start ?? DateTime.utc(2026, 10, 15, 12);

  DateTime current;

  @override
  DateTime now() => current;
}

final class SequentialIds implements ReadingIdFactory {
  var n = 0;

  @override
  String next() {
    n += 1;
    return 'id-$n';
  }
}

final class FakeNetworkStatus implements NetworkStatus {
  FakeNetworkStatus({this.online = true});

  bool online;

  @override
  Future<bool> get isOnline async => online;

  @override
  Stream<bool> watch() async* {
    yield online;
  }
}

final class FakeHeartRateRemote implements HeartRateRemote {
  FakeHeartRateRemote({this.configured = true, this.fail = false});

  bool configured;
  bool fail;
  final List<HeartRateReading> pushed = [];

  @override
  bool get isConfigured => configured;

  @override
  String get statusDetail => configured
      ? 'Fake cloud'
      : 'Firebase is not configured. Readings stay on this device.';

  @override
  Future<void> push(List<HeartRateReading> readings) async {
    if (fail) throw StateError('cloud unavailable');
    pushed.addAll(readings);
  }
}

final class FakeBleCentral implements BleCentral {
  FakeBleCentral({this.radio = RadioStatus.on});

  RadioStatus radio;
  var permissionRequests = 0;
  var scanStarts = 0;
  final StreamController<BleAdvertisement> advertisements =
      StreamController<BleAdvertisement>.broadcast();
  final Map<String, FakePeripheral> peripherals = {};

  @override
  Future<RadioStatus> currentRadio() async => radio;

  @override
  Stream<RadioStatus> watchRadio() async* {
    yield radio;
  }

  @override
  Future<void> requestPermissions() async {
    permissionRequests += 1;
  }

  @override
  Stream<BleAdvertisement> watchAdvertisements() => advertisements.stream;

  @override
  Future<void> startScan({required String serviceUuid}) async {
    if (radio != RadioStatus.on) {
      throw const BluetoothOffFailure('Bluetooth is off.');
    }
    scanStarts += 1;
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<BlePeripheralSession> connect(String deviceId) async {
    final peripheral = peripherals[deviceId];
    if (peripheral == null) {
      throw const ConnectionFailure('Device not found.');
    }
    return peripheral;
  }
}

final class FakePeripheral implements BlePeripheralSession {
  FakePeripheral({
    this.missingService = false,
    List<List<int>> packets = const [],
  }) : packets = List.of(packets);

  bool missingService;
  List<List<int>> packets;
  final StreamController<List<int>> _values = StreamController<List<int>>();
  var disconnected = false;

  void emit(List<int> bytes) => _values.add(bytes);

  @override
  Future<HeartRateNotifications> subscribeHeartRate({
    required String serviceUuid,
    required String measurementUuid,
  }) async {
    if (missingService) throw const HeartRateServiceMissing();
    for (final packet in packets) {
      _values.add(packet);
    }
    return _FakeNotifications(_values.stream);
  }

  @override
  Future<void> disconnect() async {
    disconnected = true;
  }
}

final class _FakeNotifications implements HeartRateNotifications {
  _FakeNotifications(this.values);

  @override
  final Stream<List<int>> values;

  @override
  Future<void> unsubscribe() async {}
}

/// Gateway whose measurements are pushed by the test after [connect].
final class ScriptedGateway implements HeartRateGateway {
  final StreamController<HeartRateMeasurement> _measurements =
      StreamController<HeartRateMeasurement>.broadcast();
  final StreamController<LinkStatus> _link =
      StreamController<LinkStatus>.broadcast();
  final StreamController<String> _warnings =
      StreamController<String>.broadcast();

  ActivityProfile activity = ActivityProfile.rest;
  var connectCount = 0;

  void emit(HeartRateMeasurement measurement) => _measurements.add(measurement);

  @override
  bool get canChangeActivity => true;

  @override
  Stream<RadioStatus> watchRadio() async* {
    yield RadioStatus.on;
  }

  @override
  Stream<List<HeartRateDevice>> watchDevices() async* {
    yield const [];
  }

  @override
  Stream<LinkStatus> watchLink() => _link.stream;

  @override
  Stream<HeartRateMeasurement> watchMeasurements() => _measurements.stream;

  @override
  Stream<String> watchWarnings() => _warnings.stream;

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(HeartRateDevice device) async {
    connectCount += 1;
    _link.add(const LinkLive());
  }

  @override
  Future<void> disconnect() async {
    _link.add(const LinkDisconnected());
  }

  @override
  void setActivity(ActivityProfile profile) {
    activity = profile;
  }

  @override
  Future<void> dispose() async {
    await _measurements.close();
    await _link.close();
    await _warnings.close();
  }
}
