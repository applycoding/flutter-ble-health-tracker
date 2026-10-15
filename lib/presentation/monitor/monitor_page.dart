import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/device_models.dart';
import '../../domain/models/sync_models.dart';
import '../../domain/parsing/heart_rate_zone.dart';
import '../theme/pulse_theme.dart';
import '../widgets/beating_heart.dart';
import '../widgets/bpm_chart.dart';
import 'monitor_controller.dart';

class MonitorPage extends ConsumerStatefulWidget {
  const MonitorPage({super.key});

  @override
  ConsumerState<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends ConsumerState<MonitorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monitorControllerProvider.notifier).start();
    });
  }

  Future<void> _leave() async {
    await ref.read(monitorControllerProvider.notifier).leave();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final monitor = ref.watch(monitorControllerProvider);
    final bpm = monitor.bpm;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(monitorControllerProvider.notifier).leave();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: AppFrame(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _leave,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Disconnect',
                    ),
                    Expanded(
                      child: Text(
                        monitor.device?.name ?? 'Monitor',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _LinkChip(status: monitor.link),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                  child: Column(
                    children: [
                      BeatingHeart(bpm: bpm),
                      const SizedBox(height: 8),
                      Semantics(
                        label: bpm == null
                            ? 'Heart rate unavailable'
                            : '$bpm beats per minute',
                        child: Text(
                          bpm?.toString() ?? '—',
                          key: const Key('bpm-value'),
                          style: const TextStyle(
                            fontFamily: 'IBM Plex Mono',
                            fontSize: 76,
                            fontWeight: FontWeight.w500,
                            height: 0.95,
                            letterSpacing: -3,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const Text(
                        'bpm',
                        style: TextStyle(
                          color: PulseColors.muted,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (monitor.zone != null)
                        _ZoneChip(zone: monitor.zone!)
                      else
                        const Text(
                          'Connecting',
                          style: TextStyle(color: PulseColors.muted),
                        ),
                    ],
                  ),
                ),
                if (monitor.link is LinkFailed) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    child: Text(
                      (monitor.link as LinkFailed).message,
                      key: const Key('link-error'),
                      style: const TextStyle(
                        color: PulseColors.amber,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                if (monitor.warning != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    monitor.warning!,
                    style: const TextStyle(color: PulseColors.amber),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Last minute',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Demo zones are fixed bands, not a training prescription.',
                  style: TextStyle(color: PulseColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                SectionCard(
                  padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
                  child: BpmChart(
                    bpms: [for (final sample in monitor.window) sample.bpm],
                  ),
                ),
                if (monitor.canChangeActivity) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Simulated effort',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ActivityProfile>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ActivityProfile.rest,
                        label: Text('Rest'),
                      ),
                      ButtonSegment(
                        value: ActivityProfile.walk,
                        label: Text('Walk'),
                      ),
                      ButtonSegment(
                        value: ActivityProfile.run,
                        label: Text('Run'),
                      ),
                    ],
                    selected: {monitor.activity},
                    onSelectionChanged: (selection) {
                      ref
                          .read(monitorControllerProvider.notifier)
                          .setActivity(selection.first);
                    },
                  ),
                ],
                const SizedBox(height: 18),
                _SyncFooter(monitor: monitor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.status});

  final LinkStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      LinkIdle() => ('Idle', PulseColors.muted),
      LinkConnecting() => ('Connecting', PulseColors.amber),
      LinkLive() => ('Live', PulseColors.mint),
      LinkDisconnected() => ('Disconnected', PulseColors.muted),
      LinkFailed() => ('Failed', PulseColors.heart),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        key: const Key('link-chip'),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({required this.zone});

  final HeartRateZone zone;

  @override
  Widget build(BuildContext context) {
    final color = zoneColor(zone);
    return Container(
      key: const Key('zone-label'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        zoneLabel(zone),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SyncFooter extends StatelessWidget {
  const _SyncFooter({required this.monitor});

  final MonitorState monitor;

  @override
  Widget build(BuildContext context) {
    final phase = switch (monitor.sync.phase) {
      SyncPhase.localOnly => 'On-device only',
      SyncPhase.offline => 'Offline',
      SyncPhase.syncing => 'Syncing',
      SyncPhase.synced => 'Synced',
      SyncPhase.failed => 'Sync failed',
    };
    final saved = monitor.savedCount == 1
        ? '1 reading saved'
        : '${monitor.savedCount} readings saved';
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(phase, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '$saved · ${monitor.sync.pending} waiting',
            key: const Key('sync-summary'),
            style: const TextStyle(color: PulseColors.muted),
          ),
          if (monitor.sync.detail != null) ...[
            const SizedBox(height: 6),
            Text(
              monitor.sync.detail!,
              style: const TextStyle(color: PulseColors.muted, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
