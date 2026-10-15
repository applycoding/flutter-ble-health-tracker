import 'dart:async';

import 'package:universal_ble/universal_ble.dart' hide BleCentral;

import '../../domain/failures/app_failure.dart';
import '../../domain/models/device_models.dart';
import '../../domain/ports.dart';

/// Adapter over `universal_ble`. Kept at the edge so tests can fake [BleCentral].
final class UniversalBleCentral implements BleCentral {
  @override
  Future<RadioStatus> currentRadio() async {
    try {
      return _mapRadio(await UniversalBle.getBluetoothAvailabilityState());
    } on UniversalBleException catch (error) {
      throw _mapBle(error);
    }
  }

  @override
  Stream<RadioStatus> watchRadio() async* {
    try {
      yield _mapRadio(await UniversalBle.getBluetoothAvailabilityState());
      yield* UniversalBle.availabilityStream.map(_mapRadio);
    } on UniversalBleException catch (error) {
      throw _mapBle(error);
    }
  }

  @override
  Future<void> requestPermissions() async {
    try {
      await UniversalBle.requestPermissions(withAndroidFineLocation: false);
    } on UniversalBleException catch (error) {
      throw _mapBle(error);
    }
  }

  @override
  Stream<BleAdvertisement> watchAdvertisements() {
    return UniversalBle.scanStream.map(
      (device) => BleAdvertisement(
        id: device.deviceId,
        name: device.name ?? '',
        rssi: device.rssi,
      ),
    );
  }

  @override
  Future<void> startScan({required String serviceUuid}) async {
    try {
      await UniversalBle.startScan(
        scanFilter: ScanFilter(withServices: [serviceUuid]),
        skipDuplicates: true,
      );
    } on UniversalBleException catch (error) {
      throw _mapBle(error);
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await UniversalBle.stopScan();
    } on UniversalBleException catch (error) {
      throw _mapBle(error);
    }
  }

  @override
  Future<BlePeripheralSession> connect(String deviceId) async {
    try {
      await UniversalBle.connect(
        deviceId,
        timeout: const Duration(seconds: 15),
      );
      return _UniversalSession(deviceId);
    } on UniversalBleException catch (error) {
      throw _mapBle(error);
    }
  }

  RadioStatus _mapRadio(AvailabilityState state) {
    switch (state) {
      case AvailabilityState.poweredOn:
        return RadioStatus.on;
      case AvailabilityState.poweredOff:
      case AvailabilityState.resetting:
        return RadioStatus.off;
      case AvailabilityState.unauthorized:
        return RadioStatus.unauthorized;
      case AvailabilityState.unsupported:
        return RadioStatus.unsupported;
      case AvailabilityState.unknown:
        return RadioStatus.unknown;
    }
  }
}

