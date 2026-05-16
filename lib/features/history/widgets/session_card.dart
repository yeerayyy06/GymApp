import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/utils/formatters.dart';
import '../data/history_models.dart';
import '../providers/history_providers.dart';

class SessionCard extends ConsumerWidget {
  const SessionCard({super.key, required this.summary});

  final SessionSummary summary;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar entrenamiento'),
        content: const Text(
          'Se eliminará la sesión y todas sus series. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(historyRepositoryProvider)
        .deleteSession(summary.session.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final session = summary.session;
    final relativeDate = formatRelativeDate(session.startedAt, now);
    final time = formatTime(session.startedAt);
    final displayedExercises = summary.exerciseNames.take(4).toList();
    final extraExercises = summary.exerciseNames.length - displayedExercises.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => context.push('/history/session/${session.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          relativeDate,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '$time  ·  ${formatDuration(summary.duration)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') _confirmDelete(context, ref);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.fitness_center,
                    label: '${summary.totalExercises} ejercicios',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.format_list_numbered,
                    label: '${summary.totalSets} series',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.scale,
                    label: formatVolume(summary.totalVolumeKg),
                  ),
                ],
              ),
              if (displayedExercises.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...displayedExercises.map(
                  (name) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      '•  $name',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                if (extraExercises > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 12),
                    child: Text(
                      '+$extraExercises más',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
