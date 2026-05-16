import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/id_provider.dart';
import 'routine_models.dart';

class RoutineRepository {
  RoutineRepository({
    required AppDatabase database,
    required Clock clock,
    required IdGenerator idGenerator,
  })  : _db = database,
        _clock = clock,
        _idGenerator = idGenerator;

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _idGenerator;

  Stream<List<RoutineWithExercises>> watchRoutines() {
    final routines = _db.routines;
    final days = _db.routineDays;
    final routineExercises = _db.routineExercises;
    final exercises = _db.exercises;

    final query = _db.select(routines).join([
      leftOuterJoin(
        days,
        days.routineId.equalsExp(routines.id) & days.deletedAt.isNull(),
      ),
      leftOuterJoin(
        routineExercises,
        routineExercises.routineDayId.equalsExp(days.id) &
            routineExercises.deletedAt.isNull(),
      ),
      leftOuterJoin(
        exercises,
        exercises.id.equalsExp(routineExercises.exerciseId),
      ),
    ])
      ..where(routines.deletedAt.isNull() & routines.isArchived.equals(false))
      ..orderBy([
        OrderingTerm.desc(routines.updatedAt),
        OrderingTerm.asc(days.orderInRoutine),
        OrderingTerm.asc(routineExercises.orderInDay),
      ]);

    return query.watch().map((rows) {
      final accs = <String, _RoutineAcc>{};
      for (final row in rows) {
        final routine = row.readTable(routines);
        final day = row.readTableOrNull(days);
        final re = row.readTableOrNull(routineExercises);
        final ex = row.readTableOrNull(exercises);

        final acc = accs.putIfAbsent(routine.id, () => _RoutineAcc(routine));
        if (day != null) acc.dayId ??= day.id;
        if (re != null && ex != null && acc.seenExerciseIds.add(re.id)) {
          acc.exercises.add(
            RoutineExerciseWithDetails(routineExercise: re, exercise: ex),
          );
        }
      }
      return accs.values.map((a) => a.build()).toList(growable: false);
    });
  }

  Future<RoutineWithExercises?> getRoutine(String routineId) async {
    final routines = _db.routines;
    final days = _db.routineDays;
    final routineExercises = _db.routineExercises;
    final exercises = _db.exercises;

    final query = _db.select(routines).join([
      leftOuterJoin(
        days,
        days.routineId.equalsExp(routines.id) & days.deletedAt.isNull(),
      ),
      leftOuterJoin(
        routineExercises,
        routineExercises.routineDayId.equalsExp(days.id) &
            routineExercises.deletedAt.isNull(),
      ),
      leftOuterJoin(
        exercises,
        exercises.id.equalsExp(routineExercises.exerciseId),
      ),
    ])
      ..where(routines.id.equals(routineId) & routines.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.asc(days.orderInRoutine),
        OrderingTerm.asc(routineExercises.orderInDay),
      ]);

    final rows = await query.get();
    if (rows.isEmpty) return null;

    final routine = rows.first.readTable(routines);
    final acc = _RoutineAcc(routine);
    for (final row in rows) {
      final day = row.readTableOrNull(days);
      final re = row.readTableOrNull(routineExercises);
      final ex = row.readTableOrNull(exercises);
      if (day != null) acc.dayId ??= day.id;
      if (re != null && ex != null && acc.seenExerciseIds.add(re.id)) {
        acc.exercises.add(
          RoutineExerciseWithDetails(routineExercise: re, exercise: ex),
        );
      }
    }
    return acc.build();
  }

  Future<String> createRoutine({
    required String name,
    String? description,
    required List<RoutineExerciseDraft> exercises,
  }) async {
    final now = _clock();
    final routineId = _idGenerator();
    final dayId = _idGenerator();

    await _db.transaction(() async {
      await _db.into(_db.routines).insert(
            RoutinesCompanion.insert(
              id: routineId,
              name: name,
              description: Value(description),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db.into(_db.routineDays).insert(
            RoutineDaysCompanion.insert(
              id: dayId,
              routineId: routineId,
              name: 'Día único',
              orderInRoutine: 0,
              createdAt: now,
              updatedAt: now,
            ),
          );
      for (var i = 0; i < exercises.length; i++) {
        final e = exercises[i];
        await _db.into(_db.routineExercises).insert(
              RoutineExercisesCompanion.insert(
                id: _idGenerator(),
                routineDayId: dayId,
                exerciseId: e.exerciseId,
                orderInDay: i,
                targetSets: e.targetSets,
                targetRepsMin: e.targetRepsMin,
                targetRepsMax: e.targetRepsMax,
                notes: Value(e.notes),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });

    return routineId;
  }

  Future<void> updateRoutine({
    required String routineId,
    required String name,
    String? description,
    required List<RoutineExerciseDraft> exercises,
  }) async {
    final now = _clock();

    await _db.transaction(() async {
      await (_db.update(_db.routines)
            ..where((t) => t.id.equals(routineId)))
          .write(
        RoutinesCompanion(
          name: Value(name),
          description: Value(description),
          updatedAt: Value(now),
        ),
      );

      final day = await (_db.select(_db.routineDays)
            ..where((t) =>
                t.routineId.equals(routineId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.orderInRoutine)])
            ..limit(1))
          .getSingleOrNull();

      final String dayId;
      if (day == null) {
        dayId = _idGenerator();
        await _db.into(_db.routineDays).insert(
              RoutineDaysCompanion.insert(
                id: dayId,
                routineId: routineId,
                name: 'Día único',
                orderInRoutine: 0,
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        dayId = day.id;
        await (_db.delete(_db.routineExercises)
              ..where((t) => t.routineDayId.equals(dayId)))
            .go();
      }

      for (var i = 0; i < exercises.length; i++) {
        final e = exercises[i];
        await _db.into(_db.routineExercises).insert(
              RoutineExercisesCompanion.insert(
                id: _idGenerator(),
                routineDayId: dayId,
                exerciseId: e.exerciseId,
                orderInDay: i,
                targetSets: e.targetSets,
                targetRepsMin: e.targetRepsMin,
                targetRepsMax: e.targetRepsMax,
                notes: Value(e.notes),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
  }

  Future<void> deleteRoutine(String routineId) async {
    final now = _clock();
    await (_db.update(_db.routines)..where((t) => t.id.equals(routineId)))
        .write(
      RoutinesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}

class _RoutineAcc {
  _RoutineAcc(this.routine);

  final RoutineRow routine;
  String? dayId;
  final List<RoutineExerciseWithDetails> exercises = [];
  final Set<String> seenExerciseIds = <String>{};

  RoutineWithExercises build() => RoutineWithExercises(
        routine: routine,
        dayId: dayId,
        exercises: exercises,
      );
}
