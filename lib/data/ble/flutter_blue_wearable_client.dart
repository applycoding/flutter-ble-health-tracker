import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../domain/models.dart';
import '../../domain/ports.dart';
import 'ble_uuids.dart';
import 'heart_rate_parser.dart';

/// Live adapter for the standard Heart Rate Service (0x180D / measurement 0x2A37).
class FlutterBlueWearableClient implements WearableClient {
  final _status = StreamController<WearableStatus>.broadcast();
  final _samples = StreamController<HeartRateSample>.broadcast();
  final _scans = StreamController<List<DiscoveredWearable>>.broadcast();
  final _known = <String, BluetoothDevice>{};

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _valueSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  BluetoothDevice? _connected;
  var _stopped = true;
  var _platformTouched = false;

  @override
  Stream<WearableStatus> get status => _status.stream;

  @override
  Stream<List<DiscoveredWearable>> get scanResults => _scans.stream;

  @override
  Stream<HeartRateSample> get samples => _samples.stream;

  @override
  Future<void> start() async {
    _stopped = false;
    _platformTouched = true;
    try {
      await FlutterBluePlus.setLogLevel(LogLevel.none);
      final supported = await FlutterBluePlus.isSupported;
      if (!supported) {
        _emit(
          const WearableStatus(
            phase: WearablePhase.error,
            message: 'No Bluetooth adapter. Demo mode still runs the simulated strap.',
          ),
        );
        return;
      }
      final adapter = await FlutterBluePlus.adapterState.first;
      if (adapter != BluetoothAdapterState.on) {
        _emit(
          WearableStatus(
            phase: WearablePhase.error,
            message: 'Bluetooth is ${adapter.name}. Turn it on to scan.',
          ),
        );
        return;
      }
      await _scan();
    } catch (error) {
      _emit(WearableStatus(phase: WearablePhase.error, message: _bleMessage(error)));
    }
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    if (!_platformTouched) {
      _emit(
        const WearableStatus(
          phase: WearablePhase.stopped,
          message: 'Bluetooth link stopped.',
        ),
      );
      return;
    }
    await _valueSub?.cancel();
    _valueSub = null;
    await _connectionSub?.cancel();
    _connectionSub = null;
    await _scanSub?.cancel();
    _scanSub = null;
    await _quietly(() => FlutterBluePlus.stopScan());
    final connected = _connected;
    _connected = null;
    if (connected != null) {
      await _quietly(connected.disconnect);
    }
    _emit(
      const WearableStatus(
        phase: WearablePhase.stopped,
        message: 'Bluetooth link stopped.',
      ),
    );
  }

