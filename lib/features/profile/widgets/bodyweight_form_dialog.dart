import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/formatters.dart';

class BodyweightFormResult {
  const BodyweightFormResult({
    required this.weightKg,
    required this.measuredAt,
  });

  final double weightKg;
  final DateTime measuredAt;
}

class BodyweightFormDialog extends StatefulWidget {
  const BodyweightFormDialog({
    super.key,
    this.initialWeightKg,
    this.initialMeasuredAt,
    this.isEditing = false,
  });

  final double? initialWeightKg;
  final DateTime? initialMeasuredAt;
  final bool isEditing;

  static Future<BodyweightFormResult?> show(
    BuildContext context, {
    double? initialWeightKg,
    DateTime? initialMeasuredAt,
    bool isEditing = false,
  }) {
    return showDialog<BodyweightFormResult>(
      context: context,
      builder: (_) => BodyweightFormDialog(
        initialWeightKg: initialWeightKg,
        initialMeasuredAt: initialMeasuredAt,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<BodyweightFormDialog> createState() => _BodyweightFormDialogState();
}

class _BodyweightFormDialogState extends State<BodyweightFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late DateTime _measuredAt;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.initialWeightKg?.toString() ?? '',
    );
    _measuredAt = widget.initialMeasuredAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _measuredAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _measuredAt.hour,
        _measuredAt.minute,
      );
    });
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final weight = double.parse(_weightController.text.replaceAll(',', '.'));
    Navigator.of(context).pop(
      BodyweightFormResult(weightKg: weight, measuredAt: _measuredAt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Editar peso' : 'Registrar peso'),
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
                labelText: 'Peso corporal (kg)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Introduce el peso';
                }
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) return 'Peso inválido';
                if (parsed > 500) return 'Demasiado alto';
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text(formatDate(_measuredAt)),
                  ],
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
