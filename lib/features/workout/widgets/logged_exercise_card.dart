import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/settings_providers.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/utils/one_rep_max.dart';
import '../../../core/utils/weight_format.dart';
import '../../exercises/data/exercise_videos.dart';
import '../../history/providers/history_providers.dart';
import '../data/workout_repository.dart';
import '../providers/rest_timer_provider.dart';
import '../providers/workout_providers.dart';
import 'pr_celebration.dart';
import 'set_form_dialog.dart';

class LoggedExerciseCard extends ConsumerWidget {
  const LoggedExerciseCard({
    super.key,
    required this.entry,
    this.indexInSession = 0,
  });

  final LoggedExerciseWithDetails entry;
  final int indexInSession;

  Future<void> _addSet(BuildContext context, WidgetRef ref) async {
    final sets = ref.read(setsProvider(entry.logged.id)).valueOrNull ?? [];
    final workingSets =
        sets.where((s) => !s.isWarmup).toList(growable: false);
    final lastWorkingSet =
        workingSets.isEmpty ? null : workingSets.last;
    final result = await SetFormDialog.show(
      context,
      exerciseName: entry.exercise.name,
      setNumber: workingSets.length + 1,
      initialWeightKg: lastWorkingSet?.weightKg,
      initialReps: lastWorkingSet?.reps,
      initialRpe: lastWorkingSet?.rpe,
    );
    if (result == null) return;

    // Snapshot de PRs ANTES de insertar para detectar récord
    final oldPRs = ref.read(allTimePRsProvider).valueOrNull ?? {};
    final oldPR = oldPRs[entry.exercise.id];

    await ref.read(workoutRepositoryProvider).addSet(
          loggedExerciseId: entry.logged.id,
          weightKg: result.weightKg,
          reps: result.reps,
          rpe: result.rpe,
          isWarmup: result.isWarmup,
        );
    if (!result.isWarmup) {
      final settings = ref.read(settingsProvider);
      final restSeconds = settings.restSecondsFor(entry.exercise.id);
      AudioService.warmUp();
      ref.read(restTimerProvider.notifier).start(
            duration: Duration(seconds: restSeconds),
            exerciseId: entry.exercise.id,
            exerciseName: entry.exercise.name,
          );

      // PR check
      final est1RM = estimatedOneRepMax(
        weightKg: result.weightKg,
        reps: result.reps,
      );
      final kinds = <PRKind>{};
      if (oldPR == null || result.weightKg > oldPR.bestWeightKg + 0.001) {
        kinds.add(PRKind.weight);
      }
      if (oldPR == null || est1RM > oldPR.bestEst1RMKg + 0.001) {
        kinds.add(PRKind.oneRm);
      }
      if (kinds.isNotEmpty && context.mounted) {
        await PRCelebration.show(
          context,
          exerciseName: entry.exercise.name,
          weightKg: result.weightKg,
          reps: result.reps,
          kinds: kinds,
        );
      }
    }
  }

  Future<void> _editSet(
    BuildContext context,
    WidgetRef ref,
    LoggedSetRow set,
  ) async {
    final result = await SetFormDialog.show(
      context,
      exerciseName: entry.exercise.name,
      setNumber: set.setNumber,
      initialWeightKg: set.weightKg,
      initialReps: set.reps,
      initialRpe: set.rpe,
      initialIsWarmup: set.isWarmup,
      isEditing: true,
    );
    if (result == null) return;
    await ref.read(workoutRepositoryProvider).updateSet(
          setId: set.id,
          weightKg: result.weightKg,
          reps: result.reps,
          rpe: result.rpe,
          isWarmup: result.isWarmup,
        );
  }

  Future<void> _removeExercise(WidgetRef ref) async {
    await ref
        .read(workoutRepositoryProvider)
        .removeLoggedExercise(entry.logged.id);
  }

