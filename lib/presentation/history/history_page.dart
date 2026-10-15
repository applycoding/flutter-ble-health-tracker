import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../theme/app_theme.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(readingsProvider).value ?? const <HeartRateReading>[];
    return HistoryBody(readings: readings, now: DateTime.now());
  }
}

class HistoryBody extends StatefulWidget {
  const HistoryBody({required this.readings, required this.now, super.key});

  final List<HeartRateReading> readings;
  final DateTime now;

  @override
  State<HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<HistoryBody> {
  var _pendingOnly = false;

  @override
  Widget build(BuildContext context) {
    final visible = _pendingOnly
        ? widget.readings.where((reading) => !reading.synced).toList(growable: false)
        : widget.readings;
    final groups = groupReadingsByDay(visible);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          key: const Key('history-list'),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const Text(
              'SESSION LOG',
              style: TextStyle(
                color: PulseColors.paperMuted,
                fontSize: 12,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Stored on this device',
              style: TextStyle(fontFamily: 'Fraunces', fontSize: 36, fontWeight: FontWeight.w600, height: 1.05),
            ),
            const SizedBox(height: 8),
            const Text(
              'Newest beats first. Queued rows have not reached the sync target yet.',
              style: TextStyle(color: PulseColors.paperMuted, height: 1.35),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Pending only'),
                selected: _pendingOnly,
                onSelected: (value) => setState(() => _pendingOnly = value),
              ),
            ),
            const SizedBox(height: 12),
            if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'No beats stored yet.',
                  key: Key('history-empty'),
                  style: TextStyle(color: PulseColors.paperMuted),
                ),
              )
            else
              for (final group in groups) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Text(
                    formatDayLabel(group.day, widget.now),
                    style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
                  ),
                ),
                for (final reading in group.readings) _ReadingTile(reading: reading),
              ],
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
    final synced = reading.synced;
    return Card(
      key: ValueKey('reading-${reading.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              synced ? Icons.cloud_done_outlined : Icons.cloud_queue,
              color: synced ? PulseColors.moss : PulseColors.amber,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatClock(reading.recordedAt), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${reading.deviceName} · ${reading.source.label} · ${synced ? 'Synced' : 'Queued'}',
                    style: const TextStyle(color: PulseColors.paperMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              '${reading.bpm}',
              style: const TextStyle(fontFamily: 'Fraunces', fontSize: 28, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
