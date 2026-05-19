import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/domain/muscle_group.dart';
import '../../core/providers/clock_provider.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/one_rep_max.dart';
import '../../core/utils/weight_format.dart';
import '../../shared/widgets/line_chart_card.dart';
import '../../shared/widgets/skeleton.dart';
import '../exercises/widgets/exercise_video_sheet.dart';
import 'data/history_models.dart';
import 'providers/history_providers.dart';
import 'widgets/pr_badge.dart';

class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseId));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de ejercicio',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        actions: [
          historyAsync.when(
            data: (h) => h == null
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Ver técnica',
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    onPressed: () =>
                        ExerciseVideoSheet.show(context, h.exercise.name),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const DetailSkeleton(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (history) {
          if (history == null) {
            return const Center(child: Text('Ejercicio no encontrado'));
          }
          return _ExerciseHistoryBody(history: history);
        },
      ),
    );
  }
}

class _ExerciseHistoryBody extends ConsumerWidget {
  const _ExerciseHistoryBody({required this.history});

  final ExerciseHistory history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final exercise = history.exercise;
    final muscles = exercise.primaryMuscles
        .map((m) => m.displayName)
        .join(', ');
    final scheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // ── Exercise info header ──
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.1),
                  scheme.tertiary.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                ),
                if (muscles.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    muscles,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
                if (exercise.equipment != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.fitness_center,
                          size: 13, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        exercise.equipment!,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── PRs card ──
        SliverToBoxAdapter(
          child: _PRsCard(prs: history.prs, totalSets: history.totalSets),
        ),

        // ── Progression chart ──
        SliverToBoxAdapter(
          child: LineChartCard(
            title: '1RM estimado',
            icon: Icons.trending_up_rounded,
            points: _build1RMPoints(history.entries),
            unit: ' kg',
            daysWindow: 180,
            emptyMessage:
                'Registra al menos 2 sesiones con series de trabajo para ver la evolución',
          ),
        ),

        // ── Session entries ──
        if (history.entries.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(24),
              child:
                  Center(child: Text('Aún no has registrado este ejercicio')),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Historial por sesión',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: history.entries.length,
            itemBuilder: (context, index) {
              final entry = history.entries[index];
              return _SessionEntry(
                entry: entry,
                prs: history.prs,
                now: now,
              );
            },
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }
}

List<ChartPoint> _build1RMPoints(List<ExerciseSessionEntry> entries) {
  final points = <ChartPoint>[];
  for (final entry in entries) {
    double best = 0;
    for (final set in entry.sets) {
      if (set.isWarmup) continue;
      final est =
          estimatedOneRepMax(weightKg: set.weightKg, reps: set.reps);
      if (est > best) best = est;
    }
    if (best > 0) {
      points.add(ChartPoint(time: entry.session.startedAt, value: best));
    }
  }
  return points;
}

class _PRsCard extends ConsumerWidget {
  const _PRsCard({required this.prs, required this.totalSets});

  final ExercisePRs? prs;
  final int totalSets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final unit = ref.watch(settingsProvider).weightUnit;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    size: 18, color: scheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Récords personales',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (prs == null)
              Text(
                'Aún no hay récords. Registra una serie para empezar.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              )
            else
              Row(
                children: [
                  _PRStat(
                    label: 'Peso máx',
                    value: formatWeight(prs!.bestWeightKg, unit),
                    color: scheme.primary,
                  ),
                  _PRStat(
                    label: '1RM est.',
                    value: formatWeight(prs!.bestEst1RMKg, unit),
                    color: scheme.secondary,
                  ),
                  _PRStat(
                    label: 'Vol. serie',
                    value: formatVolumeInUnit(prs!.bestVolumeSetKg, unit),
                    color: scheme.tertiary,
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Divider(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                height: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Total series registradas: $totalSets',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PRStat extends StatelessWidget {
  const _PRStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SessionEntry extends StatelessWidget {
  const _SessionEntry({
    required this.entry,
    required this.prs,
    required this.now,
  });

  final ExerciseSessionEntry entry;
  final ExercisePRs? prs;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHigh,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  formatRelativeDate(entry.session.startedAt, now),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatTime(entry.session.startedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._buildSetRows(entry.sets, prs),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSetRows(List<LoggedSetRow> sets, ExercisePRs? prs) {
    final rows = <Widget>[];
    var workingCounter = 0;
    for (final set in sets) {
      final label = set.isWarmup ? null : (++workingCounter).toString();
      rows.add(_ExerciseHistorySetRow(label: label, set: set, prs: prs));
    }
    return rows;
  }
}

class _ExerciseHistorySetRow extends ConsumerWidget {
  const _ExerciseHistorySetRow({
    required this.label,
    required this.set,
    required this.prs,
  });

  final String? label;
  final LoggedSetRow set;
  final ExercisePRs? prs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final unit = ref.watch(settingsProvider).weightUnit;
    final est1RM = estimatedOneRepMax(weightKg: set.weightKg, reps: set.reps);
    final isWeightPR = !set.isWarmup &&
        prs != null &&
        set.weightKg >= prs!.bestWeightKg - 0.001;
    final is1RMPR = !set.isWarmup &&
        prs != null &&
        est1RM >= prs!.bestEst1RMKg - 0.001;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: label == null
                ? Text(
                    'W',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.tertiary,
                        ),
                  )
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label!,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                                fontSize: 10,
                              ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${formatWeight(set.weightKg, unit)}  ×  ${set.reps}'
              '${set.rpe == null ? '' : '  ·  RPE ${set.rpe}'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (is1RMPR)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: PRBadge(label: '1RM'),
            )
          else if (isWeightPR)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: PRBadge(label: 'PESO'),
            ),
        ],
      ),
    );
  }
}
