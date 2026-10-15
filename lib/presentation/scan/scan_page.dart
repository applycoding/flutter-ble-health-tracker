import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/device_models.dart';
import '../app.dart';
import '../providers.dart';
import '../theme/pulse_theme.dart';
import 'scan_controller.dart';

class ScanPage extends ConsumerWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: AppFrame(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PulseKeep',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Heart rate, on device first',
                          style: TextStyle(color: PulseColors.muted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: const Key('history-button'),
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed(PulseKeepApp.historyRoute);
                    },
                    child: const Text('History'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio demo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Not a medical device. The simulator runs with no hardware '
                      'and no Firebase project. Readings are saved on this phone '
                      'first, then synced only if you add Firebase config.',
                      style: TextStyle(color: PulseColors.muted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SegmentedButton<Transport>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: Transport.simulator,
                    label: Text('Simulator'),
                    icon: Icon(Icons.monitor_heart_outlined),
                  ),
                  ButtonSegment(
                    value: Transport.bluetooth,
                    label: Text('Bluetooth'),
                    icon: Icon(Icons.bluetooth),
                  ),
                ],
                selected: {scan.transport},
                onSelectionChanged: (selection) async {
                  final next = selection.first;
                  if (next == ref.read(transportProvider)) return;
                  await ref.read(activeGatewayProvider).disconnect();
                  ref.read(transportProvider.notifier).select(next);
                },
              ),
              const SizedBox(height: 18),
              if (scan.transport == Transport.bluetooth) ...[
                _RadioLine(radio: scan.radio),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('scan-button'),
                  onPressed: scan.scanning
                      ? null
                      : () => ref.read(scanControllerProvider.notifier).scan(),
                  icon: scan.scanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.radar),
                  label: Text(scan.scanning ? 'Scanning' : 'Scan for 0x180D'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Looks for peripherals advertising the standard Heart Rate Service. '
                  'A phone will not show up unless it is acting as that peripheral.',
                  style: TextStyle(color: PulseColors.muted, height: 1.35),
                ),
              ],
              if (scan.error != null) ...[
                const SizedBox(height: 12),
                SectionCard(
                  child: Text(
                    scan.error!,
                    key: const Key('scan-error'),
                    style: const TextStyle(
                      color: PulseColors.amber,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (scan.devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'No monitors yet',
                      style: TextStyle(color: PulseColors.muted),
                    ),
                  ),
                )
              else
                for (final device in scan.devices) ...[
                  _DeviceTile(device: device),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioLine extends StatelessWidget {
  const _RadioLine({required this.radio});

  final RadioStatus radio;

  @override
  Widget build(BuildContext context) {
    final label = switch (radio) {
      RadioStatus.unknown => 'Checking the radio…',
      RadioStatus.on => 'Bluetooth is on',
      RadioStatus.off => 'Bluetooth is off',
      RadioStatus.unauthorized => 'Bluetooth permission needed',
      RadioStatus.unsupported => 'No BLE radio on this device',
    };
    final color = switch (radio) {
      RadioStatus.on => PulseColors.mint,
      RadioStatus.off ||
      RadioStatus.unauthorized ||
      RadioStatus.unsupported => PulseColors.amber,
      RadioStatus.unknown => PulseColors.muted,
    };
    return Text(label, style: TextStyle(color: color));
  }
}

class _DeviceTile extends ConsumerWidget {
  const _DeviceTile({required this.device});

  final HeartRateDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = switch (device.kind) {
      DeviceKind.simulator => 'Simulated · no radio required',
      DeviceKind.ble =>
        device.rssi == null ? device.id : '${device.rssi} dBm · ${device.id}',
    };
    return SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: PulseColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            key: Key('connect-${device.id}'),
            onPressed: () {
              ref.read(selectedDeviceProvider.notifier).select(device);
              Navigator.of(context).pushNamed(PulseKeepApp.monitorRoute);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
