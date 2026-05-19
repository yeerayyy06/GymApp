import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_providers.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/settings_service.dart';
import '../../shared/widgets/blurred_dialog.dart';

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
              Divider(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              SwitchListTile(
                value: settings.restNotificationsEnabled,
                title: const Text('Notificaciones de descanso'),
                subtitle: Text(
                  WebNotificationService.isSupported
                      ? 'Aviso del navegador cuando el descanso acaba'
                      : 'No soportado en esta plataforma',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onChanged: WebNotificationService.isSupported
                    ? (value) async {
                        if (value) {
                          final granted =
                              await WebNotificationService.requestPermission();
                          if (!granted) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Permiso de notificaciones denegado por el navegador',
                                ),
                              ),
                            );
                            return;
                          }
                        }
                        await ref
                            .read(settingsProvider.notifier)
                            .setRestNotificationsEnabled(value);
                      }
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 0),
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
          _SectionHeader(title: 'Datos', icon: Icons.dataset_outlined),
          _SettingsCard(
            children: [
              _ActionTile(
                icon: Icons.download_rounded,
                title: 'Exportar sesiones (CSV)',
                subtitle: 'Descarga un archivo con todas tus series',
                onTap: () => _exportSessions(context, ref),
              ),
              Divider(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              _ActionTile(
                icon: Icons.monitor_weight_outlined,
                title: 'Exportar peso corporal (CSV)',
                subtitle: 'Tu historial de peso completo',
                onTap: () => _exportBodyweight(context, ref),
              ),
              Divider(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              _ActionTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Generar datos de prueba',
                subtitle: '90 días de sesiones + 3 rutinas + peso',
                onTap: () => _confirmGenerate(context, ref),
              ),
              Divider(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              _ActionTile(
                icon: Icons.delete_sweep_outlined,
                title: 'Borrar todos los datos',
                subtitle: 'Sesiones, rutinas y peso corporal',
                onTap: () => _confirmClear(context, ref),
                destructive: true,
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

  Future<void> _exportSessions(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Generando CSV…')),
    );
    try {
      final n = await ref.read(csvExportServiceProvider).exportSessions();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('$n series exportadas')),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo exportar: $e')),
      );
    }
  }

  Future<void> _exportBodyweight(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Generando CSV…')),
    );
    try {
      final n = await ref.read(csvExportServiceProvider).exportBodyweight();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('$n registros exportados')),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo exportar: $e')),
      );
    }
  }

  Future<void> _confirmGenerate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showBlurredDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Generar datos de prueba'),
        content: const Text(
          'Se añadirán 3 rutinas (Push / Pull / Piernas), unas 50 '
          'sesiones de los últimos 90 días con progresión realista, y '
          'unas 30 entradas de peso corporal. Los datos existentes se '
          'conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Generar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Generando datos…')),
    );
    final result =
        await ref.read(demoDataServiceProvider).generate(days: 90);
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.sessions} sesiones, ${result.routines} rutinas, '
          '${result.bodyweightEntries} pesos generados',
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showBlurredDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Borrar todos los datos'),
        content: const Text(
          'Se eliminarán sesiones, rutinas y registros de peso. Los '
          'ejercicios del catálogo se mantienen. Esta acción no se '
          'puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(demoDataServiceProvider).clearAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos borrados')),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: destructive ? scheme.error : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
