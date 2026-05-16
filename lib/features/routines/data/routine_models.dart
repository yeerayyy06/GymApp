import '../../../core/database/app_database.dart';

class RoutineExerciseDraft {
  const RoutineExerciseDraft({
    required this.exerciseId,
    required this.exerciseName,
    this.targetSets = 3,
    this.targetRepsMin = 8,
    this.targetRepsMax = 12,
    this.notes,
  });

  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetRepsMin;
  final int targetRepsMax;
  final String? notes;

  RoutineExerciseDraft copyWith({
    int? targetSets,
    int? targetRepsMin,
    int? targetRepsMax,
    String? notes,
  }) {
    return RoutineExerciseDraft(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      targetSets: targetSets ?? this.targetSets,
      targetRepsMin: targetRepsMin ?? this.targetRepsMin,
      targetRepsMax: targetRepsMax ?? this.targetRepsMax,
      notes: notes ?? this.notes,
    );
  }
}

class RoutineExerciseWithDetails {
  const RoutineExerciseWithDetails({
    required this.routineExercise,
    required this.exercise,
  });

  final RoutineExerciseRow routineExercise;
  final ExerciseRow exercise;
}

class RoutineWithExercises {
  const RoutineWithExercises({
    required this.routine,
    required this.dayId,
    required this.exercises,
  });

  final RoutineRow routine;
  final String? dayId;
  final List<RoutineExerciseWithDetails> exercises;

  int get exerciseCount => exercises.length;
  int get totalTargetSets =>
      exercises.fold(0, (sum, e) => sum + e.routineExercise.targetSets);
}
