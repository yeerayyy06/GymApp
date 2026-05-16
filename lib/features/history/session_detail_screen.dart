import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/one_rep_max.dart';
import '../workout/providers/workout_providers.dart';
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
        title: const Text(
          'Entrenamiento',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
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
      bottomNavigationBar: _RepeatBar(
        sessionId: sessionId,
        detail: detailAsync.valueOrNull,
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

class _RepeatBar extends ConsumerWidget {
  const _RepeatBar({required this.sessionId, required this.detail});

  final String sessionId;
  final SessionDetail? detail;

  Future<void> _onRepeat(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(workoutRepositoryProvider);
    final active = await repo.getActiveSession();
    if (!context.mounted) return;
    if (active != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Hay una sesión en curso'),
          content: const Text(
            'Para repetir este entrenamiento se descartará la sesión activa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Descartar y repetir'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!context.mounted) return;
      await repo.cancelSession(active.id);
    }
    if (!context.mounted) return;
    await repo.repeatSession(sessionId);
    if (!context.mounted) return;
    context.go('/workout');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (detail == null || detail!.exercises.isEmpty) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _onRepeat(context, ref),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Repetir entrenamiento'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.allPRs});

  final SessionDetail detail;
  final Map<String, ExercisePRs> allPRs;

  @override
  Widget build(BuildContext context) {
    final session = detail.session;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ── Session summary header ──
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.12),
                scheme.tertiary.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formatDate(session.startedAt)} · ${formatTime(session.startedAt)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SummaryStat(
                    icon: Icons.timer_outlined,
                    value: formatDuration(detail.duration),
                    label: 'Duración',
                    color: scheme.primary,
                  ),
                  _SummaryStat(
                    icon: Icons.scale,
                    value: formatVolume(detail.totalVolumeKg),
                    label: 'Volumen',
                    color: scheme.secondary,
                  ),
                  _SummaryStat(
                    icon: Icons.format_list_numbered,
                    value: '${detail.totalSets}',
                    label: 'Series',
                    color: scheme.tertiary,
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
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: -0.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 2),
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
    final scheme = Theme.of(context).colorScheme;
    final setRows = <Widget>[];
    var workingCounter = 0;
    for (final set in detail.sets) {
      final label = set.isWarmup ? null : (++workingCounter).toString();
      setRows.add(_SetRow(label: label, set: set, prs: prs));
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHigh,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push(
              '/history/exercise/${detail.exercise.id}',
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.exercise.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${detail.sets.length} series · '
                          '${formatVolume(detail.exerciseVolumeKg)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
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
          if (detail.sets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Sin series registradas'),
            ),
          ...setRows,
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.label,
    required this.set,
    required this.prs,
  });

  final String? label;
  final LoggedSetRow set;
  final ExercisePRs? prs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final est1RM = estimatedOneRepMax(weightKg: set.weightKg, reps: set.reps);
    final isWeightPR = !set.isWarmup &&
        prs != null &&
        set.weightKg >= prs!.bestWeightKg - 0.001;
    final is1RMPR = !set.isWarmup &&
        prs != null &&
        est1RM >= prs!.bestEst1RMKg - 0.001;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Center(
              child: label == null
                  ? Text(
                      'W',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.tertiary,
                              ),
                    )
                  : Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label!,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${formatWeightKg(set.weightKg)}  ×  ${set.reps}'
              '${set.rpe == null ? '' : '  ·  RPE ${set.rpe}'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (is1RMPR)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: PRBadge(label: '1RM'),
            )
          else if (isWeightPR)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: PRBadge(label: 'PESO'),
            ),
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHigh,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sticky_note_2_outlined,
                  size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Notas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                  icon: const Icon(Icons.edit, size: 14),
                  label: Text(notes.isEmpty ? 'Añadir' : 'Editar'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (_isEditing)
            TextField(
              controller: _controller,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                      color: notes.isEmpty
                          ? scheme.onSurfaceVariant
                          : null,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
