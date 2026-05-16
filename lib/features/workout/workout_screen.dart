import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import 'providers/workout_providers.dart';
import 'widgets/exercise_picker_sheet.dart';
import 'widgets/logged_exercise_card.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenar'),
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
      icon: const Icon(Icons.check_circle_outline),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, size: 72),
            const SizedBox(height: 16),
            Text(
              'Listo para entrenar',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Inicia una sesión para empezar a registrar ejercicios y series.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(workoutRepositoryProvider).startSession(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar entrenamiento'),
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

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

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
    final loggedAsync =
        ref.watch(loggedExercisesProvider(session.id));

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                'Sesión iniciada a las ${_formatTime(session.startedAt)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _confirmCancel(context, ref),
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
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aún no has añadido ejercicios.\nPulsa el botón para empezar.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _addExercise(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Añadir ejercicio'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
