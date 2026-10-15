import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/failures/app_failure.dart';
import '../../domain/models/device_models.dart';
import '../../domain/ports.dart';
import '../providers.dart';

final scanControllerProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);

final class ScanState {
  const ScanState({
    required this.transport,
    required this.scanning,
    required this.devices,
    required this.radio,
    this.error,
  });

  final Transport transport;
  final bool scanning;
  final List<HeartRateDevice> devices;
  final RadioStatus radio;
  final String? error;

  ScanState copyWith({
    Transport? transport,
    bool? scanning,
    List<HeartRateDevice>? devices,
    RadioStatus? radio,
    String? error,
    bool clearError = false,
  }) {
    return ScanState(
      transport: transport ?? this.transport,
      scanning: scanning ?? this.scanning,
      devices: devices ?? this.devices,
      radio: radio ?? this.radio,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final class ScanController extends Notifier<ScanState> {
  StreamSubscription<List<HeartRateDevice>>? _devicesSub;
  StreamSubscription<RadioStatus>? _radioSub;
  Timer? _timeout;

  @override
  ScanState build() {
    final transport = ref.watch(transportProvider);
    final gateway = ref.watch(activeGatewayProvider);
    ref.onDispose(() {
      _timeout?.cancel();
      _devicesSub?.cancel();
      _radioSub?.cancel();
      unawaited(gateway.stopScan());
    });
    _bind(gateway);
    return ScanState(
      transport: transport,
      scanning: false,
      radio: RadioStatus.unknown,
      devices: const [],
    );
  }

  void _bind(HeartRateGateway gateway) {
    _devicesSub?.cancel();
    _radioSub?.cancel();
    _devicesSub = gateway.watchDevices().listen((devices) {
      state = state.copyWith(devices: devices, clearError: true);
    });
    _radioSub = gateway.watchRadio().listen((radio) {
      state = state.copyWith(radio: radio);
    });
  }

  Future<void> scan() async {
    final gateway = ref.read(activeGatewayProvider);
    state = state.copyWith(scanning: true, clearError: true, devices: const []);
    try {
      await gateway.startScan();
      _timeout?.cancel();
      _timeout = Timer(const Duration(seconds: 12), () async {
        await stop();
        if (state.devices.isEmpty) {
          state = state.copyWith(
            error:
                'No monitors advertised Heart Rate Service 0x180D. '
                'Many chest straps do. The simulator always works.',
          );
        }
      });
      if (ref.read(transportProvider) == Transport.simulator) {
        state = state.copyWith(scanning: false);
      }
    } on AppFailure catch (error) {
      state = state.copyWith(scanning: false, error: error.message);
    }
  }

  Future<void> stop() async {
    _timeout?.cancel();
    state = state.copyWith(scanning: false);
    await ref.read(activeGatewayProvider).stopScan();
  }
}