  Future<void> _deleteSet(WidgetRef ref, String setId) async {
    await ref.read(workoutRepositoryProvider).deleteSet(setId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final setsAsync = ref.watch(setsProvider(entry.logged.id));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.exercise.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Ver técnica',
                            icon: Icon(
                              Icons.play_circle_outline_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                openExerciseVideo(entry.exercise.name),
                          ),
                        ],
                      ),
                      if (entry.exercise.equipment != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          entry.exercise.equipment!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: indexInSession,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'remove') _removeExercise(ref);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Eliminar ejercicio'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _PreviousPerformance(
            exerciseId: entry.exercise.id,
            currentSessionId: entry.logged.sessionId,
            loggedExerciseId: entry.logged.id,
          ),
          setsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $error'),
            ),
            data: (sets) {
              if (sets.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Text(
                    'Aún no hay series',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                );
              }
              final tiles = <Widget>[];
              var workingCounter = 0;
              for (final set in sets) {
                final label =
                    set.isWarmup ? null : (++workingCounter).toString();
                tiles.add(
                  _SetTile(
                    label: label,
                    set: set,
                    onTap: () => _editSet(context, ref, set),
                    onDelete: () => _deleteSet(ref, set.id),
                  ),
                );
              }
              return Column(children: tiles);
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addSet(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Añadir serie'),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviousPerformance extends ConsumerWidget {
  const _PreviousPerformance({
    required this.exerciseId,
    required this.currentSessionId,
    required this.loggedExerciseId,
  });

  final String exerciseId;
  final String currentSessionId;
  final String loggedExerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrev = ref.watch(previousExerciseSetsProvider(
      (exerciseId: exerciseId, excludingSessionId: currentSessionId),
    ));
    final unit = ref.watch(settingsProvider).weightUnit;
    final currentSetsAsync = ref.watch(setsProvider(loggedExerciseId));
    final scheme = Theme.of(context).colorScheme;
    return asyncPrev.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (prev) {
        if (prev == null) return const SizedBox.shrink();
        final prevWorking =
            prev.sets.where((s) => !s.isWarmup).toList(growable: false);
        if (prevWorking.isEmpty) return const SizedBox.shrink();
        final prevTop = prevWorking
            .reduce((a, b) => (a.weightKg * a.reps) >= (b.weightKg * b.reps) ? a : b);
        final summary =
            '${prevWorking.length}×${prevTop.reps} · ${formatWeight(prevTop.weightKg, unit)}';
        final daysAgo = DateTime.now().difference(prev.sessionStartedAt).inDays;
        final whenLabel = daysAgo == 0
            ? 'hoy'
            : daysAgo == 1
                ? 'ayer'
                : 'hace ${daysAgo}d';

        // Delta vs sesión actual (si ya hay sets de trabajo registrados)
        final currentWorking = currentSetsAsync.maybeWhen(
          data: (sets) => sets.where((s) => !s.isWarmup).toList(),
          orElse: () => <LoggedSetRow>[],
        );
        Widget? deltaChip;
        if (currentWorking.isNotEmpty) {
          final currTop = currentWorking
              .reduce((a, b) => (a.weightKg * a.reps) >= (b.weightKg * b.reps) ? a : b);
          final weightDelta = currTop.weightKg - prevTop.weightKg;
          final repDelta = currTop.reps - prevTop.reps;
          final volDelta = (currTop.weightKg * currTop.reps) -
              (prevTop.weightKg * prevTop.reps);
          // Mostrar la dimensión más relevante
          final List<String> parts = [];
          Color color;
          IconData icon;
          if (weightDelta.abs() > 0.05) {
            parts.add(
              '${weightDelta > 0 ? '+' : ''}${unit.fromKg(weightDelta).toStringAsFixed(weightDelta.abs() < 10 ? 1 : 0)} ${unit.label}',
            );
          }
          if (repDelta != 0) {
            parts.add('${repDelta > 0 ? '+' : ''}$repDelta rep');
          }
          if (parts.isEmpty && volDelta.abs() > 0.5) {
            parts.add(
              '${volDelta > 0 ? '+' : ''}${unit.fromKg(volDelta).toStringAsFixed(0)} ${unit.label}',
            );
          }
          final isUp = volDelta > 0.5 ||
              (volDelta.abs() <= 0.5 && weightDelta > 0.05);
          final isDown = volDelta < -0.5 ||
              (volDelta.abs() <= 0.5 && weightDelta < -0.05);
          if (isUp) {
            color = const Color(0xFF22C55E);
            icon = Icons.trending_up_rounded;
          } else if (isDown) {
            color = const Color(0xFFEF4444);
            icon = Icons.trending_down_rounded;
          } else {
            color = scheme.onSurfaceVariant;
            icon = Icons.trending_flat_rounded;
          }
          if (parts.isNotEmpty || !isUp && !isDown) {
            deltaChip = Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color.withValues(alpha: 0.16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 11, color: color),
                  const SizedBox(width: 3),
                  Text(
                    parts.isEmpty ? 'igual' : parts.join(' · '),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            );
          }
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: scheme.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 12, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Última ($whenLabel): $summary',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                if (deltaChip != null) ...[
                  const SizedBox(width: 6),
                  deltaChip,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SetTile extends ConsumerWidget {
  const _SetTile({
    required this.label,
    required this.set,
    required this.onTap,
    required this.onDelete,
  });

  final String? label;
  final LoggedSetRow set;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final unit = ref.watch(settingsProvider).weightUnit;
    final rpeText = set.rpe == null ? '' : '  ·  RPE ${set.rpe}';
    return Dismissible(
      key: ValueKey(set.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete_rounded, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: label == null
                    ? Text(
                        'W',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.tertiary,
                            ),
                        textAlign: TextAlign.center,
                      )
                    : Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label!,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${formatWeight(set.weightKg, unit)}  ×  ${set.reps}$rpeText',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
