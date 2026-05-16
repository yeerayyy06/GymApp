import 'package:flutter/material.dart';

class PlateCalculatorDialog extends StatefulWidget {
  const PlateCalculatorDialog({
    super.key,
    required this.targetWeightKg,
    this.barWeightKg = 20.0,
  });

  final double targetWeightKg;
  final double barWeightKg;

  static Future<void> show(
    BuildContext context, {
    required double targetWeightKg,
    double barWeightKg = 20.0,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => PlateCalculatorDialog(
        targetWeightKg: targetWeightKg,
        barWeightKg: barWeightKg,
      ),
    );
  }

  @override
  State<PlateCalculatorDialog> createState() => _PlateCalculatorDialogState();
}

class _PlateCalculatorDialogState extends State<PlateCalculatorDialog> {
  static const List<double> _availablePlates = [
    25, 20, 15, 10, 5, 2.5, 1.25, 0.5,
  ];

  late double _barWeight;

  @override
  void initState() {
    super.initState();
    _barWeight = widget.barWeightKg;
  }

  List<double> _computePlatesPerSide(double target, double bar) {
    final perSide = (target - bar) / 2;
    if (perSide <= 0) return const [];
    final plates = <double>[];
    var remaining = perSide;
    for (final plate in _availablePlates) {
      while (remaining + 0.001 >= plate) {
        plates.add(plate);
        remaining -= plate;
      }
    }
    return plates;
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final plates = _computePlatesPerSide(widget.targetWeightKg, _barWeight);
    final perSide = plates.fold<double>(0, (sum, p) => sum + p);
    final achievable = _barWeight + perSide * 2;
    final missing = widget.targetWeightKg - achievable;
    final closeEnough = missing.abs() < 0.05;

    return AlertDialog(
      title: const Text('Calculadora de discos'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: scheme.primary.withValues(alpha: 0.08),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    'Objetivo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmt(widget.targetWeightKg)} kg',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: scheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Barra:',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 20.0, label: Text('20 kg')),
                      ButtonSegment(value: 15.0, label: Text('15')),
                      ButtonSegment(value: 10.0, label: Text('10')),
                      ButtonSegment(value: 7.0, label: Text('7')),
                      ButtonSegment(value: 0.0, label: Text('—')),
                    ],
                    selected: {_barWeight},
                    onSelectionChanged: (selected) {
                      setState(() => _barWeight = selected.first);
                    },
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (plates.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: scheme.errorContainer.withValues(alpha: 0.3),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: scheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _barWeight >= widget.targetWeightKg
                            ? 'La barra ya pesa ${_fmt(_barWeight)} kg, no necesitas discos.'
                            : 'El objetivo es menor que la barra.',
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'Por cada lado:',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final p in plates) _PlateChip(value: p, scheme: scheme),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '= ${_fmt(perSide)} kg por lado',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: scheme.surfaceContainerHigh,
                ),
                child: Row(
                  children: [
                    Icon(
                      closeEnough
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: closeEnough ? scheme.primary : scheme.tertiary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        closeEnough
                            ? 'Total: ${_fmt(achievable)} kg'
                            : 'Total alcanzable: ${_fmt(achievable)} kg '
                                '(${missing > 0 ? "faltan" : "sobran"} ${_fmt(missing.abs())} kg)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _PlateChip extends StatelessWidget {
  const _PlateChip({required this.value, required this.scheme});

  final double value;
  final ColorScheme scheme;

  Color _colorFor(double v) {
    if (v >= 25) return const Color(0xFFE53935);
    if (v >= 20) return const Color(0xFF1E88E5);
    if (v >= 15) return const Color(0xFFFDD835);
    if (v >= 10) return const Color(0xFF43A047);
    if (v >= 5) return const Color(0xFFECEFF1);
    return const Color(0xFF90A4AE);
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Text(
        '${_fmt(value)} kg',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
