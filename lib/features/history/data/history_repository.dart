import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/one_rep_max.dart';
import 'history_models.dart';

class HistoryRepository {
  HistoryRepository({
    required AppDatabase database,
    required Clock clock,
  })  : _db = database,
        _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  Stream<List<SessionSummary>> watchSessionSummaries() {
    final sessions = _db.workoutSessions;
    final loggedExercises = _db.loggedExercises;
    final exercises = _db.exercises;
    final loggedSets = _db.loggedSets;

    final query = _db.select(sessions).join([
      leftOuterJoin(
        loggedExercises,
        loggedExercises.sessionId.equalsExp(sessions.id) &
            loggedExercises.deletedAt.isNull(),
      ),
      leftOuterJoin(
        exercises,
        exercises.id.equalsExp(loggedExercises.exerciseId),
      ),
      leftOuterJoin(
        loggedSets,
        loggedSets.loggedExerciseId.equalsExp(loggedExercises.id) &
            loggedSets.deletedAt.isNull(),
      ),
    ])
      ..where(sessions.endedAt.isNotNull() & sessions.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.desc(sessions.startedAt),
        OrderingTerm.asc(loggedExercises.orderInSession),
        OrderingTerm.asc(loggedSets.setNumber),
      ]);

    return query.watch().map((rows) {
      final accs = <String, _SessionAcc>{};
      for (final row in rows) {
        final session = row.readTable(sessions);
        final acc = accs.putIfAbsent(session.id, () => _SessionAcc(session));
        final logged = row.readTableOrNull(loggedExercises);
        final exercise = row.readTableOrNull(exercises);
        final set = row.readTableOrNull(loggedSets);
        if (logged != null && exercise != null) {
          acc.exerciseOrder.putIfAbsent(logged.id, () => exercise.name);
        }
        if (set != null && acc.seenSetIds.add(set.id)) {
          acc.totalSets++;
          acc.totalVolumeKg += set.weightKg * set.reps;
        }
      }
      return accs.values.map((a) => a.build()).toList(growable: false);
    });
  }

  Stream<HistoryStats> watchHistoryStats() {
    final sessions = _db.workoutSessions;
    final loggedExercises = _db.loggedExercises;
    final loggedSets = _db.loggedSets;

    final query = _db.select(sessions).join([
      leftOuterJoin(
        loggedExercises,
        loggedExercises.sessionId.equalsExp(sessions.id) &
            loggedExercises.deletedAt.isNull(),
      ),
      leftOuterJoin(
        loggedSets,
        loggedSets.loggedExerciseId.equalsExp(loggedExercises.id) &
            loggedSets.deletedAt.isNull(),
      ),
    ])
      ..where(sessions.endedAt.isNotNull() & sessions.deletedAt.isNull());

    return query.watch().map((rows) {
      final now = _clock();
      final weekStart = startOfWeek(now);
      final monthStart = startOfMonth(now);
      final sessionIds = <String>{};
      final sessionsThisWeek = <String>{};
      final sessionsThisMonth = <String>{};
      final countedSetIds = <String>{};
      var totalVolume = 0.0;
      var totalSets = 0;

      for (final row in rows) {
        final session = row.readTable(sessions);
        sessionIds.add(session.id);
        if (!session.startedAt.isBefore(weekStart)) {
          sessionsThisWeek.add(session.id);
        }
        if (!session.startedAt.isBefore(monthStart)) {
          sessionsThisMonth.add(session.id);
        }
        final set = row.readTableOrNull(loggedSets);
        if (set != null && countedSetIds.add(set.id)) {
          totalSets++;
          totalVolume += set.weightKg * set.reps;
        }
      }

      return HistoryStats(
        totalSessions: sessionIds.length,
        sessionsThisWeek: sessionsThisWeek.length,
        sessionsThisMonth: sessionsThisMonth.length,
        totalVolumeKg: totalVolume,
        totalSets: totalSets,
      );
    });
  }

  Stream<SessionDetail?> watchSessionDetail(String sessionId) {
    final sessions = _db.workoutSessions;
    final loggedExercises = _db.loggedExercises;
    final exercises = _db.exercises;
    final loggedSets = _db.loggedSets;

    final query = _db.select(sessions).join([
      leftOuterJoin(
        loggedExercises,
        loggedExercises.sessionId.equalsExp(sessions.id) &
            loggedExercises.deletedAt.isNull(),
      ),
      leftOuterJoin(
        exercises,
        exercises.id.equalsExp(loggedExercises.exerciseId),
      ),
      leftOuterJoin(
        loggedSets,
        loggedSets.loggedExerciseId.equalsExp(loggedExercises.id) &
            loggedSets.deletedAt.isNull(),
      ),
    ])
      ..where(sessions.id.equals(sessionId) & sessions.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.asc(loggedExercises.orderInSession),
        OrderingTerm.asc(loggedSets.setNumber),
      ]);

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final session = rows.first.readTable(sessions);
      final orderedLogged = <String, _LoggedAcc>{};
      for (final row in rows) {
        final logged = row.readTableOrNull(loggedExercises);
        final exercise = row.readTableOrNull(exercises);
        if (logged == null || exercise == null) continue;
        final acc = orderedLogged.putIfAbsent(
          logged.id,
          () => _LoggedAcc(logged: logged, exercise: exercise),
        );
        final set = row.readTableOrNull(loggedSets);
        if (set != null && acc.seenSetIds.add(set.id)) {
          acc.sets.add(set);
          acc.volumeKg += set.weightKg * set.reps;
        }
      }
      final exercisesList = orderedLogged.values
          .map(
            (a) => LoggedExerciseDetail(
              logged: a.logged,
              exercise: a.exercise,
              sets: a.sets,
              exerciseVolumeKg: a.volumeKg,
            ),
          )
          .toList(growable: false);
      final totalSets = exercisesList.fold<int>(
        0,
        (sum, e) => sum + e.sets.length,
      );
      final totalVolume = exercisesList.fold<double>(
        0,
        (sum, e) => sum + e.exerciseVolumeKg,
      );
      final endedAt = session.endedAt ?? session.startedAt;
      return SessionDetail(
        session: session,
        duration: endedAt.difference(session.startedAt),
        totalSets: totalSets,
        totalVolumeKg: totalVolume,
        exercises: exercisesList,
      );
    });
  }

  Stream<Map<String, ExercisePRs>> watchAllTimePRs() {
    final loggedExercises = _db.loggedExercises;
    final loggedSets = _db.loggedSets;
    final sessions = _db.workoutSessions;

    final query = _db.select(loggedSets).join([
      innerJoin(
        loggedExercises,
        loggedExercises.id.equalsExp(loggedSets.loggedExerciseId),
      ),
      innerJoin(sessions, sessions.id.equalsExp(loggedExercises.sessionId)),
    ])
      ..where(
        loggedSets.deletedAt.isNull() &
            loggedSets.isWarmup.equals(false) &
            loggedExercises.deletedAt.isNull() &
            sessions.deletedAt.isNull(),
      );

    return query.watch().map((rows) {
      final byExercise = <String, ExercisePRs>{};
      for (final row in rows) {
        final set = row.readTable(loggedSets);
        final logged = row.readTable(loggedExercises);
        final est1RM =
            estimatedOneRepMax(weightKg: set.weightKg, reps: set.reps);
        final volume = set.weightKg * set.reps;
        final existing = byExercise[logged.exerciseId];
        if (existing == null) {
          byExercise[logged.exerciseId] = ExercisePRs(
            bestWeightKg: set.weightKg,
            bestEst1RMKg: est1RM,
            bestVolumeSetKg: volume,
          );
        } else {
          byExercise[logged.exerciseId] = ExercisePRs(
            bestWeightKg: math.max(existing.bestWeightKg, set.weightKg),
            bestEst1RMKg: math.max(existing.bestEst1RMKg, est1RM),
            bestVolumeSetKg: math.max(existing.bestVolumeSetKg, volume),
          );
        }
      }
      return byExercise;
    });
  }

  Stream<ExerciseHistory?> watchExerciseHistory(String exerciseId) {
    final exercises = _db.exercises;
    final loggedExercises = _db.loggedExercises;
    final loggedSets = _db.loggedSets;
    final sessions = _db.workoutSessions;

    final query = _db.select(loggedSets).join([
      innerJoin(
        loggedExercises,
        loggedExercises.id.equalsExp(loggedSets.loggedExerciseId),
      ),
      innerJoin(sessions, sessions.id.equalsExp(loggedExercises.sessionId)),
      innerJoin(exercises, exercises.id.equalsExp(loggedExercises.exerciseId)),
    ])
      ..where(
        loggedExercises.exerciseId.equals(exerciseId) &
            loggedSets.deletedAt.isNull() &
            loggedExercises.deletedAt.isNull() &
            sessions.deletedAt.isNull() &
            sessions.endedAt.isNotNull(),
      )
      ..orderBy([
        OrderingTerm.desc(sessions.startedAt),
        OrderingTerm.asc(loggedSets.setNumber),
      ]);

    final exerciseLookupQuery = _db.select(exercises)
      ..where((t) => t.id.equals(exerciseId));

    return query.watch().asyncMap((rows) async {
      final exercise = await exerciseLookupQuery.getSingleOrNull();
      if (exercise == null) return null;
      final entries = <String, _ExerciseEntryAcc>{};
      ExercisePRs? prs;
      var totalSets = 0;
      for (final row in rows) {
        final session = row.readTable(sessions);
        final set = row.readTable(loggedSets);
        final acc = entries.putIfAbsent(
          session.id,
          () => _ExerciseEntryAcc(session),
        );
        acc.sets.add(set);
        totalSets++;
        if (set.isWarmup) continue;
        final est1RM =
            estimatedOneRepMax(weightKg: set.weightKg, reps: set.reps);
        final volume = set.weightKg * set.reps;
        if (prs == null) {
          prs = ExercisePRs(
            bestWeightKg: set.weightKg,
            bestEst1RMKg: est1RM,
            bestVolumeSetKg: volume,
          );
        } else {
          prs = ExercisePRs(
            bestWeightKg: math.max(prs.bestWeightKg, set.weightKg),
            bestEst1RMKg: math.max(prs.bestEst1RMKg, est1RM),
            bestVolumeSetKg: math.max(prs.bestVolumeSetKg, volume),
          );
        }
      }
      return ExerciseHistory(
        exercise: exercise,
        entries: entries.values
            .map(
              (a) => ExerciseSessionEntry(session: a.session, sets: a.sets),
            )
            .toList(growable: false),
        prs: prs,
        totalSets: totalSets,
      );
    });
  }

  Future<void> deleteSession(String sessionId) async {
    final now = _clock();
    await (_db.update(_db.workoutSessions)
          ..where((t) => t.id.equals(sessionId)))
        .write(
      WorkoutSessionsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updateSessionNotes(String sessionId, String? notes) async {
    final now = _clock();
    final value = (notes == null || notes.trim().isEmpty)
        ? const Value<String?>(null)
        : Value<String?>(notes.trim());
    await (_db.update(_db.workoutSessions)
          ..where((t) => t.id.equals(sessionId)))
        .write(
      WorkoutSessionsCompanion(
        notes: value,
        updatedAt: Value(now),
      ),
    );
  }
}

class _SessionAcc {
  _SessionAcc(this.session);

  final WorkoutSessionRow session;
  final Map<String, String> exerciseOrder = {};
  final Set<String> seenSetIds = <String>{};
  int totalSets = 0;
  double totalVolumeKg = 0;

  SessionSummary build() {
    final endedAt = session.endedAt ?? session.startedAt;
    final names = exerciseOrder.values.toList(growable: false);
    return SessionSummary(
      session: session,
      duration: endedAt.difference(session.startedAt),
      totalSets: totalSets,
      totalExercises: names.length,
      totalVolumeKg: totalVolumeKg,
      exerciseNames: names,
    );
  }
}

class _LoggedAcc {
  _LoggedAcc({required this.logged, required this.exercise});

  final LoggedExerciseRow logged;
  final ExerciseRow exercise;
  final List<LoggedSetRow> sets = [];
  final Set<String> seenSetIds = <String>{};
  double volumeKg = 0;
}

class _ExerciseEntryAcc {
  _ExerciseEntryAcc(this.session);

  final WorkoutSessionRow session;
  final List<LoggedSetRow> sets = [];
}
