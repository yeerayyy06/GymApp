import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/id_provider.dart';

class LoggedExerciseWithDetails {
  const LoggedExerciseWithDetails({
    required this.logged,
    required this.exercise,
  });

  final LoggedExerciseRow logged;
  final ExerciseRow exercise;
}

class WorkoutRepository {
  WorkoutRepository({
    required AppDatabase database,
    required Clock clock,
    required IdGenerator idGenerator,
  })  : _db = database,
        _clock = clock,
        _idGenerator = idGenerator;

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _idGenerator;

  Stream<List<ExerciseRow>> watchExercises() {
    final query = _db.select(_db.exercises)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  Stream<WorkoutSessionRow?> watchActiveSession() {
    final query = _db.select(_db.workoutSessions)
      ..where((t) => t.endedAt.isNull() & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Future<WorkoutSessionRow?> getActiveSession() {
    final query = _db.select(_db.workoutSessions)
      ..where((t) => t.endedAt.isNull() & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<WorkoutSessionRow> startSessionFromRoutine(String routineId) {
    return _db.transaction(() async {
      final day = await (_db.select(_db.routineDays)
            ..where((t) =>
                t.routineId.equals(routineId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.orderInRoutine)])
            ..limit(1))
          .getSingleOrNull();

      final now = _clock();
      final sessionId = _idGenerator();
      await _db.into(_db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: sessionId,
              startedAt: now,
              createdAt: now,
              updatedAt: now,
              routineDayId: Value(day?.id),
            ),
          );

      if (day != null) {
        final routineExercises = await (_db.select(_db.routineExercises)
              ..where((t) =>
                  t.routineDayId.equals(day.id) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.orderInDay)]))
            .get();
        for (var i = 0; i < routineExercises.length; i++) {
          await _db.into(_db.loggedExercises).insert(
                LoggedExercisesCompanion.insert(
                  id: _idGenerator(),
                  sessionId: sessionId,
                  exerciseId: routineExercises[i].exerciseId,
                  orderInSession: i,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }
      }

      return (_db.select(_db.workoutSessions)
            ..where((t) => t.id.equals(sessionId)))
          .getSingle();
    });
  }

  Future<WorkoutSessionRow> repeatSession(String sourceSessionId) {
    return _db.transaction(() async {
      final source = await (_db.select(_db.loggedExercises)
            ..where((t) =>
                t.sessionId.equals(sourceSessionId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.orderInSession)]))
          .get();
      final now = _clock();
      final newSessionId = _idGenerator();
      await _db.into(_db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: newSessionId,
              startedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
      for (var i = 0; i < source.length; i++) {
        await _db.into(_db.loggedExercises).insert(
              LoggedExercisesCompanion.insert(
                id: _idGenerator(),
                sessionId: newSessionId,
                exerciseId: source[i].exerciseId,
                orderInSession: i,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
      return (_db.select(_db.workoutSessions)
            ..where((t) => t.id.equals(newSessionId)))
          .getSingle();
    });
  }

  Future<WorkoutSessionRow> startSession() async {
    final now = _clock();
    final id = _idGenerator();
    await _db.into(_db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            id: id,
            startedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (_db.select(_db.workoutSessions)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<void> endSession(String sessionId) async {
    final now = _clock();
    await (_db.update(_db.workoutSessions)
          ..where((t) => t.id.equals(sessionId)))
        .write(
      WorkoutSessionsCompanion(
        endedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> cancelSession(String sessionId) async {
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

  Stream<List<LoggedExerciseWithDetails>> watchLoggedExercises(
    String sessionId,
  ) {
    final query = _db.select(_db.loggedExercises).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.loggedExercises.exerciseId),
      ),
    ])
      ..where(_db.loggedExercises.sessionId.equals(sessionId) &
          _db.loggedExercises.deletedAt.isNull())
      ..orderBy([OrderingTerm.asc(_db.loggedExercises.orderInSession)]);
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => LoggedExerciseWithDetails(
                  logged: row.readTable(_db.loggedExercises),
                  exercise: row.readTable(_db.exercises),
                ),
              )
              .toList(growable: false),
        );
  }

  Future<LoggedExerciseRow> addLoggedExercise({
    required String sessionId,
    required String exerciseId,
  }) async {
    final now = _clock();
    final existing = await (_db.select(_db.loggedExercises)
          ..where((t) =>
              t.sessionId.equals(sessionId) & t.deletedAt.isNull()))
        .get();
    final id = _idGenerator();
    await _db.into(_db.loggedExercises).insert(
          LoggedExercisesCompanion.insert(
            id: id,
            sessionId: sessionId,
            exerciseId: exerciseId,
            orderInSession: existing.length,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (_db.select(_db.loggedExercises)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<void> removeLoggedExercise(String loggedExerciseId) async {
    final now = _clock();
    await (_db.update(_db.loggedExercises)
          ..where((t) => t.id.equals(loggedExerciseId)))
        .write(
      LoggedExercisesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Stream<List<LoggedSetRow>> watchSets(String loggedExerciseId) {
    final query = _db.select(_db.loggedSets)
      ..where((t) =>
          t.loggedExerciseId.equals(loggedExerciseId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]);
    return query.watch();
  }

  Future<LoggedSetRow> addSet({
    required String loggedExerciseId,
    required double weightKg,
    required int reps,
    double? rpe,
    bool isWarmup = false,
  }) async {
    final now = _clock();
    final existing = await (_db.select(_db.loggedSets)
          ..where((t) =>
              t.loggedExerciseId.equals(loggedExerciseId) &
              t.deletedAt.isNull()))
        .get();
    final id = _idGenerator();
    await _db.into(_db.loggedSets).insert(
          LoggedSetsCompanion.insert(
            id: id,
            loggedExerciseId: loggedExerciseId,
            setNumber: existing.length + 1,
            weightKg: weightKg,
            reps: reps,
            rpe: Value(rpe),
            isWarmup: Value(isWarmup),
            completedAt: Value(now),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (_db.select(_db.loggedSets)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<void> deleteSet(String setId) async {
    final now = _clock();
    await (_db.update(_db.loggedSets)..where((t) => t.id.equals(setId)))
        .write(
      LoggedSetsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updateSet({
    required String setId,
    required double weightKg,
    required int reps,
    double? rpe,
    bool isWarmup = false,
  }) async {
    final now = _clock();
    await (_db.update(_db.loggedSets)..where((t) => t.id.equals(setId)))
        .write(
      LoggedSetsCompanion(
        weightKg: Value(weightKg),
        reps: Value(reps),
        rpe: Value(rpe),
        isWarmup: Value(isWarmup),
        updatedAt: Value(now),
      ),
    );
  }
}
