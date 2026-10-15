import 'dart:async';

import '../../core/ble_uuids.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/models/device_models.dart';
import '../../domain/models/heart_rate_measurement.dart';
import '../../domain/parsing/heart_rate_measurement_parser.dart';
import '../../domain/ports.dart';

/// Scans for peripherals advertising Heart Rate Service 0x180D and subscribes
/// to Heart Rate Measurement 0x2A37.
final class BluetoothHeartRateGateway implements HeartRateGateway {
  BluetoothHeartRateGateway({required this._central, required this._parser});

  final BleCentral _central;
  final HeartRateMeasurementParser _parser;

  final StreamController<List<HeartRateDevice>> _devices =
      StreamController<List<HeartRateDevice>>.broadcast(sync: true);
  final StreamController<LinkStatus> _link =
      StreamController<LinkStatus>.broadcast(sync: true);
  final StreamController<HeartRateMeasurement> _measurements =
      StreamController<HeartRateMeasurement>.broadcast(sync: true);
  final StreamController<String> _warnings = StreamController<String>.broadcast(
    sync: true,
  );

  final Map<String, HeartRateDevice> _seen = {};
  StreamSubscription<BleAdvertisement>? _scanSub;
  StreamSubscription<List<int>>? _valueSub;
  BlePeripheralSession? _session;
  var _scanning = false;

  @override
  bool get canChangeActivity => false;

  @override
  Stream<RadioStatus> watchRadio() => _central.watchRadio();

  @override
  Stream<List<HeartRateDevice>> watchDevices() => _devices.stream;

  @override
  Stream<LinkStatus> watchLink() => _link.stream;

  @override
  Stream<HeartRateMeasurement> watchMeasurements() => _measurements.stream;

  @override
  Stream<String> watchWarnings() => _warnings.stream;

  @override
  void setActivity(ActivityProfile profile) {}

  @override
  Future<void> startScan() async {
    final radio = await _central.currentRadio();
    if (radio != RadioStatus.on) {
      throw BluetoothOffFailure(_radioMessage(radio));
    }
    try {
      await _central.requestPermissions();
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw PermissionFailure(error.toString());
    }

    await _scanSub?.cancel();
    _seen.clear();
    _emitDevices();
    _scanSub = _central.watchAdvertisements().listen((advertisement) {
      final name = advertisement.name.trim();
      _seen[advertisement.id] = HeartRateDevice(
        id: advertisement.id,
        name: name.isEmpty ? 'Heart rate monitor' : name,
        kind: DeviceKind.ble,
        rssi: advertisement.rssi,
      );
      _emitDevices();
    });
    _scanning = true;
    try {
      await _central.startScan(serviceUuid: BleUuids.heartRateService);
    } catch (error) {
      _scanning = false;
      await _scanSub?.cancel();
      _scanSub = null;
      throw asAppFailure(error);
    }
  }

  @override
  Future<void> stopScan() async {
    if (!_scanning) {
      await _scanSub?.cancel();
      _scanSub = null;
      return;
    }
    _scanning = false;
    await _scanSub?.cancel();
    _scanSub = null;
    try {
      await _central.stopScan();
    } catch (error) {
      throw asAppFailure(error);
    }
  }

  @override
  Future<void> connect(HeartRateDevice device) async {
    await stopScan();
    _link.add(const LinkConnecting());
    try {
      final session = await _central.connect(device.id);
      _session = session;
      final notifications = await session.subscribeHeartRate(
        serviceUuid: BleUuids.heartRateService,
        measurementUuid: BleUuids.heartRateMeasurement,
      );
      await _valueSub?.cancel();
      _valueSub = notifications.values.listen((bytes) {
        try {
          _measurements.add(_parser.parse(bytes));
        } on FormatException catch (error) {
          _warnings.add(error.message);
        }
      });
      _link.add(const LinkLive());
    } catch (error) {
      final failure = asAppFailure(error);
      _link.add(LinkFailed(failure.message));
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _valueSub?.cancel();
    _valueSub = null;
    final session = _session;
    _session = null;
    if (session != null) {
      await session.disconnect();
    }
    _link.add(const LinkDisconnected());
  }

  @override
  Future<void> dispose() async {
    await _scanSub?.cancel();
    await _valueSub?.cancel();
    await disconnect();
    await _devices.close();
    await _link.close();
    await _measurements.close();
    await _warnings.close();
  }

  void _emitDevices() {
    if (_devices.isClosed) return;
    _devices.add(_seen.values.toList(growable: false));
  }

  String _radioMessage(RadioStatus radio) {
    switch (radio) {
      case RadioStatus.unknown:
        return 'Bluetooth is still starting.';
      case RadioStatus.on:
        return 'Bluetooth is on.';
      case RadioStatus.off:
        return 'Bluetooth is off. Turn it on to scan for a heart-rate strap.';
      case RadioStatus.unauthorized:
        return 'Bluetooth permission is missing. Allow it in system settings.';
      case RadioStatus.unsupported:
        return 'This device has no Bluetooth Low Energy radio. Use the simulator.';
    }
  }
}
