import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/system_services.dart';
import '../data/ble/bluetooth_heart_rate_gateway.dart';
import '../data/ble/universal_ble_central.dart';
import '../data/simulator/simulated_heart_rate_gateway.dart';
import '../domain/models/device_models.dart';
import '../domain/parsing/heart_rate_measurement_parser.dart';
import '../domain/ports.dart';
import '../domain/repositories/heart_rate_repository.dart';

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final heartRateRepositoryProvider = Provider<HeartRateRepository>((ref) {
  throw StateError(
    'HeartRateRepository is created during startup and overridden.',
  );
});

final parserProvider = Provider<HeartRateMeasurementParser>(
  (ref) => const HeartRateMeasurementParser(),
);

final simulatedGatewayProvider = Provider<HeartRateGateway>((ref) {
  final gateway = SimulatedHeartRateGateway();
  ref.onDispose(() {
    gateway.dispose();
  });
  return gateway;
});

final bluetoothGatewayProvider = Provider<HeartRateGateway>((ref) {
  final gateway = BluetoothHeartRateGateway(
    central: UniversalBleCentral(),
    parser: ref.watch(parserProvider),
  );
  ref.onDispose(() {
    gateway.dispose();
  });
  return gateway;
});

final transportProvider = NotifierProvider<TransportController, Transport>(
  TransportController.new,
);

final selectedDeviceProvider =
    NotifierProvider<SelectedDeviceController, HeartRateDevice?>(
      SelectedDeviceController.new,
    );

final activeGatewayProvider = Provider<HeartRateGateway>((ref) {
  final transport = ref.watch(transportProvider);
  switch (transport) {
    case Transport.simulator:
      return ref.watch(simulatedGatewayProvider);
    case Transport.bluetooth:
      return ref.watch(bluetoothGatewayProvider);
  }
});

final class TransportController extends Notifier<Transport> {
  @override
  Transport build() => Transport.simulator;

  void select(Transport transport) {
    state = transport;
  }
}

final class SelectedDeviceController extends Notifier<HeartRateDevice?> {
  @override
  HeartRateDevice? build() => null;

  void select(HeartRateDevice device) => state = device;
}
