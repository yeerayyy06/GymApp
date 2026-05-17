import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../history/providers/history_providers.dart';

class ActivityHeatmapCard extends ConsumerWidget {
  const ActivityHeatmapCard({super.key});

  static const _weeks = 13; // ~3 meses

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncByDay = ref.watch(dailyVolumeProvider);
    final now = ref.watch(clockProvider)();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded,
                  size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Actividad',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
              ),
              const Spacer(),
              Text(
                'Últimas 13 semanas',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          asyncByDay.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (byDay) {
              final maxVol = byDay.values
                  .fold<double>(0, (a, b) => a > b ? a : b);
              return _HeatmapGrid(
                byDay: byDay,
                maxVolume: maxVol,
                today: startOfDay(now),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Menos',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(width: 6),
              for (final alpha in [0.15, 0.35, 0.6, 0.85, 1.0])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: alpha == 0.15
                          ? scheme.surfaceContainerHighest
                          : scheme.primary.withValues(alpha: alpha),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                'Más',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.byDay,
    required this.maxVolume,
    required this.today,
  });

  final Map<DateTime, double> byDay;
  final double maxVolume;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const weeks = ActivityHeatmapCard._weeks;
        const days = 7;
        const spacing = 3.0;
        final available = constraints.maxWidth - 18; // espacio para labels
        final cellSize =
            ((available - (weeks - 1) * spacing) / weeks).clamp(8.0, 18.0);

        // Día de la semana: lunes=0..domingo=6
        final mondayOfThisWeek =
            today.subtract(Duration(days: today.weekday - 1));

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Etiquetas L/M/V
            Column(
              children: [
                _DayLabel(text: 'L', cellSize: cellSize, spacing: spacing),
                _DayLabel(text: '', cellSize: cellSize, spacing: spacing),
                _DayLabel(text: 'M', cellSize: cellSize, spacing: spacing),
                _DayLabel(text: '', cellSize: cellSize, spacing: spacing),
                _DayLabel(text: 'V', cellSize: cellSize, spacing: spacing),
                _DayLabel(text: '', cellSize: cellSize, spacing: spacing),
                _DayLabel(text: 'D', cellSize: cellSize, spacing: spacing),
              ],
            ),
            const SizedBox(width: 4),
            for (int w = 0; w < weeks; w++)
              Padding(
                padding: EdgeInsets.only(
                  right: w == weeks - 1 ? 0 : spacing,
                ),
                child: Column(
                  children: [
                    for (int d = 0; d < days; d++)
                      _buildCell(context, mondayOfThisWeek, w, d, cellSize,
                          spacing, weeks),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCell(
    BuildContext context,
    DateTime mondayOfThisWeek,
    int weekIdx,
    int dayIdx,
    double cellSize,
    double spacing,
    int weeks,
  ) {
    final weekStart = mondayOfThisWeek
        .subtract(Duration(days: (weeks - 1 - weekIdx) * 7));
    final date = weekStart.add(Duration(days: dayIdx));
    final inFuture = date.isAfter(today);
    final volume = byDay[date] ?? 0;
    final scheme = Theme.of(context).colorScheme;

    Color cellColor;
    if (inFuture) {
      cellColor = Colors.transparent;
    } else if (volume == 0) {
      cellColor = scheme.surfaceContainerHighest;
    } else {
      final ratio = maxVolume == 0 ? 0.0 : (volume / maxVolume).clamp(0.0, 1.0);
      final alpha = 0.2 + ratio * 0.8;
      cellColor = scheme.primary.withValues(alpha: alpha);
    }

    final isToday = date == today;

    return Padding(
      padding: EdgeInsets.only(bottom: dayIdx == 6 ? 0 : spacing),
      child: Tooltip(
        message: inFuture
            ? ''
            : '${date.day}/${date.month}: ${volume > 0 ? formatVolume(volume) : "descanso"}',
        child: Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: cellColor,
            border: isToday
                ? Border.all(color: scheme.primary, width: 1.2)
                : null,
          ),
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({
    required this.text,
    required this.cellSize,
    required this.spacing,
  });

  final String text;
  final double cellSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: cellSize + spacing,
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
