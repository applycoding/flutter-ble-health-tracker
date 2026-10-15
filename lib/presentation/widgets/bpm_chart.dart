import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme/app_theme.dart';

class BpmChart extends StatelessWidget {
  const BpmChart({required this.points, super.key});

  /// Chronological, oldest first.
  final List<HeartRateReading> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'The trace starts with the next beat.',
            style: TextStyle(color: PulseColors.paperMuted),
          ),
        ),
      );
    }

    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].bpm.toDouble()),
    ];
    final values = spots.map((spot) => spot.y);
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    if (maxY - minY < 16) {
      final mid = (maxY + minY) / 2;
      minY = mid - 8;
      maxY = mid + 8;
    } else {
      minY -= 4;
      maxY += 4;
    }
    final yInterval = _yInterval(maxY - minY);
    final step = points.length <= 4 ? 1 : (points.length / 4).ceil();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: points.length == 1 ? 1 : (points.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) => const FlLine(color: PulseColors.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: yInterval,
                getTitlesWidget: (value, _) => Text(
                  value.round().toString(),
                  style: const TextStyle(color: PulseColors.paperMuted, fontSize: 11),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final index = value.round();
                  if ((value - index).abs() > 0.01 || index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  if (index != points.length - 1 && index % step != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _relativeLabel(points[index].recordedAt, points.last.recordedAt),
                      style: const TextStyle(color: PulseColors.paperMuted, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: points.length > 2,
              color: PulseColors.signal,
              barWidth: 2.4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, bar) => spot.x == bar.spots.last.x,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PulseColors.signal.withValues(alpha: 0.28),
                    PulseColors.signal.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}

double _yInterval(double span) {
  if (span <= 24) return 4;
  if (span <= 50) return 10;
  return 20;
}

String _relativeLabel(DateTime point, DateTime newest) {
  final seconds = newest.difference(point).inSeconds;
  if (seconds <= 0) return 'now';
  return '-${seconds}s';
}
