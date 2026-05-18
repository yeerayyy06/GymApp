import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../workout/widgets/exercise_picker_sheet.dart';
import 'data/routine_models.dart';
import 'providers/routine_providers.dart';

class RoutineEditScreen extends ConsumerStatefulWidget {
  const RoutineEditScreen({super.key, this.routineId});

  final String? routineId;

  bool get isEditing => routineId != null;

  @override
  ConsumerState<RoutineEditScreen> createState() =>
      _RoutineEditScreenState();
}

class _RoutineEditScreenState extends ConsumerState<RoutineEditScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<RoutineExerciseDraft> _exercises = [];
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _hydrateFrom(RoutineWithExercises r) {
    if (_loaded) return;
    _loaded = true;
    _nameController.text = r.routine.name;
    _descriptionController.text = r.routine.description ?? '';
    _exercises.clear();
    for (final e in r.exercises) {
      _exercises.add(RoutineExerciseDraft(
        exerciseId: e.exercise.id,
        exerciseName: e.exercise.name,
        targetSets: e.routineExercise.targetSets,
        targetRepsMin: e.routineExercise.targetRepsMin,
        targetRepsMax: e.routineExercise.targetRepsMax,
        notes: e.routineExercise.notes,
      ));
    }
  }

  Future<void> _addExercise() async {
    final picked = await ExercisePickerSheet.show(context);
    if (picked == null) return;
    setState(() {
      _exercises.add(RoutineExerciseDraft(
        exerciseId: picked.id,
        exerciseName: picked.name,
      ));
    });
  }

  Future<void> _editTargets(int index) async {
    final draft = _exercises[index];
    final updated = await showDialog<RoutineExerciseDraft>(
      context: context,
      builder: (_) => _TargetsDialog(initial: draft),
    );
    if (updated == null) return;
    setState(() {
      _exercises[index] = updated;
    });
  }

  void _remove(int index) {
    setState(() => _exercises.removeAt(index));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre a la rutina')),
      );
      return;
    }
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un ejercicio')),
      );
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(routineRepositoryProvider);
    final description = _descriptionController.text.trim();
    try {
      if (widget.isEditing) {
        await repo.updateRoutine(
          routineId: widget.routineId!,
          name: name,
          description: description.isEmpty ? null : description,
          exercises: _exercises,
        );
      } else {
        await repo.createRoutine(
          name: name,
          description: description.isEmpty ? null : description,
          exercises: _exercises,
        );
      }
      if (!mounted) return;
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && !_loaded) {
      final asyncRoutine = ref.watch(routineByIdProvider(widget.routineId!));
      return asyncRoutine.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        data: (r) {
          if (r == null) {
            return const Scaffold(
              body: Center(child: Text('Rutina no encontrada')),
            );
          }
          _hydrateFrom(r);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar rutina' : 'Nueva rutina',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '…' : 'Guardar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Push A',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notas (opcional)',
              hintText: 'Pecho, hombro frontal y tríceps',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                'Ejercicios',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
              ),
              const Spacer(),
              Text(
                '${_exercises.length}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_exercises.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Sin ejercicios. Pulsa el botón para añadir.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _exercises.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _exercises.removeAt(oldIndex);
                  _exercises.insert(newIndex, item);
                });
              },
              itemBuilder: (context, i) {
                final e = _exercises[i];
                return _ExerciseRow(
                  key: ValueKey('${e.exerciseId}-$i'),
                  draft: e,
                  index: i + 1,
                  reorderIndex: i,
                  onTap: () => _editTargets(i),
                  onDelete: () => _remove(i),
                );
              },
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Añadir ejercicio'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    super.key,
    required this.draft,
    required this.index,
    required this.reorderIndex,
    required this.onTap,
    required this.onDelete,
  });

  final RoutineExerciseDraft draft;
  final int index;
  final int reorderIndex;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final repsRange = draft.targetRepsMin == draft.targetRepsMax
        ? '${draft.targetRepsMin}'
        : '${draft.targetRepsMin}-${draft.targetRepsMax}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.exerciseName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${draft.targetSets} series · $repsRange reps',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: reorderIndex,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: scheme.error),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetsDialog extends StatefulWidget {
  const _TargetsDialog({required this.initial});

  final RoutineExerciseDraft initial;

  @override
  State<_TargetsDialog> createState() => _TargetsDialogState();
}

class _TargetsDialogState extends State<_TargetsDialog> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsMinController;
  late final TextEditingController _repsMaxController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _setsController =
        TextEditingController(text: widget.initial.targetSets.toString());
    _repsMinController =
        TextEditingController(text: widget.initial.targetRepsMin.toString());
    _repsMaxController =
        TextEditingController(text: widget.initial.targetRepsMax.toString());
    _notesController =
        TextEditingController(text: widget.initial.notes ?? '');
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsMinController.dispose();
    _repsMaxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final sets = int.tryParse(_setsController.text) ?? widget.initial.targetSets;
    final minR =
        int.tryParse(_repsMinController.text) ?? widget.initial.targetRepsMin;
    final maxR = int.tryParse(_repsMaxController.text) ??
        widget.initial.targetRepsMax;
    final notes = _notesController.text.trim();
    Navigator.of(context).pop(
      widget.initial.copyWith(
        targetSets: sets.clamp(1, 20),
        targetRepsMin: minR.clamp(1, 50),
        targetRepsMax: maxR.clamp(minR, 50),
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial.exerciseName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _setsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Series',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _repsMinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps min',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _repsMaxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps max',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