AppFailure _mapBle(UniversalBleException error) {
  switch (error.code) {
    case UniversalBleErrorCode.bluetoothNotEnabled:
    case UniversalBleErrorCode.bluetoothNotAvailable:
      return BluetoothOffFailure(error.message);
    case UniversalBleErrorCode.bluetoothNotAllowed:
    case UniversalBleErrorCode.bluetoothUnauthorized:
      return PermissionFailure(error.message);
    case UniversalBleErrorCode.serviceNotFound:
    case UniversalBleErrorCode.characteristicNotFound:
    case UniversalBleErrorCode.characteristicDoesNotSupportNotify:
    case UniversalBleErrorCode.characteristicDoesNotSupportIndicate:
    case UniversalBleErrorCode.operationNotSupported:
      return const HeartRateServiceMissing();
    case UniversalBleErrorCode.unknownError:
    case UniversalBleErrorCode.failed:
    case UniversalBleErrorCode.notSupported:
    case UniversalBleErrorCode.notImplemented:
    case UniversalBleErrorCode.channelError:
    case UniversalBleErrorCode.deviceDisconnected:
    case UniversalBleErrorCode.connectionTimeout:
    case UniversalBleErrorCode.connectionFailed:
    case UniversalBleErrorCode.connectionRejected:
    case UniversalBleErrorCode.connectionLimitExceeded:
    case UniversalBleErrorCode.connectionAlreadyExists:
    case UniversalBleErrorCode.connectionTerminated:
    case UniversalBleErrorCode.connectionInProgress:
    case UniversalBleErrorCode.illegalArgument:
    case UniversalBleErrorCode.deviceNotFound:
    case UniversalBleErrorCode.invalidServiceUuid:
    case UniversalBleErrorCode.invalidCharacteristicUuid:
    case UniversalBleErrorCode.invalidOffset:
    case UniversalBleErrorCode.invalidAttributeLength:
    case UniversalBleErrorCode.invalidPdu:
    case UniversalBleErrorCode.invalidHandle:
    case UniversalBleErrorCode.readFailed:
    case UniversalBleErrorCode.readNotPermitted:
    case UniversalBleErrorCode.writeFailed:
    case UniversalBleErrorCode.writeNotPermitted:
    case UniversalBleErrorCode.writeRequestBusy:
    case UniversalBleErrorCode.invalidAction:
    case UniversalBleErrorCode.operationTimeout:
    case UniversalBleErrorCode.operationCancelled:
    case UniversalBleErrorCode.operationInProgress:
    case UniversalBleErrorCode.characteristicDoesNotSupportRead:
    case UniversalBleErrorCode.characteristicDoesNotSupportWrite:
    case UniversalBleErrorCode.characteristicDoesNotSupportWriteWithoutResponse:
    case UniversalBleErrorCode.notPaired:
    case UniversalBleErrorCode.notPairable:
    case UniversalBleErrorCode.alreadyPaired:
    case UniversalBleErrorCode.pairingFailed:
    case UniversalBleErrorCode.pairingCancelled:
    case UniversalBleErrorCode.pairingTimeout:
    case UniversalBleErrorCode.pairingNotAllowed:
    case UniversalBleErrorCode.authenticationFailure:
    case UniversalBleErrorCode.insufficientAuthentication:
    case UniversalBleErrorCode.insufficientAuthorization:
    case UniversalBleErrorCode.insufficientEncryption:
    case UniversalBleErrorCode.insufficientKeySize:
    case UniversalBleErrorCode.protectionLevelNotMet:
    case UniversalBleErrorCode.accessDenied:
    case UniversalBleErrorCode.unpairingFailed:
    case UniversalBleErrorCode.alreadyUnpaired:
    case UniversalBleErrorCode.scanFailed:
    case UniversalBleErrorCode.stoppingScanInProgress:
    case UniversalBleErrorCode.webBluetoothGloballyDisabled:
      return ConnectionFailure(error.message);
  }
}

final class _UniversalSession implements BlePeripheralSession {
  _UniversalSession(this.deviceId);

  final String deviceId;

  @override
  Future<HeartRateNotifications> subscribeHeartRate({
    required String serviceUuid,
    required String measurementUuid,
  }) async {
    final device = BleDevice(deviceId: deviceId, name: null);
    final BleCharacteristic characteristic;
    try {
      characteristic = await device.getCharacteristic(
        measurementUuid,
        service: serviceUuid,
        preferCached: false,
      );
    } on UniversalBleException catch (error) {
      throw _mapBle(error);
    }

    final notifies = characteristic.properties.contains(
      CharacteristicProperty.notify,
    );
    final indicates = characteristic.properties.contains(
      CharacteristicProperty.indicate,
    );
    try {
      if (notifies) {
        await characteristic.notifications.subscribe();
      } else if (indicates) {
        await characteristic.indications.subscribe();
      } else {
        throw const HeartRateServiceMissing();
      }
    } on UniversalBleException catch (error) {
      throw _mapBle(error);
    } on HeartRateServiceMissing {
      rethrow;
    }

    return _UniversalNotifications(characteristic);
  }

  @override
  Future<void> disconnect() async {
    try {
      await UniversalBle.disconnect(deviceId);
    } on UniversalBleException catch (error) {
      throw _mapBle(error);
    }
  }
}

final class _UniversalNotifications implements HeartRateNotifications {
  _UniversalNotifications(this._characteristic);

  final BleCharacteristic _characteristic;

  @override
  Stream<List<int>> get values =>
      _characteristic.onValueReceived.map((bytes) => bytes.toList());

  @override
  Future<void> unsubscribe() => _characteristic.unsubscribe();
}
