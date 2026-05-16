import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/id_provider.dart';
import '../data/routine_models.dart';
import '../data/routine_repository.dart';

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository(
    database: ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
});

final routinesProvider =
    StreamProvider<List<RoutineWithExercises>>((ref) {
  return ref.watch(routineRepositoryProvider).watchRoutines();
});

final routineByIdProvider =
    FutureProvider.family<RoutineWithExercises?, String>((ref, id) {
  return ref.watch(routineRepositoryProvider).getRoutine(id);
});
