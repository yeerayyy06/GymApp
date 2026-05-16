import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'plate_calculator_dialog.dart';

class SetFormResult {
  const SetFormResult({
    required this.weightKg,
    required this.reps,
    this.rpe,
    this.isWarmup = false,
  });

  final double weightKg;
  final int reps;
  final double? rpe;
  final bool isWarmup;
}

class SetFormDialog extends StatefulWidget {
  const SetFormDialog({
    super.key,
    required this.exerciseName,
    required this.setNumber,
    this.initialWeightKg,
    this.initialReps,
    this.initialRpe,
    this.initialIsWarmup = false,
    this.isEditing = false,
  });

  final String exerciseName;
  final int setNumber;
  final double? initialWeightKg;
  final int? initialReps;
  final double? initialRpe;
  final bool initialIsWarmup;
  final bool isEditing;

  static Future<SetFormResult?> show(
    BuildContext context, {
    required String exerciseName,
    required int setNumber,
    double? initialWeightKg,
    int? initialReps,
    double? initialRpe,
    bool initialIsWarmup = false,
    bool isEditing = false,
  }) {
    return showDialog<SetFormResult>(
      context: context,
      builder: (_) => SetFormDialog(
        exerciseName: exerciseName,
        setNumber: setNumber,
        initialWeightKg: initialWeightKg,
        initialReps: initialReps,
        initialRpe: initialRpe,
        initialIsWarmup: initialIsWarmup,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<SetFormDialog> createState() => _SetFormDialogState();
}

class _SetFormDialogState extends State<SetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _rpeController;
  late bool _isWarmup;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.initialWeightKg?.toString() ?? '',
    );
    _repsController = TextEditingController(
      text: widget.initialReps?.toString() ?? '',
    );
    _rpeController = TextEditingController(
      text: widget.initialRpe?.toString() ?? '',
    );
    _isWarmup = widget.initialIsWarmup;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _rpeController.dispose();
    super.dispose();
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final weight = double.parse(_weightController.text.replaceAll(',', '.'));
    final reps = int.parse(_repsController.text);
    final rpeText = _rpeController.text.trim();
    final rpe =
        rpeText.isEmpty ? null : double.parse(rpeText.replaceAll(',', '.'));
    Navigator.of(context).pop(
      SetFormResult(
        weightKg: weight,
        reps: reps,
        rpe: rpe,
        isWarmup: _isWarmup,
      ),
    );
  }

  void _showPlateCalculator() {
    final parsed = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce un peso antes de calcular los discos'),
        ),
      );
      return;
    }
    PlateCalculatorDialog.show(context, targetWeightKg: parsed);
  }

  @override
  Widget build(BuildContext context) {
    final String title;
    if (widget.isEditing) {
      title = 'Editar serie · ${widget.exerciseName}';
    } else if (_isWarmup) {
      title = 'Calentamiento · ${widget.exerciseName}';
    } else {
      title = 'Serie ${widget.setNumber} · ${widget.exerciseName}';
    }
    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _weightController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Introduce el peso';
                }
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed < 0) {
                  return 'Peso inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Repeticiones',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Introduce las repeticiones';
                }
                final parsed = int.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return 'Valor inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rpeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'RPE (opcional)',
                border: OutlineInputBorder(),
                helperText: 'Escala 1-10',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed < 1 || parsed > 10) {
                  return 'RPE entre 1 y 10';
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              value: _isWarmup,
              onChanged: (value) => setState(() => _isWarmup = value),
              title: const Text('Calentamiento'),
              subtitle: const Text('No cuenta para PRs'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _showPlateCalculator,
                icon: const Icon(Icons.calculate_rounded, size: 16),
                label: const Text('Calculadora de discos'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
