import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/seed.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/id_provider.dart';
import '../data/workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(
    database: ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
});

final bootstrapProvider = FutureProvider<void>((ref) async {
  await seedExercisesIfEmpty(
    db: ref.watch(databaseProvider),
    now: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
});

final exercisesProvider = StreamProvider<List<ExerciseRow>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchExercises();
});

final activeSessionProvider =
    StreamProvider<WorkoutSessionRow?>((ref) {
  return ref.watch(workoutRepositoryProvider).watchActiveSession();
});

final loggedExercisesProvider = StreamProvider.family<
    List<LoggedExerciseWithDetails>, String>((ref, sessionId) {
  return ref.watch(workoutRepositoryProvider).watchLoggedExercises(sessionId);
});

final setsProvider =
    StreamProvider.family<List<LoggedSetRow>, String>((ref, loggedExerciseId) {
  return ref.watch(workoutRepositoryProvider).watchSets(loggedExerciseId);
});
