import 'package:flutter/material.dart';

import '../../application/monitor_state.dart';
import '../format.dart';
import '../theme/app_theme.dart';

class BpmReadout extends StatelessWidget {
  const BpmReadout({required this.state, super.key});

  final MonitorState state;

  @override
  Widget build(BuildContext context) {
    final bpm = state.bpm;
    final stats = state.stats;
    return Semantics(
      label: bpm == null ? 'No heart rate yet' : '$bpm beats per minute',
      child: Column(
        key: const Key('bpm-readout'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: phaseColor(state.phase),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                phaseLabel(state.phase).toUpperCase(),
                style: TextStyle(
                  color: phaseColor(state.phase),
                  fontSize: 12,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(width: 42, height: 3, color: PulseColors.signal),
          const SizedBox(height: 12),
          Text(
            formatBpm(bpm),
            key: const Key('bpm-value'),
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 92,
              height: 0.9,
              fontWeight: FontWeight.w600,
              letterSpacing: -2,
            ),
          ),
          const Text(
            'bpm',
            style: TextStyle(color: PulseColors.paperMuted, fontSize: 16, letterSpacing: 0.4),
          ),
          const SizedBox(height: 18),
          Text(state.deviceName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(state.statusMessage, style: const TextStyle(color: PulseColors.paperMuted, height: 1.35)),
          const SizedBox(height: 22),
          Row(
            children: [
              _Stat(label: 'Min', value: formatBpm(stats.min)),
              _Stat(label: 'Avg', value: formatBpm(stats.average)),
              _Stat(label: 'Max', value: formatBpm(stats.max)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: PulseColors.paperMuted, fontSize: 11, letterSpacing: 1.1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontFamily: 'Fraunces', fontSize: 22, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
