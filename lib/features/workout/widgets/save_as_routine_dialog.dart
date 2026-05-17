import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routines/providers/routine_providers.dart';

class SaveAsRoutineDialog extends StatefulWidget {
  const SaveAsRoutineDialog({
    super.key,
    required this.ref,
    required this.sessionId,
  });

  final WidgetRef ref;
  final String sessionId;

  static Future<void> show(
    BuildContext context, {
    required WidgetRef ref,
    required String sessionId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => SaveAsRoutineDialog(ref: ref, sessionId: sessionId),
    );
  }

  @override
  State<SaveAsRoutineDialog> createState() => _SaveAsRoutineDialogState();
}

class _SaveAsRoutineDialogState extends State<SaveAsRoutineDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre a la rutina')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.ref
          .read(routineRepositoryProvider)
          .createRoutineFromSession(
            sessionId: widget.sessionId,
            name: name,
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rutina "$name" guardada')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Guardar como rutina'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Se creará una rutina con los ejercicios actuales y los rangos de '
            'series/reps de esta sesión.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Push A',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '…' : 'Guardar'),
        ),
      ],
    );
  }
}
