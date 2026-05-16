import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_providers.dart';
import '../../core/services/settings_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SectionHeader(title: 'Entrenamiento', icon: Icons.fitness_center_rounded),
          _SettingsCard(
            children: [
              _RestSlider(
                seconds: settings.defaultRestSeconds,
                onChanged: (value) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setDefaultRestSeconds(value);
                },
              ),
              if (settings.exerciseRestSeconds.isNotEmpty) ...[
                Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                  height: 1,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Descansos por ejercicio',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _clearAllOverrides(ref),
                        child: const Text('Borrar todos'),
                      ),
                    ],
                  ),
                ),
                for (final entry in settings.exerciseRestSeconds.entries)
                  _ExerciseRestRow(
                    exerciseId: entry.key,
                    seconds: entry.value,
                  ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Unidades', icon: Icons.straighten_rounded),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peso',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<WeightUnit>(
                      segments: const [
                        ButtonSegment(
                          value: WeightUnit.kg,
                          label: Text('Kilogramos'),
                        ),
                        ButtonSegment(
                          value: WeightUnit.lbs,
                          label: Text('Libras'),
                        ),
                      ],
                      selected: {settings.weightUnit},
                      onSelectionChanged: (selected) async {
                        await ref
                            .read(settingsProvider.notifier)
                            .setWeightUnit(selected.first);
                      },
                      showSelectedIcon: false,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'De momento solo afecta a la etiqueta — los datos se guardan en kg.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Acerca de', icon: Icons.info_outline_rounded),
          _SettingsCard(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gym Tracker'),
                    SizedBox(height: 2),
                    Text(
                      'Registro de entrenamientos offline-first',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllOverrides(WidgetRef ref) async {
    final notifier = ref.read(settingsProvider.notifier);
    final ids = ref
        .read(settingsProvider)
        .exerciseRestSeconds
        .keys
        .toList(growable: false);
    for (final id in ids) {
      await notifier.setExerciseRestSeconds(id, null);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHigh,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _RestSlider extends StatelessWidget {
  const _RestSlider({required this.seconds, required this.onChanged});

  final int seconds;
  final Future<void> Function(int value) onChanged;

  String _format(int s) {
    final mm = s ~/ 60;
    final ss = s % 60;
    if (mm == 0) return '${ss}s';
    if (ss == 0) return '${mm}min';
    return '${mm}min ${ss}s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Descanso por defecto',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                _format(seconds),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                      letterSpacing: -0.2,
                    ),
              ),
            ],
          ),
          Slider(
            value: seconds.toDouble(),
            min: 30,
            max: 300,
            divisions: (300 - 30) ~/ 15,
            onChanged: (value) {
              onChanged(value.round());
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '30s',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                '5 min',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseRestRow extends ConsumerWidget {
  const _ExerciseRestRow({
    required this.exerciseId,
    required this.seconds,
  });

  final String exerciseId;
  final int seconds;

  String _format(int s) {
    final mm = s ~/ 60;
    final ss = s % 60;
    if (mm == 0) return '${ss}s';
    if (ss == 0) return '${mm}min';
    return '${mm}min ${ss}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              exerciseId,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _format(seconds),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          IconButton(
            tooltip: 'Quitar',
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () async {
              await ref
                  .read(settingsProvider.notifier)
                  .setExerciseRestSeconds(exerciseId, null);
            },
          ),
        ],
      ),
    );
  }
}
