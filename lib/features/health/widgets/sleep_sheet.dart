import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/health_providers.dart';

class SleepSheet {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
  ) {
    final existing = ref.read(healthProvider).sleepFor(day);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SleepForm(
        day: day,
        initialMinutes: existing?.minutes ?? 480,
        initialQuality: existing?.quality ?? 3,
      ),
    );
  }
}

class _SleepForm extends ConsumerStatefulWidget {
  const _SleepForm({
    required this.day,
    required this.initialMinutes,
    required this.initialQuality,
  });

  final DateTime day;
  final int initialMinutes;
  final int initialQuality;

  @override
  ConsumerState<_SleepForm> createState() => _SleepFormState();
}

class _SleepFormState extends ConsumerState<_SleepForm> {
  late double _minutes;
  late int _quality;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes.toDouble();
    _quality = widget.initialQuality;
  }

  String _fmt(double m) {
    final h = m ~/ 60;
    final mm = (m % 60).toInt();
    if (mm == 0) return '${h}h';
    return '${h}h ${mm}min';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const blue = Color(0xFF60A5FA);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sueño',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              _fmt(_minutes),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: blue,
                  ),
            ),
          ),
          Slider(
            value: _minutes,
            min: 0,
            max: 720, // 12h
            divisions: 48, // pasos de 15min
            activeColor: blue,
            onChanged: (v) => setState(() => _minutes = v),
          ),
          const SizedBox(height: 12),
          Text(
            'Calidad',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _quality = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= _quality
                          ? blue.withValues(alpha: 0.18)
                          : scheme.surfaceContainerHigh,
                      border: Border.all(
                        color: i == _quality ? blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      i <= _quality
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i <= _quality ? blue : scheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref.read(healthProvider.notifier).setSleep(
                      widget.day,
                      _minutes.round(),
                      _quality,
                    );
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
