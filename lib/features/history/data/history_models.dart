import '../../../core/database/app_database.dart';
import '../../../core/domain/muscle_group.dart';

class ExerciseSummaryLine {
  const ExerciseSummaryLine({
    required this.name,
    required this.setCount,
  });

  final String name;
  final int setCount;
}

class SessionSummary {
  const SessionSummary({
    required this.session,
    required this.duration,
    required this.totalSets,
    required this.totalExercises,
    required this.totalVolumeKg,
    required this.exerciseNames,
    this.exerciseSummaries = const [],
    this.muscleGroups = const <MuscleGroup>{},
  });

  final WorkoutSessionRow session;
  final Duration duration;
  final int totalSets;
  final int totalExercises;
  final double totalVolumeKg;
  final List<String> exerciseNames;
  /// Exercise name + set count per exercise for rich card display.
  final List<ExerciseSummaryLine> exerciseSummaries;
  /// Conjunto de grupos musculares trabajados en la sesión (primarios).
  final Set<MuscleGroup> muscleGroups;
}

class SessionDetail {
  const SessionDetail({
    required this.session,
    required this.duration,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.exercises,
  });

  final WorkoutSessionRow session;
  final Duration duration;
  final int totalSets;
  final double totalVolumeKg;
  final List<LoggedExerciseDetail> exercises;
}

class LoggedExerciseDetail {
  const LoggedExerciseDetail({
    required this.logged,
    required this.exercise,
    required this.sets,
    required this.exerciseVolumeKg,
  });

  final LoggedExerciseRow logged;
  final ExerciseRow exercise;
  final List<LoggedSetRow> sets;
  final double exerciseVolumeKg;
}

class ExercisePRs {
  const ExercisePRs({
    required this.bestWeightKg,
    required this.bestEst1RMKg,
    required this.bestVolumeSetKg,
  });

  final double bestWeightKg;
  final double bestEst1RMKg;
  final double bestVolumeSetKg;
}

class HistoryStats {
  const HistoryStats({
    required this.totalSessions,
    required this.sessionsThisWeek,
    required this.sessionsThisMonth,
    required this.totalVolumeKg,
    required this.totalSets,
  });

  factory HistoryStats.empty() => const HistoryStats(
        totalSessions: 0,
        sessionsThisWeek: 0,
        sessionsThisMonth: 0,
        totalVolumeKg: 0,
        totalSets: 0,
      );

  final int totalSessions;
  final int sessionsThisWeek;
  final int sessionsThisMonth;
  final double totalVolumeKg;
  final int totalSets;
}

class ExerciseSessionEntry {
  const ExerciseSessionEntry({
    required this.session,
    required this.sets,
  });

  final WorkoutSessionRow session;
  final List<LoggedSetRow> sets;
}

class ExerciseHistory {
  const ExerciseHistory({
    required this.exercise,
    required this.entries,
    required this.prs,
    required this.totalSets,
  });

  final ExerciseRow exercise;
  final List<ExerciseSessionEntry> entries;
  final ExercisePRs? prs;
  final int totalSets;
}

class PrEvent {
  const PrEvent({
    required this.when,
    required this.exercise,
    required this.weightKg,
    required this.reps,
    required this.est1RM,
    required this.isWeightPR,
    required this.is1RMPR,
  });

  final DateTime when;
  final ExerciseRow exercise;
  final double weightKg;
  final int reps;
  final double est1RM;
  final bool isWeightPR;
  final bool is1RMPR;
}
