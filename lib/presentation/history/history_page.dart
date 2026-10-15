import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/heart_rate_reading.dart';
import '../../domain/models/sync_models.dart';
import '../theme/pulse_theme.dart';
import 'history_controller.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: AppFrame(
          child: history.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                        ),
                        const Text(
                          'History',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _StatsRow(stats: history.stats),
                    const SizedBox(height: 12),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusLine(history),
                            key: const Key('history-status'),
                            style: const TextStyle(height: 1.35),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            key: const Key('sync-button'),
                            onPressed: history.syncing
                                ? null
                                : () => ref
                                      .read(historyControllerProvider.notifier)
                                      .sync(),
                            child: Text(
                              history.syncing ? 'Syncing' : 'Sync now',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (history.recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 28),
                        child: Text(
                          'No readings yet. Connect the simulator or a heart-rate '
                          'strap. Samples are written to SQLite on this device '
                          'about once a second.',
                          key: Key('history-empty'),
                          style: TextStyle(
                            color: PulseColors.muted,
                            height: 1.4,
                          ),
                        ),
                      )
                    else
                      ..._grouped(history.recent),
                  ],
                ),
        ),
      ),
    );
  }

  String _statusLine(HistoryState history) {
    if (history.syncing) return 'Syncing queued readings…';
    final detail = history.sync.detail;
    switch (history.sync.phase) {
      case SyncPhase.failed:
        return detail ?? 'Sync failed. Readings are still on this device.';
      case SyncPhase.offline:
        return detail ?? 'Offline. Readings stay on this device.';
      case SyncPhase.localOnly:
        return detail ?? 'On-device only. Firebase is not configured.';
      case SyncPhase.syncing:
      case SyncPhase.synced:
        if (history.stats.pending > 0) {
          return '${history.stats.pending} waiting to sync.';
        }
        return detail ?? 'Nothing waiting to sync.';
    }
  }

  List<Widget> _grouped(List<HeartRateReading> readings) {
    final groups = <String, List<HeartRateReading>>{};
    for (final reading in readings) {
      final label = _dayLabel(reading.recordedAt.toLocal());
      groups.putIfAbsent(label, () => []).add(reading);
    }
    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            entry.key,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
      for (final reading in entry.value) {
        widgets.add(_ReadingTile(reading: reading));
        widgets.add(const SizedBox(height: 8));
      }
    }
    return widgets;
  }

  String _dayLabel(DateTime local) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d').format(local);
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final ReadingStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(label: 'Avg', value: _fmt(stats.averageBpm)),
        const SizedBox(width: 8),
        _Stat(label: 'Min', value: _fmt(stats.minBpm)),
        const SizedBox(width: 8),
        _Stat(label: 'Max', value: _fmt(stats.maxBpm)),
      ],
    );
  }

  String _fmt(int? value) => value?.toString() ?? '—';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: PulseColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.reading});

  final HeartRateReading reading;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss').format(reading.recordedAt.toLocal());
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(
            '${reading.bpm}',
            style: const TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          const Text('bpm', style: TextStyle(color: PulseColors.muted)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: const TextStyle(color: PulseColors.muted)),
              Text(
                reading.synced ? 'Synced' : 'On device',
                style: TextStyle(
                  color: reading.synced ? PulseColors.mint : PulseColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
