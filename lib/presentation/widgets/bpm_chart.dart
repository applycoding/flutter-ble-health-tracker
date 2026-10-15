import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/pulse_theme.dart';

class BpmChart extends StatelessWidget {
  const BpmChart({required this.bpms, super.key});

  final List<int> bpms;

  @override
  Widget build(BuildContext context) {
    if (bpms.length < 2) {
      return const SizedBox(
        height: 156,
        child: Center(
          child: Text(
            'Waiting for the first few beats',
            style: TextStyle(color: PulseColors.muted),
          ),
        ),
      );
    }

    final minBpm = bpms.reduce(math.min).toDouble();
    final maxBpm = bpms.reduce(math.max).toDouble();
    var minY = (minBpm - 8).clamp(30, 210).toDouble();
    var maxY = (maxBpm + 8).clamp(40, 220).toDouble();
    if (maxY - minY < 24) {
      final mid = (minY + maxY) / 2;
      minY = mid - 12;
      maxY = mid + 12;
    }
    final spots = [
      for (var i = 0; i < bpms.length; i++)
        FlSpot(i.toDouble(), bpms[i].toDouble()),
    ];

    return SizedBox(
      height: 156,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          minX: 0,
          maxX: (bpms.length - 1).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: PulseColors.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 10,
                getTitlesWidget: (value, meta) {
                  if (value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: PulseColors.muted,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: PulseColors.heart,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PulseColors.heart.withValues(alpha: 0.35),
                    PulseColors.heart.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
