import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_providers.dart';
import '../../../core/utils/weight_format.dart';
import '../providers/history_providers.dart';

/// Mini-chart de volumen agregado por semana (últimas 8 semanas).
class WeeklyVolumeCard extends ConsumerWidget {
  const WeeklyVolumeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWeeks = ref.watch(weeklyVolumeProvider);
    final unit = ref.watch(settingsProvider).weightUnit;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHigh,
      ),
      child: asyncWeeks.when(
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (weeks) {
          if (weeks.isEmpty || weeks.every((w) => w.volume == 0)) {
            return _Empty(scheme: scheme);
          }
          final maxVol = weeks.map((w) => w.volume).reduce(math.max);
          final totalLast =
              weeks.fold<double>(0, (a, w) => a + w.volume);
          final avg = totalLast / weeks.length;

          // Tendencia: comparar primera mitad con segunda
          final firstHalf = weeks
                  .take(weeks.length ~/ 2)
                  .fold<double>(0, (a, w) => a + w.volume) /
              (weeks.length / 2);
          final secondHalf = weeks
                  .skip(weeks.length ~/ 2)
                  .fold<double>(0, (a, w) => a + w.volume) /
              (weeks.length - weeks.length ~/ 2);
          final trendPct = firstHalf == 0
              ? 0.0
              : ((secondHalf - firstHalf) / firstHalf * 100);
          final trendUp = trendPct > 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Volumen semanal',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                  ),
                  const Spacer(),
                  if (trendPct.abs() >= 1)
                    Row(
                      children: [
                        Icon(
                          trendUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 14,
                          color: trendUp ? scheme.tertiary : scheme.error,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${trendUp ? '+' : ''}${trendPct.toStringAsFixed(0)}%',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: trendUp
                                    ? scheme.tertiary
                                    : scheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 70,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < weeks.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _Bar(
                            value: weeks[i].volume,
                            max: maxVol,
                            isLast: i == weeks.length - 1,
                            scheme: scheme,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Hace 8 sem',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const Spacer(),
                  Text(
                    'Esta sem',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Media: ${formatVolumeInUnit(avg, unit)}/sem',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    'Última: ${formatVolumeInUnit(weeks.last.volume, unit)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.max,
    required this.isLast,
    required this.scheme,
  });

  final double value;
  final double max;
  final bool isLast;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final color = isLast ? scheme.primary : scheme.primary.withValues(alpha: 0.5);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 60 * ratio + (value > 0 ? 4 : 0),
          decoration: BoxDecoration(
            color: value == 0 ? scheme.surfaceContainerHighest : color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
              bottom: Radius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          'Sin volumen registrado',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
