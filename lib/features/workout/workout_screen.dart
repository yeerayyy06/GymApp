import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/utils/formatters.dart';
import 'providers/workout_providers.dart';
import 'widgets/elapsed_timer.dart';
import 'widgets/exercise_picker_sheet.dart';
import 'widgets/logged_exercise_card.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Entrenar',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: const [_EndSessionAction()],
      ),
      body: bootstrap.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No se pudo inicializar la base de datos: $error'),
          ),
        ),
        data: (_) => const _WorkoutBody(),
      ),
    );
  }
}

class _EndSessionAction extends ConsumerWidget {
  const _EndSessionAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider).valueOrNull;
    if (session == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Finalizar entrenamiento',
      icon: const Icon(Icons.check_circle_rounded),
      onPressed: () => _confirmEnd(context, ref, session),
    );
  }

  Future<void> _confirmEnd(
    BuildContext context,
    WidgetRef ref,
    WorkoutSessionRow session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar entrenamiento'),
        content: const Text(
          '¿Quieres dar por terminada la sesión actual?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(workoutRepositoryProvider).endSession(session.id);
  }
}

class _WorkoutBody extends ConsumerWidget {
  const _WorkoutBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(activeSessionProvider);
    return sessionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (session) {
        if (session == null) return const _StartSessionView();
        return _ActiveSessionView(session: session);
      },
    );
  }
}

class _StartSessionView extends ConsumerWidget {
  const _StartSessionView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.18),
                    scheme.tertiary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 56,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Listo para entrenar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inicia una sesión para empezar a registrar ejercicios y series.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(workoutRepositoryProvider).startSession(),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Iniciar entrenamiento'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionView extends ConsumerWidget {
  const _ActiveSessionView({required this.session});

  final WorkoutSessionRow session;

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final picked = await ExercisePickerSheet.show(context);
    if (picked == null) return;
    await ref.read(workoutRepositoryProvider).addLoggedExercise(
          sessionId: session.id,
          exerciseId: picked.id,
        );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar entrenamiento'),
        content: const Text(
          'Se descartará la sesión actual y los datos registrados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(workoutRepositoryProvider).cancelSession(session.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final loggedAsync = ref.watch(loggedExercisesProvider(session.id));

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
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
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timer_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElapsedTimer(
                      startedAt: session.startedAt,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                    ),
                    Text(
                      'Iniciado a las ${formatTime(session.startedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _confirmCancel(context, ref),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.error,
                ),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: loggedAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 48,
                          color: scheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aún no has añadido ejercicios.\nPulsa el botón para empezar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return LoggedExerciseCard(entry: entries[index]);
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
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
                onPressed: () => _addExercise(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir ejercicio'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
