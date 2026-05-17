import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_providers.dart';
import '../../../core/utils/weight_format.dart';
import '../../../shared/widgets/app_gradients.dart';
import '../../../shared/widgets/bento_tile.dart';
import '../providers/history_providers.dart';

class StatsSummaryCard extends ConsumerWidget {
  const StatsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(historyStatsProvider);
    final unit = ref.watch(settingsProvider).weightUnit;
    final scheme = Theme.of(context).colorScheme;

    return statsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $error'),
      ),
      data: (stats) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: BentoTile(
                    gradient: AppGradients.ocean,
                    icon: Icons.date_range_rounded,
                    label: 'Esta semana',
                    value: '${stats.sessionsThisWeek}',
                    subtitle: stats.sessionsThisWeek == 1
                        ? 'sesión'
                        : 'sesiones',
                    compact: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BentoTile(
                    gradient: AppGradients.violet,
                    icon: Icons.calendar_today_rounded,
                    label: 'Este mes',
                    value: '${stats.sessionsThisMonth}',
                    subtitle: stats.sessionsThisMonth == 1
                        ? 'sesión'
                        : 'sesiones',
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: scheme.surfaceContainerHigh,
              ),
              child: Row(
                children: [
                  _SmallStat(
                    icon: Icons.fitness_center_rounded,
                    value: formatVolumeInUnit(stats.totalVolumeKg, unit),
                    label: 'Volumen total',
                    color: scheme.primary,
                  ),
                  const _StatDivider(),
                  _SmallStat(
                    icon: Icons.repeat_rounded,
                    value: '${stats.totalSets}',
                    label: 'Series',
                    color: scheme.secondary,
                  ),
                  const _StatDivider(),
                  _SmallStat(
                    icon: Icons.event_available_rounded,
                    value: '${stats.totalSessions}',
                    label: 'Sesiones',
                    color: scheme.tertiary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: color,
                ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}
