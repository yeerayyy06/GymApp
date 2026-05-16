import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartPoint {
  const ChartPoint({required this.time, required this.value});
  final DateTime time;
  final double value;
}

class LineChartCard extends StatelessWidget {
  const LineChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.points,
    this.unit = '',
    this.emptyMessage = 'Necesitas al menos 2 registros para ver la evolución',
    this.height = 200,
    this.daysWindow = 90,
    this.valueFormatter,
  });

  final String title;
  final IconData icon;
  final List<ChartPoint> points;
  final String unit;
  final String emptyMessage;
  final double height;
  final int daysWindow;
  final String Function(double value)? valueFormatter;

  String _fmtValue(double v) {
    if (valueFormatter != null) return valueFormatter!(v);
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final cutoff = DateTime.now().subtract(Duration(days: daysWindow));
    final filtered = points
        .where((p) => p.time.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHigh,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                ),
                const Spacer(),
                Text(
                  '${daysWindow}d',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: filtered.length < 2
                  ? Center(
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  : _buildChart(context, filtered, scheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<ChartPoint> data,
    ColorScheme scheme,
  ) {
    final values = data.map((p) => p.value).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final range = maxVal - minVal;
    final pad = math.max(range * 0.15, 1.0);
    final minY = minVal - pad;
    final maxY = maxVal + pad;

    final minX = data.first.time.millisecondsSinceEpoch.toDouble();
    final maxX = data.last.time.millisecondsSinceEpoch.toDouble();
    final spanMs = math.max(maxX - minX, 1.0);

    final spots = data
        .map((p) =>
            FlSpot(p.time.millisecondsSinceEpoch.toDouble(), p.value))
        .toList(growable: false);

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.25),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: (maxY - minY) / 4,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _fmtValue(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: spanMs / 3,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                  value.toInt(),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                scheme.inverseSurface.withValues(alpha: 0.92),
            getTooltipItems: (touched) => touched.map((t) {
              final date = DateTime.fromMillisecondsSinceEpoch(t.x.toInt());
              return LineTooltipItem(
                '${_fmtValue(t.y)}$unit\n${date.day}/${date.month}/${date.year}',
                TextStyle(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: scheme.primary,
            barWidth: 2.5,
            isCurved: false,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 30,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: scheme.primary,
                strokeColor: scheme.surfaceContainerHigh,
                strokeWidth: 1.5,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.primary.withValues(alpha: 0.22),
                  scheme.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
