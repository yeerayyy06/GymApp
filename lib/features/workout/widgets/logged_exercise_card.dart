import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/settings_providers.dart';
import '../data/workout_repository.dart';
import '../providers/rest_timer_provider.dart';
import '../providers/workout_providers.dart';
import 'set_form_dialog.dart';

class LoggedExerciseCard extends ConsumerWidget {
  const LoggedExerciseCard({
    super.key,
    required this.entry,
    this.canMoveUp = true,
    this.canMoveDown = true,
  });

  final LoggedExerciseWithDetails entry;
  final bool canMoveUp;
  final bool canMoveDown;

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
      ref.read(restTimerProvider.notifier).start(
            duration: Duration(seconds: restSeconds),
            exerciseId: entry.exercise.id,
            exerciseName: entry.exercise.name,
          );
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

  Future<void> _move(WidgetRef ref, int delta) async {
    await ref.read(workoutRepositoryProvider).moveLoggedExercise(
          sessionId: entry.logged.sessionId,
          loggedExerciseId: entry.logged.id,
          delta: delta,
        );
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
                      Text(
                        entry.exercise.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
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
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'remove':
                        _removeExercise(ref);
                      case 'move_up':
                        _move(ref, -1);
                      case 'move_down':
                        _move(ref, 1);
                    }
                  },
                  itemBuilder: (_) => [
                    if (canMoveUp)
                      const PopupMenuItem(
                        value: 'move_up',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.arrow_upward_rounded),
                          title: Text('Mover arriba'),
                        ),
                      ),
                    if (canMoveDown)
                      const PopupMenuItem(
                        value: 'move_down',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.arrow_downward_rounded),
                          title: Text('Mover abajo'),
                        ),
                      ),
                    const PopupMenuItem(
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

class _SetTile extends StatelessWidget {
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

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                  '${_formatWeight(set.weightKg)} kg  ×  ${set.reps}$rpeText',
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
