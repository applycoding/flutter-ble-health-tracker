import 'failures/app_failure.dart';
import 'models/device_models.dart';
import 'models/heart_rate_measurement.dart';
import 'models/heart_rate_reading.dart';

abstract interface class Clock {
  DateTime now();
}

abstract interface class ReadingIdFactory {
  String next();
}

abstract interface class NetworkStatus {
  Future<bool> get isOnline;

  Stream<bool> watch();
}

abstract interface class ReadingStore {
  Future<void> insert(HeartRateReading reading);

  Future<List<HeartRateReading>> recent({int limit = 200});

  Future<List<HeartRateReading>> pending({int limit = 400});

  Future<void> markSynced(Iterable<String> ids);

  Future<ReadingStats> stats();

  Stream<void> get changes;

  Future<void> close();
}

abstract interface class HeartRateRemote {
  bool get isConfigured;

  String get statusDetail;

  Future<void> push(List<HeartRateReading> readings);
}

/// A discovered advertisement, before the app decides to connect.
final class BleAdvertisement {
  const BleAdvertisement({required this.id, required this.name, this.rssi});

  final String id;
  final String name;
  final int? rssi;
}

abstract interface class HeartRateNotifications {
  Stream<List<int>> get values;

  Future<void> unsubscribe();
}

abstract interface class BlePeripheralSession {
  Future<HeartRateNotifications> subscribeHeartRate({
    required String serviceUuid,
    required String measurementUuid,
  });

  Future<void> disconnect();
}

/// Plugin-facing BLE central. The gateway depends on this, not on a package.
abstract interface class BleCentral {
  Future<RadioStatus> currentRadio();

  Stream<RadioStatus> watchRadio();

  Future<void> requestPermissions();

  Stream<BleAdvertisement> watchAdvertisements();

  Future<void> startScan({required String serviceUuid});

  Future<void> stopScan();

  Future<BlePeripheralSession> connect(String deviceId);
}

/// Either the phone radio or the in-app simulator.
abstract interface class HeartRateGateway {
  bool get canChangeActivity;

  Stream<RadioStatus> watchRadio();

  Stream<List<HeartRateDevice>> watchDevices();

  Stream<LinkStatus> watchLink();

  Stream<HeartRateMeasurement> watchMeasurements();

  Stream<String> watchWarnings();

  Future<void> startScan();

  Future<void> stopScan();

  Future<void> connect(HeartRateDevice device);

  Future<void> disconnect();

  void setActivity(ActivityProfile profile);

  Future<void> dispose();
}

/// Maps a plugin or parser error into an [AppFailure] the UI can render.
AppFailure asAppFailure(Object error) {
  if (error is AppFailure) return error;
  return ConnectionFailure(error.toString());
}
