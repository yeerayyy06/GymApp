import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/workout_repository.dart';
import '../providers/workout_providers.dart';
import 'set_form_dialog.dart';

class LoggedExerciseCard extends ConsumerWidget {
  const LoggedExerciseCard({super.key, required this.entry});

  final LoggedExerciseWithDetails entry;

  Future<void> _addSet(BuildContext context, WidgetRef ref) async {
    final sets = ref.read(setsProvider(entry.logged.id)).valueOrNull ?? [];
    final lastSet = sets.isEmpty ? null : sets.last;
    final result = await SetFormDialog.show(
      context,
      exerciseName: entry.exercise.name,
      setNumber: sets.length + 1,
      initialWeightKg: lastSet?.weightKg,
      initialReps: lastSet?.reps,
      initialRpe: lastSet?.rpe,
    );
    if (result == null) return;
    await ref.read(workoutRepositoryProvider).addSet(
          loggedExerciseId: entry.logged.id,
          weightKg: result.weightKg,
          reps: result.reps,
          rpe: result.rpe,
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
    final setsAsync = ref.watch(setsProvider(entry.logged.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              entry.exercise.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: entry.exercise.equipment == null
                ? null
                : Text(entry.exercise.equipment!),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') _removeExercise(ref);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'remove',
                  child: Text('Eliminar ejercicio'),
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
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Aún no hay series'),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < sets.length; i++)
                    _SetTile(
                      index: i + 1,
                      set: sets[i],
                      onDelete: () => _deleteSet(ref, sets[i].id),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addSet(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Añadir serie'),
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
    required this.index,
    required this.set,
    required this.onDelete,
  });

  final int index;
  final LoggedSetRow set;
  final VoidCallback onDelete;

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final rpeText = set.rpe == null ? '' : '  ·  RPE ${set.rpe}';
    return Dismissible(
      key: ValueKey(set.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          child: Text(
            '$index',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        title: Text(
          '${_formatWeight(set.weightKg)} kg  ×  ${set.reps}$rpeText',
        ),
      ),
    );
  }
}
