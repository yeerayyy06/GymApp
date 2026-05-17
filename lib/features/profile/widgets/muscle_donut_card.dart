import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/muscle_color.dart';
import '../../../core/domain/muscle_group.dart';
import '../../../core/utils/formatters.dart';
import '../../history/providers/history_providers.dart';

class MuscleDonutCard extends ConsumerStatefulWidget {
  const MuscleDonutCard({super.key});

  @override
  ConsumerState<MuscleDonutCard> createState() => _MuscleDonutCardState();
}

class _MuscleDonutCardState extends ConsumerState<MuscleDonutCard> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final asyncMap = ref.watch(volumeByMuscleProvider);
    final days = ref.watch(muscleVolumeWindowProvider);
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
              Icon(Icons.donut_large_rounded,
                  size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Distribución de volumen',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
              ),
              const Spacer(),
              Text(
                '${days}d',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          asyncMap.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (volumes) {
              if (volumes.isEmpty) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Sin datos',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                );
              }
              return _DonutBody(
                volumes: volumes,
                touchedIndex: _touchedIndex,
                onSectionTouched: (i) =>
                    setState(() => _touchedIndex = i),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DonutBody extends StatelessWidget {
  const _DonutBody({
    required this.volumes,
    required this.touchedIndex,
    required this.onSectionTouched,
  });

  final Map<MuscleGroup, double> volumes;
  final int? touchedIndex;
  final ValueChanged<int?> onSectionTouched;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = volumes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (a, e) => a + e.value);

    // Si hay más de 7 músculos agrupamos los más pequeños en "Otros"
    final shown = entries.length > 7 ? entries.take(6).toList() : entries;
    final othersValue = entries.length > 7
        ? entries.skip(6).fold<double>(0, (a, e) => a + e.value)
        : 0.0;

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < shown.length; i++) {
      final entry = shown[i];
      final isTouched = touchedIndex == i;
      sections.add(PieChartSectionData(
        color: entry.key.brandColor,
        value: entry.value,
        title: '',
        radius: isTouched ? 38 : 32,
      ));
    }
    if (othersValue > 0) {
      final isTouched = touchedIndex == shown.length;
      sections.add(PieChartSectionData(
        color: scheme.onSurfaceVariant,
        value: othersValue,
        title: '',
        radius: isTouched ? 38 : 32,
      ));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 42,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        onSectionTouched(null);
                        return;
                      }
                      onSectionTouched(
                        response.touchedSection!.touchedSectionIndex,
                      );
                    },
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatVolume(total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < shown.length; i++)
                _LegendRow(
                  label: shown[i].key.displayName,
                  color: shown[i].key.brandColor,
                  percent: total == 0 ? 0 : shown[i].value / total,
                  highlighted: touchedIndex == i,
                ),
              if (othersValue > 0)
                _LegendRow(
                  label: 'Otros',
                  color: scheme.onSurfaceVariant,
                  percent: total == 0 ? 0 : othersValue / total,
                  highlighted: touchedIndex == shown.length,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.color,
    required this.percent,
    required this.highlighted,
  });

  final String label;
  final Color color;
  final double percent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: highlighted
            ? color.withValues(alpha: 0.18)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
          Text(
            '${(percent * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
