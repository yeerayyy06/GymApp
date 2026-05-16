import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/domain/muscle_group.dart';
import '../providers/workout_providers.dart';

class ExercisePickerSheet extends ConsumerStatefulWidget {
  const ExercisePickerSheet({super.key});

  static Future<ExerciseRow?> show(BuildContext context) {
    return showModalBottomSheet<ExerciseRow>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const ExercisePickerSheet(),
    );
  }

  @override
  ConsumerState<ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Añadir ejercicio',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: false,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: exercisesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text('Error: $error')),
                  data: (exercises) {
                    final filtered = _query.isEmpty
                        ? exercises
                        : exercises
                            .where((e) =>
                                e.name.toLowerCase().contains(_query))
                            .toList(growable: false);
                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No hay ejercicios que coincidan'),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        return ListTile(
                          title: Text(exercise.name),
                          subtitle: Text(
                            exercise.primaryMuscles
                                .map((m) => m.displayName)
                                .join(', '),
                          ),
                          trailing: exercise.equipment == null
                              ? null
                              : Text(
                                  exercise.equipment!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                          onTap: () => Navigator.of(context).pop(exercise),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