  @override
  Future<void> connect(DiscoveredWearable wearable) async {
    final device = _known[wearable.id];
    if (device == null) {
      _emit(
        const WearableStatus(
          phase: WearablePhase.error,
          message: 'That scan result expired. Scan again.',
        ),
      );
      return;
    }
    try {
      _emit(
        WearableStatus(
          phase: WearablePhase.connecting,
          deviceName: wearable.name,
          message: 'Connecting to ${wearable.name}.',
        ),
      );
      await FlutterBluePlus.stopScan();
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
      );
      if (_stopped) {
        await device.disconnect();
        return;
      }
      _connected = device;
      var sawConnected = false;
      _connectionSub = device.connectionState.listen((connection) {
        if (connection == BluetoothConnectionState.connected) {
          sawConnected = true;
          return;
        }
        if (sawConnected && identical(_connected, device)) {
          _connected = null;
          _emit(
            WearableStatus(
              phase: WearablePhase.error,
              deviceName: wearable.name,
              message: '${wearable.name} disconnected.',
            ),
          );
        }
      });

      final services = await device.discoverServices();
      final service = _service(services);
      if (service == null) {
        _emit(
          WearableStatus(
            phase: WearablePhase.error,
            deviceName: wearable.name,
            message: 'Heart Rate Service 0x180D was not found on ${wearable.name}.',
          ),
        );
        await device.disconnect();
        return;
      }
      final characteristic = _measurement(service);
      if (characteristic == null) {
        _emit(
          WearableStatus(
            phase: WearablePhase.error,
            deviceName: wearable.name,
            message: 'Heart Rate Measurement 0x2A37 was not found.',
          ),
        );
        await device.disconnect();
        return;
      }
      final properties = characteristic.properties;
      if (!properties.notify && !properties.indicate) {
        _emit(
          WearableStatus(
            phase: WearablePhase.error,
            deviceName: wearable.name,
            message: '0x2A37 does not notify or indicate.',
          ),
        );
        return;
      }
      await characteristic.setNotifyValue(
        true,
        forceIndications: properties.indicate && !properties.notify,
      );
      await _valueSub?.cancel();
      _valueSub = characteristic.onValueReceived.listen(
        (value) => _onMeasurement(value, wearable),
      );
      _emit(
        WearableStatus(
          phase: WearablePhase.streaming,
          deviceName: wearable.name,
          message: 'Subscribed to Heart Rate Measurement 0x2A37.',
        ),
      );
    } catch (error) {
      _emit(
        WearableStatus(
          phase: WearablePhase.error,
          deviceName: wearable.name,
          message: _bleMessage(error),
        ),
      );
    }
  }

  Future<void> _scan() async {
    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen(_onScan);
    _emit(
      const WearableStatus(
        phase: WearablePhase.scanning,
        message: 'Scanning for Heart Rate Service 0x180D.',
      ),
    );
    await FlutterBluePlus.startScan(
      withServices: [BleUuids.heartRateService],
      timeout: const Duration(seconds: 8),
    );
  }

  void _onScan(List<ScanResult> results) {
    final found = <DiscoveredWearable>[];
    for (final result in results) {
      final id = result.device.remoteId.str;
      _known[id] = result.device;
      final advertised = result.advertisementData.advName;
      final platformName = result.device.platformName;
      final name = advertised.isNotEmpty
          ? advertised
          : platformName.isNotEmpty
              ? platformName
              : 'Heart rate monitor';
      found.add(DiscoveredWearable(id: id, name: name, rssi: result.rssi));
    }
    if (!_scans.isClosed) _scans.add(found);
  }

  void _onMeasurement(List<int> value, DiscoveredWearable wearable) {
    try {
      final measurement = parseHeartRateMeasurement(value);
      if (_samples.isClosed) return;
      _samples.add(
        HeartRateSample(
          bpm: measurement.bpm,
          recordedAt: DateTime.now(),
          deviceId: wearable.id,
          deviceName: wearable.name,
          source: ReadingSource.ble,
          energyExpendedKj: measurement.energyExpendedKj,
          rrIntervalsMs: measurement.rrIntervalsMs,
          sensorContactSupported: measurement.sensorContactSupported,
          sensorContactDetected: measurement.sensorContactDetected,
        ),
      );
    } on FormatException {
      _emit(
        WearableStatus(
          phase: WearablePhase.streaming,
          deviceName: wearable.name,
          message: 'Ignored a malformed heart-rate packet.',
        ),
      );
    }
  }

  BluetoothService? _service(List<BluetoothService> services) {
    for (final service in services) {
      if (service.uuid == BleUuids.heartRateService) return service;
    }
    return null;
  }

  BluetoothCharacteristic? _measurement(BluetoothService service) {
    for (final characteristic in service.characteristics) {
      if (characteristic.uuid == BleUuids.heartRateMeasurement) return characteristic;
    }
    return null;
  }

  void _emit(WearableStatus status) {
    if (!_status.isClosed) _status.add(status);
  }

  String _bleMessage(Object error) {
    if (error is FlutterBluePlusException) {
      final description = error.description;
      if (description != null && description.isNotEmpty) return description;
      return 'Bluetooth ${error.function} failed.';
    }
    return 'Bluetooth is unavailable on this host. Demo mode does not need a radio.';
  }

  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('BLE cleanup: $error');
    }
  }
}
