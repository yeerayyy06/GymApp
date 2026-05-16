import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/one_rep_max.dart';
import 'data/history_models.dart';
import 'providers/history_providers.dart';
import 'widgets/pr_badge.dart';

class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(sessionDetailProvider(sessionId));
    final prsAsync = ref.watch(allTimePRsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamiento'),
        actions: [
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Sesión no encontrada'));
          }
          return _DetailBody(
            detail: detail,
            allPRs: prsAsync.valueOrNull ?? const {},
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar entrenamiento'),
        content: const Text(
          'Se eliminará la sesión y todas sus series. No se puede deshacer.',
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
    if (!context.mounted) return;
    await ref.read(historyRepositoryProvider).deleteSession(sessionId);
    if (!context.mounted) return;
    context.pop();
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.allPRs});

  final SessionDetail detail;
  final Map<String, ExercisePRs> allPRs;

  @override
  Widget build(BuildContext context) {
    final session = detail.session;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formatDate(session.startedAt)} · ${formatTime(session.startedAt)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SummaryStat(
                    icon: Icons.timer_outlined,
                    value: formatDuration(detail.duration),
                    label: 'Duración',
                  ),
                  _SummaryStat(
                    icon: Icons.scale,
                    value: formatVolume(detail.totalVolumeKg),
                    label: 'Volumen',
                  ),
                  _SummaryStat(
                    icon: Icons.format_list_numbered,
                    value: '${detail.totalSets}',
                    label: 'Series',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (detail.exercises.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Esta sesión no tiene ejercicios')),
          ),
        ...detail.exercises.map(
          (e) => _ExerciseSection(detail: e, prs: allPRs[e.exercise.id]),
        ),
        _NotesSection(session: session),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ExerciseSection extends StatelessWidget {
  const _ExerciseSection({required this.detail, required this.prs});

  final LoggedExerciseDetail detail;
  final ExercisePRs? prs;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push(
              '/history/exercise/${detail.exercise.id}',
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.exercise.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${detail.sets.length} series · '
                          '${formatVolume(detail.exerciseVolumeKg)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          if (detail.sets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Sin series registradas'),
            ),
          for (var i = 0; i < detail.sets.length; i++)
            _SetRow(
              index: i + 1,
              set: detail.sets[i],
              prs: prs,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.prs,
  });

  final int index;
  final LoggedSetRow set;
  final ExercisePRs? prs;

  @override
  Widget build(BuildContext context) {
    final est1RM = estimatedOneRepMax(weightKg: set.weightKg, reps: set.reps);
    final isWeightPR = !set.isWarmup &&
        prs != null &&
        set.weightKg >= prs!.bestWeightKg - 0.001;
    final is1RMPR = !set.isWarmup &&
        prs != null &&
        est1RM >= prs!.bestEst1RMKg - 0.001;
    final showPR = isWeightPR || is1RMPR;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Center(
              child: set.isWarmup
                  ? Text(
                      'W',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    )
                  : CircleAvatar(
                      radius: 12,
                      child: Text(
                        '$index',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${formatWeightKg(set.weightKg)}  ×  ${set.reps}'
              '${set.rpe == null ? '' : '  ·  RPE ${set.rpe}'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (showPR) ...[
            if (is1RMPR)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: PRBadge(label: '1RM'),
              ),
            if (isWeightPR && !is1RMPR)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: PRBadge(label: 'PESO'),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotesSection extends ConsumerStatefulWidget {
  const _NotesSection({required this.session});

  final WorkoutSessionRow session;

  @override
  ConsumerState<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends ConsumerState<_NotesSection> {
  late final TextEditingController _controller;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.session.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant _NotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing &&
        widget.session.notes != oldWidget.session.notes) {
      _controller.text = widget.session.notes ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await ref.read(historyRepositoryProvider).updateSessionNotes(
          widget.session.id,
          _controller.text,
        );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.session.notes ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Notas',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (_isEditing)
                TextButton(
                  onPressed: _isSaving ? null : _save,
                  child: const Text('Guardar'),
                )
              else
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(notes.isEmpty ? 'Añadir' : 'Editar'),
                ),
            ],
          ),
          if (_isEditing)
            TextField(
              controller: _controller,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Cómo te sentiste, sensaciones, técnica...',
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                notes.isEmpty ? 'Sin notas' : notes,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle:
                          notes.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
