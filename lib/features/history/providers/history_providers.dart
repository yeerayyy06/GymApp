import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/database_provider.dart';
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
