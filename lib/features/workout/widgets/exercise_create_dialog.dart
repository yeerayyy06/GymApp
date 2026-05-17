import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/domain/muscle_group.dart';
import '../providers/workout_providers.dart';

class ExerciseCreateDialog extends ConsumerStatefulWidget {
  const ExerciseCreateDialog({super.key});

  static Future<ExerciseRow?> show(BuildContext context) {
    return showDialog<ExerciseRow>(
      context: context,
      builder: (_) => const ExerciseCreateDialog(),
    );
  }

  @override
  ConsumerState<ExerciseCreateDialog> createState() =>
      _ExerciseCreateDialogState();
}

class _ExerciseCreateDialogState extends ConsumerState<ExerciseCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _equipmentController = TextEditingController();
  MuscleGroup? _primaryMuscle;
  bool _isCompound = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_primaryMuscle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un grupo muscular')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final exercise =
          await ref.read(workoutRepositoryProvider).createExercise(
                name: _nameController.text.trim(),
                primaryMuscles: [_primaryMuscle!],
                equipment: _equipmentController.text.trim().isEmpty
                    ? null
                    : _equipmentController.text.trim(),
                isCompound: _isCompound,
              );
      if (!mounted) return;
      Navigator.of(context).pop(exercise);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo ejercicio'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Press inclinado mancuerna',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MuscleGroup>(
                initialValue: _primaryMuscle,
                decoration: const InputDecoration(
                  labelText: 'Grupo muscular principal',
                ),
                items: [
                  for (final m in MuscleGroup.values)
                    DropdownMenuItem(value: m, child: Text(m.displayName)),
                ],
                onChanged: (value) => setState(() => _primaryMuscle = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _equipmentController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Equipamiento (opcional)',
                  hintText: 'Mancuernas, barra, polea...',
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                value: _isCompound,
                onChanged: (v) => setState(() => _isCompound = v),
                title: const Text('Multiarticular'),
                subtitle: const Text('Involucra más de una articulación'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '…' : 'Crear'),
        ),
      ],
    );
  }
}
