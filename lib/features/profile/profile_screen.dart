import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/clock_provider.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/line_chart_card.dart';
import '../history/providers/history_providers.dart';
import 'providers/profile_providers.dart';
import 'widgets/activity_heatmap_card.dart';
import 'widgets/bodyweight_form_dialog.dart';
import 'widgets/muscle_donut_card.dart';
import 'widgets/muscle_volume_card.dart';
import 'widgets/streak_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _addEntry(BuildContext context, WidgetRef ref) async {
    final result = await BodyweightFormDialog.show(context);
    if (result == null) return;
    await ref.read(profileRepositoryProvider).addEntry(
          weightKg: result.weightKg,
          measuredAt: result.measuredAt,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(bodyweightEntriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEntry(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar peso'),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (entries) => _ProfileBody(entries: entries),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.entries});

  final List<BodyweightEntryRow> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final scheme = Theme.of(context).colorScheme;
    final latest = entries.isEmpty ? null : entries.first;
    final previous = entries.length >= 2 ? entries[1] : null;
    final delta =
        latest != null && previous != null ? latest.weightKg - previous.weightKg : null;

    final chartPoints = entries
        .map((e) => ChartPoint(time: e.measuredAt, value: e.weightKg))
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _BodyweightHeader(latest: latest, delta: delta, now: now),
        const StreakCard(),
        const _TrainingSummaryCard(),
        const ActivityHeatmapCard(),
        const MuscleDonutCard(),
        const MuscleVolumeCard(),
        LineChartCard(
          title: 'Evolución del peso',
          icon: Icons.show_chart_rounded,
          points: chartPoints,
          unit: ' kg',
          daysWindow: 90,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text(
            'Historial de peso',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
          ),
        ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.monitor_weight_outlined,
                    size: 40,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aún no hay registros de peso',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          )
        else
          ...entries.map(
            (entry) => _BodyweightTile(entry: entry, now: now),
          ),
      ],
    );
  }
}

class _BodyweightHeader extends StatelessWidget {
  const _BodyweightHeader({
    required this.latest,
    required this.delta,
    required this.now,
  });

  final BodyweightEntryRow? latest;
  final double? delta;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.12),
            scheme.tertiary.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_weight_rounded,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Peso corporal',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (latest == null)
            Text(
              'Sin registros',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatWeightKg(latest!.weightKg),
                  style:
                      Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                ),
                const SizedBox(width: 12),
                if (delta != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DeltaChip(delta: delta!),
                  ),
              ],
            ),
          const SizedBox(height: 4),
          if (latest != null)
            Text(
              formatRelativeDate(latest!.measuredAt, now),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPositive = delta > 0;
    final isZero = delta.abs() < 0.05;
    final color = isZero
        ? scheme.onSurfaceVariant
        : (isPositive ? scheme.tertiary : scheme.primary);
    final icon = isZero
        ? Icons.remove_rounded
        : (isPositive
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded);
    final text = isZero
        ? '0 kg'
        : '${isPositive ? '+' : '−'}${delta.abs().toStringAsFixed(1)} kg';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingSummaryCard extends ConsumerWidget {
  const _TrainingSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(historyStatsProvider);
    final scheme = Theme.of(context).colorScheme;
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
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: statsAsync.when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Error: $error'),
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Entrenamientos',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SummaryBlock(
                    value: '${stats.totalSessions}',
                    label: 'Sesiones',
                    accent: scheme.primary,
                  ),
                  _SummaryBlock(
                    value: '${stats.totalSets}',
                    label: 'Series',
                    accent: scheme.secondary,
                  ),
                  _SummaryBlock(
                    value: formatVolume(stats.totalVolumeKg),
                    label: 'Volumen',
                    accent: scheme.tertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: accent,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _BodyweightTile extends ConsumerWidget {
  const _BodyweightTile({required this.entry, required this.now});

  final BodyweightEntryRow entry;
  final DateTime now;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await BodyweightFormDialog.show(
      context,
      initialWeightKg: entry.weightKg,
      initialMeasuredAt: entry.measuredAt,
      isEditing: true,
    );
    if (result == null) return;
    await ref.read(profileRepositoryProvider).updateEntry(
          id: entry.id,
          weightKg: result.weightKg,
          measuredAt: result.measuredAt,
        );
  }

  Future<void> _delete(WidgetRef ref) async {
    await ref.read(profileRepositoryProvider).deleteEntry(entry.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete_rounded, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => _delete(ref),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: scheme.surfaceContainerHigh,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _edit(context, ref),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatWeightKg(entry.weightKg),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatRelativeDate(entry.measuredAt, now),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
