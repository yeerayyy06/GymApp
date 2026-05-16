import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/domain/muscle_group.dart';
import '../../core/providers/clock_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/one_rep_max.dart';
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
      appBar: AppBar(title: const Text('Historial de ejercicio')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (muscles.isNotEmpty)
                  Text(
                    muscles,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (exercise.equipment != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      exercise.equipment!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _PRsCard(prs: history.prs, totalSets: history.totalSets)),
        if (history.entries.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Aún no has registrado este ejercicio')),
            ),
          )
        else
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
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }
}

class _PRsCard extends StatelessWidget {
  const _PRsCard({required this.prs, required this.totalSets});

  final ExercisePRs? prs;
  final int totalSets;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Récords personales',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            if (prs == null)
              Text(
                'Aún no hay récords. Registra una serie para empezar.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Row(
                children: [
                  _PRStat(
                    label: 'Peso máx',
                    value: formatWeightKg(prs!.bestWeightKg),
                  ),
                  _PRStat(
                    label: '1RM est.',
                    value: formatWeightKg(prs!.bestEst1RMKg),
                  ),
                  _PRStat(
                    label: 'Vol. serie',
                    value: formatVolume(prs!.bestVolumeSetKg),
                  ),
                ],
              ),
            const Divider(height: 22),
            Text(
              'Total series registradas: $totalSets',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PRStat extends StatelessWidget {
  const _PRStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatRelativeDate(entry.session.startedAt, now),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              formatTime(entry.session.startedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < entry.sets.length; i++)
              _ExerciseHistorySetRow(
                index: i + 1,
                set: entry.sets[i],
                prs: prs,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseHistorySetRow extends StatelessWidget {
  const _ExerciseHistorySetRow({
    required this.index,
    required this.set,
    required this.prs,
  });

  final int index;
  final LoggedSetRow set;
  final ExercisePRs? prs;

  @override
  Widget build(BuildContext context) {
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
            width: 24,
            child: Text(
              '$index',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Expanded(
            child: Text(
              '${formatWeightKg(set.weightKg)}  ×  ${set.reps}'
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
