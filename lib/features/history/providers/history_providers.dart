import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/domain/muscle_group.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/formatters.dart';
import '../data/history_models.dart';
import '../data/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(
    database: ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  );
});

final sessionSummariesProvider =
    StreamProvider<List<SessionSummary>>((ref) {
  return ref.watch(historyRepositoryProvider).watchSessionSummaries();
});

final selectedDayProvider = StateProvider<DateTime?>((ref) => null);

final workoutDaysProvider = Provider<AsyncValue<Set<DateTime>>>((ref) {
  return ref.watch(sessionSummariesProvider).whenData((summaries) {
    return summaries
        .map((s) => startOfDay(s.session.startedAt))
        .toSet();
  });
});

final filteredSessionSummariesProvider =
    Provider<AsyncValue<List<SessionSummary>>>((ref) {
  final summariesAsync = ref.watch(sessionSummariesProvider);
  final selected = ref.watch(selectedDayProvider);
  return summariesAsync.whenData((summaries) {
    if (selected == null) return summaries;
    return summaries
        .where((s) => startOfDay(s.session.startedAt) == selected)
        .toList(growable: false);
  });
});

final historyStatsProvider = StreamProvider<HistoryStats>((ref) {
  return ref.watch(historyRepositoryProvider).watchHistoryStats();
});

final sessionDetailProvider =
    StreamProvider.family<SessionDetail?, String>((ref, sessionId) {
  return ref.watch(historyRepositoryProvider).watchSessionDetail(sessionId);
});

final allTimePRsProvider =
    StreamProvider<Map<String, ExercisePRs>>((ref) {
  return ref.watch(historyRepositoryProvider).watchAllTimePRs();
});

final exerciseHistoryProvider =
    StreamProvider.family<ExerciseHistory?, String>((ref, exerciseId) {
  return ref.watch(historyRepositoryProvider).watchExerciseHistory(exerciseId);
});

final recentPRsProvider = StreamProvider<List<PrEvent>>((ref) {
  return ref.watch(historyRepositoryProvider).watchRecentPRs(limit: 10);
});

/// Mapa fecha (startOfDay) → volumen total acumulado de todas las
/// sesiones completadas ese día. Calculado a partir de
/// sessionSummariesProvider.
final dailyVolumeProvider =
    Provider<AsyncValue<Map<DateTime, double>>>((ref) {
  final asyncSums = ref.watch(sessionSummariesProvider);
  return asyncSums.whenData((sums) {
    final byDay = <DateTime, double>{};
    for (final s in sums) {
      final day = startOfDay(s.session.startedAt);
      byDay[day] = (byDay[day] ?? 0) + s.totalVolumeKg;
    }
    return byDay;
  });
});

/// Volumen agregado por semana (últimas 8 semanas, lunes-domingo).
final weeklyVolumeProvider =
    Provider<AsyncValue<List<({DateTime weekStart, double volume})>>>((ref) {
  final asyncSums = ref.watch(sessionSummariesProvider);
  final now = ref.watch(clockProvider)();
  return asyncSums.whenData((sums) {
    final thisWeekStart = startOfWeek(now);
    final weeks = List.generate(8, (i) {
      return thisWeekStart.subtract(Duration(days: 7 * (7 - i)));
    });
    final byWeek = <DateTime, double>{};
    for (final s in sums) {
      final w = startOfWeek(s.session.startedAt);
      byWeek[w] = (byWeek[w] ?? 0) + s.totalVolumeKg;
    }
    return weeks
        .map((w) => (weekStart: w, volume: byWeek[w] ?? 0.0))
        .toList(growable: false);
  });
});

/// Racha actual: días consecutivos con entrenamiento desde hoy hacia
/// atrás (si hoy no hay sesión, mira a partir de ayer para no romper
/// la racha de buena mañana).
final currentStreakProvider = Provider<AsyncValue<int>>((ref) {
  final asyncByDay = ref.watch(dailyVolumeProvider);
  final clock = ref.watch(clockProvider);
  return asyncByDay.whenData((byDay) {
    final today = startOfDay(clock());
    var streak = 0;
    var cursor = today;
    if (!byDay.containsKey(today)) {
      cursor = today.subtract(const Duration(days: 1));
    }
    while ((byDay[cursor] ?? 0) > 0) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  });
});

final muscleVolumeWindowProvider = StateProvider<int>((_) => 7);

final volumeByMuscleProvider =
    StreamProvider<Map<MuscleGroup, double>>((ref) {
  final days = ref.watch(muscleVolumeWindowProvider);
  return ref
      .watch(historyRepositoryProvider)
      .watchVolumeByMuscleGroup(days: days);
});

typedef PreviousExerciseResult = ({
  DateTime sessionStartedAt,
  List<LoggedSetRow> sets,
})?;

final previousExerciseSetsProvider = FutureProvider.family<
    PreviousExerciseResult,
    ({String exerciseId, String? excludingSessionId})>((ref, args) {
  return ref.read(historyRepositoryProvider).getPreviousExerciseSets(
        exerciseId: args.exerciseId,
        excludingSessionId: args.excludingSessionId,
      );
});
