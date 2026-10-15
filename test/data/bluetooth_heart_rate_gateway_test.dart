import 'package:flutter_test/flutter_test.dart';
import 'package:pulsekeep/data/ble/bluetooth_heart_rate_gateway.dart';
import 'package:pulsekeep/domain/failures/app_failure.dart';
import 'package:pulsekeep/domain/models/device_models.dart';
import 'package:pulsekeep/domain/parsing/heart_rate_measurement_parser.dart';
import 'package:pulsekeep/domain/ports.dart';

import '../support/fakes.dart';

void main() {
  test('refuses to scan while the radio is off', () async {
    final central = FakeBleCentral(radio: RadioStatus.off);
    final gateway = _gateway(central);

    await expectLater(gateway.startScan(), throwsA(isA<BluetoothOffFailure>()));
    expect(central.scanStarts, 0);
    await gateway.dispose();
  });

  test('collects advertisements for the heart-rate service', () async {
    final central = FakeBleCentral();
    final gateway = _gateway(central);
    final seen = <List<HeartRateDevice>>[];
    final sub = gateway.watchDevices().listen(seen.add);

    await gateway.startScan();
    central.advertisements.add(
      const BleAdvertisement(id: 'aa:bb', name: 'Polar H10', rssi: -67),
    );
    await Future<void>.delayed(Duration.zero);

    expect(central.scanStarts, 1);
    expect(central.permissionRequests, 1);
    expect(seen.last.single.name, 'Polar H10');
    expect(seen.last.single.kind, DeviceKind.ble);
    await sub.cancel();
    await gateway.dispose();
  });

  test('parses heart-rate notifications after connect', () async {
    final central = FakeBleCentral();
    final peripheral = FakePeripheral(
      packets: const [
        [0x00, 72],
      ],
    );
    central.peripherals['aa'] = peripheral;
    final gateway = _gateway(central);
    final bpms = <int>[];
    final sub = gateway.watchMeasurements().listen((m) => bpms.add(m.bpm));

    await gateway.connect(
      const HeartRateDevice(id: 'aa', name: 'Strap', kind: DeviceKind.ble),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bpms, [72]);
    await sub.cancel();
    await gateway.dispose();
    expect(peripheral.disconnected, isTrue);
  });

  test('reports a missing heart-rate characteristic', () async {
    final central = FakeBleCentral();
    central.peripherals['aa'] = FakePeripheral(missingService: true);
    final gateway = _gateway(central);
    final links = <LinkStatus>[];
    final sub = gateway.watchLink().listen(links.add);

    await expectLater(
      gateway.connect(
        const HeartRateDevice(id: 'aa', name: 'Strap', kind: DeviceKind.ble),
      ),
      throwsA(isA<HeartRateServiceMissing>()),
    );
    expect(links.whereType<LinkFailed>(), isNotEmpty);
    await sub.cancel();
    await gateway.dispose();
  });

  test('surfaces a malformed packet without dropping the link', () async {
    final central = FakeBleCentral();
    final peripheral = FakePeripheral();
    central.peripherals['aa'] = peripheral;
    final gateway = _gateway(central);
    final warnings = <String>[];
    final bpms = <int>[];
    final warningSub = gateway.watchWarnings().listen(warnings.add);
    final valueSub = gateway.watchMeasurements().listen((m) => bpms.add(m.bpm));

    await gateway.connect(
      const HeartRateDevice(id: 'aa', name: 'Strap', kind: DeviceKind.ble),
    );
    peripheral.emit(const []);
    peripheral.emit(const [0x00, 64]);
    await Future<void>.delayed(Duration.zero);

    expect(warnings, isNotEmpty);
    expect(bpms, [64]);
    await warningSub.cancel();
    await valueSub.cancel();
    await gateway.dispose();
  });
}

BluetoothHeartRateGateway _gateway(FakeBleCentral central) {
  return BluetoothHeartRateGateway(
    central: central,
    parser: const HeartRateMeasurementParser(),
  );
}
