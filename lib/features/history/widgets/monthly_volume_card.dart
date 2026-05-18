import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_providers.dart';
import '../../../core/utils/weight_format.dart';
import '../providers/history_providers.dart';

class MonthlyVolumeCard extends ConsumerWidget {
  const MonthlyVolumeCard({super.key});

  static const _monthLabels = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMonths = ref.watch(monthlyVolumeProvider);
    final unit = ref.watch(settingsProvider).weightUnit;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHigh,
      ),
      child: asyncMonths.when(
        loading: () => const SizedBox(
          height: 110,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (months) {
          if (months.isEmpty || months.every((m) => m.volume == 0)) {
            return SizedBox(
              height: 110,
              child: Center(
                child: Text(
                  'Sin volumen registrado',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            );
          }
          final maxVol = months.map((m) => m.volume).reduce(math.max);
          final totalLast = months.fold<double>(0, (a, m) => a + m.volume);
          final avg = totalLast / months.length;

          // tendencia: primer trimestre vs último trimestre
          final firstHalf =
              months.take(3).fold<double>(0, (a, m) => a + m.volume) / 3;
          final secondHalf =
              months.skip(3).fold<double>(0, (a, m) => a + m.volume) / 3;
          final trendPct =
              firstHalf == 0 ? 0.0 : (secondHalf - firstHalf) / firstHalf * 100;
          final trendUp = trendPct > 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.stacked_bar_chart_rounded,
                      size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Volumen mensual',
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
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: trendUp ? scheme.tertiary : scheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < months.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _Bar(
                            value: months[i].volume,
                            max: maxVol,
                            isLast: i == months.length - 1,
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
                  for (final m in months)
                    Expanded(
                      child: Center(
                        child: Text(
                          _monthLabels[m.monthStart.month - 1],
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Media: ${formatVolumeInUnit(avg, unit)}/mes',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    'Total 6m: ${formatVolumeInUnit(totalLast, unit)}',
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
          height: 80 * ratio + (value > 0 ? 4 : 0),
          decoration: BoxDecoration(
            color: value == 0 ? scheme.surfaceContainerHighest : color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(5),
              bottom: Radius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}
