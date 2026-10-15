import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/monitor_controller.dart';
import '../../application/monitor_state.dart';
import '../../domain/models.dart';
import '../theme/app_theme.dart';
import '../widgets/bpm_chart.dart';
import '../widgets/bpm_readout.dart';

class MonitorPage extends ConsumerWidget {
  const MonitorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitorProvider);
    final controller = ref.read(monitorProvider.notifier);
    return MonitorBody(
      state: state,
      onDemoMode: (demo) {
        unawaited(controller.setDemoMode(demo));
      },
      onOnline: controller.setOnline,
      onSync: controller.syncNow,
      onStreaming: (streaming) {
        unawaited(controller.setStreaming(streaming));
      },
      onScan: controller.scanAgain,
      onConnect: (device) {
        unawaited(controller.connect(device));
      },
    );
  }
}

class MonitorBody extends StatelessWidget {
  const MonitorBody({
    required this.state,
    required this.onDemoMode,
    required this.onOnline,
    required this.onSync,
    required this.onStreaming,
    required this.onScan,
    required this.onConnect,
    super.key,
  });

  final MonitorState state;
  final ValueChanged<bool> onDemoMode;
  final ValueChanged<bool> onOnline;
  final Future<void> Function() onSync;
  final ValueChanged<bool> onStreaming;
  final Future<void> Function() onScan;
  final ValueChanged<DiscoveredWearable> onConnect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;
        final trace = state.trace;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                _Header(state: state, onDemoMode: onDemoMode, stacked: stacked),
                const SizedBox(height: 18),
                if (stacked) ...[
                  _card(BpmReadout(state: state)),
                  const SizedBox(height: 14),
                  _card(_TraceCard(count: trace.length, points: trace)),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _card(BpmReadout(state: state))),
                      const SizedBox(width: 14),
                      Expanded(flex: 7, child: _card(_TraceCard(count: trace.length, points: trace))),
                    ],
                  ),
                const SizedBox(height: 14),
                _card(_SyncCard(
                  state: state,
                  onOnline: onOnline,
                  onSync: onSync,
                  onStreaming: onStreaming,
                )),
                if (!state.demoMode) ...[
                  const SizedBox(height: 14),
                  _card(_DeviceCard(state: state, onScan: onScan, onConnect: onConnect)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _card(Widget child) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.onDemoMode, required this.stacked});

  final MonitorState state;
  final ValueChanged<bool> onDemoMode;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PULSE LEDGER',
          style: TextStyle(
            color: PulseColors.paperMuted,
            fontSize: 12,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Heart rate',
          style: TextStyle(fontFamily: 'Fraunces', fontSize: 36, fontWeight: FontWeight.w600, height: 1.05),
        ),
        const SizedBox(height: 6),
        Text(
          state.firebaseConfigured
              ? 'Offline-first log. Sync target is Firestore.'
              : 'Offline-first log. Sync target is the mock cloud.',
          style: const TextStyle(color: PulseColors.paperMuted),
        ),
      ],
    );
    final toggle = SegmentedButton<bool>(
      key: const Key('mode-toggle'),
      showSelectedIcon: false,
      segments: [
        ButtonSegment<bool>(
          value: true,
          label: const Text('Demo strap'),
          icon: stacked ? null : const Icon(Icons.monitor_heart_outlined),
        ),
        ButtonSegment<bool>(
          value: false,
          label: const Text('Live BLE'),
          icon: stacked ? null : const Icon(Icons.bluetooth),
        ),
      ],
      selected: {state.demoMode},
      onSelectionChanged: (selection) => onDemoMode(selection.first),
    );
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 14), toggle],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [Expanded(child: title), const SizedBox(width: 16), toggle],
    );
  }
}

class _TraceCard extends StatelessWidget {
  const _TraceCard({required this.count, required this.points});

  final int count;
  final List<HeartRateReading> points;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Live trace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            Text(
              count == 1 ? '1 beat' : '$count beats',
              style: const TextStyle(color: PulseColors.paperMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Latest stored beats',
          style: TextStyle(color: PulseColors.paperMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        BpmChart(points: points),
      ],
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.state,
    required this.onOnline,
    required this.onSync,
    required this.onStreaming,
  });

  final MonitorState state;
  final ValueChanged<bool> onOnline;
  final Future<void> Function() onSync;
  final ValueChanged<bool> onStreaming;

  @override
  Widget build(BuildContext context) {
    final pending = state.pendingCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 18,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Network', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Switch(
                  key: const Key('online-switch'),
                  value: state.online,
                  onChanged: onOnline,
                ),
                Text(state.online ? 'Online' : 'Offline', style: const TextStyle(color: PulseColors.paperMuted)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SYNC TARGET', style: TextStyle(color: PulseColors.paperMuted, fontSize: 11, letterSpacing: 1.1)),
                const SizedBox(height: 2),
                Text(state.syncTarget, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            FilledButton.icon(
              key: const Key('sync-button'),
              onPressed: state.syncing
                  ? null
                  : () {
                      unawaited(onSync());
                    },
              icon: state.syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(state.syncing ? 'Syncing' : 'Sync now'),
            ),
            if (state.demoMode)
              OutlinedButton(
                key: const Key('stream-toggle'),
                onPressed: () => onStreaming(state.phase != WearablePhase.streaming),
                child: Text(state.phase == WearablePhase.streaming ? 'Pause strap' : 'Resume strap'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          pending == 1 ? '1 reading waiting to sync' : '$pending readings waiting to sync',
          key: const Key('pending-count'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          state.syncMessage,
          key: const Key('sync-message'),
          style: TextStyle(color: outcomeColor(state.syncOutcome), height: 1.35),
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.state, required this.onScan, required this.onConnect});

  final MonitorState state;
  final Future<void> Function() onScan;
  final ValueChanged<DiscoveredWearable> onConnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Nearby monitors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            OutlinedButton(
              key: const Key('scan-button'),
              onPressed: () {
                unawaited(onScan());
              },
              child: const Text('Scan again'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Filtered to the Heart Rate Service, UUID 0x180D.',
          style: TextStyle(color: PulseColors.paperMuted),
        ),
        const SizedBox(height: 8),
        if (state.discovered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No monitors advertising 0x180D yet.',
              key: Key('scan-empty'),
            ),
          )
        else
          for (final device in state.discovered)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(device.name),
              subtitle: Text(device.rssi == null ? device.id : '${device.id} · ${device.rssi} dBm'),
              trailing: FilledButton(
                onPressed: () => onConnect(device),
                child: const Text('Connect'),
              ),
            ),
      ],
    );
  }
}
