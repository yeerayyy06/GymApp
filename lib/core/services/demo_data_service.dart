import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../providers/clock_provider.dart';
import '../providers/id_provider.dart';

class DemoDataResult {
  const DemoDataResult({
    required this.sessions,
    required this.routines,
    required this.bodyweightEntries,
  });

  final int sessions;
  final int routines;
  final int bodyweightEntries;
}

class DemoDataService {
  DemoDataService({
    required AppDatabase db,
    required Clock clock,
    required IdGenerator idGenerator,
  })  : _db = db,
        _clock = clock,
        _idGen = idGenerator;

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _idGen;

  static const _routineTemplates = <String, List<_ExercisePlan>>{
    'Push A': [
      _ExercisePlan('Press de banca', baseKg: 50, increment: 1.0, working: 3, reps: [8, 7, 6]),
      _ExercisePlan('Press militar', baseKg: 30, increment: 0.5, working: 3, reps: [10, 8, 6]),
      _ExercisePlan('Elevaciones laterales', baseKg: 6, increment: 0.25, working: 3, reps: [12, 12, 10]),
      _ExercisePlan('Extensión de tríceps en polea', baseKg: 20, increment: 0.5, working: 3, reps: [12, 10, 10]),
    ],
    'Pull A': [
      _ExercisePlan('Dominadas', baseKg: 0, increment: 0.5, working: 3, reps: [8, 7, 6]),
      _ExercisePlan('Remo con barra', baseKg: 45, increment: 1.0, working: 3, reps: [8, 8, 8]),
      _ExercisePlan('Curl con barra', baseKg: 15, increment: 0.5, working: 3, reps: [10, 10, 8]),
    ],
    'Piernas A': [
      _ExercisePlan('Sentadilla', baseKg: 60, increment: 1.5, working: 3, reps: [8, 7, 6]),
      _ExercisePlan('Peso muerto', baseKg: 70, increment: 1.5, working: 3, reps: [6, 5, 5]),
      _ExercisePlan('Curl de pierna', baseKg: 25, increment: 0.5, working: 3, reps: [12, 10, 10]),
      _ExercisePlan('Elevaciones de gemelo', baseKg: 40, increment: 0.5, working: 4, reps: [15, 15, 12, 12]),
    ],
  };

  Future<DemoDataResult> generate({int days = 90}) async {
    final now = _clock();
    final rng = math.Random(7);

    final exercises = await _db.select(_db.exercises).get();
    final byName = <String, ExerciseRow>{
      for (final e in exercises) e.name.toLowerCase(): e,
    };

    int sessionCount = 0;
    int weightCount = 0;
    int routineCount = 0;

    await _db.transaction(() async {
      // ── Rutinas ──
      final routineNames = _routineTemplates.keys.toList();
      for (final name in routineNames) {
        final routineId = _idGen();
        final dayId = _idGen();
        await _db.into(_db.routines).insert(
              RoutinesCompanion.insert(
                id: routineId,
                name: name,
                description: const Value('Generada como datos de prueba'),
                createdAt: now.subtract(Duration(days: days)),
                updatedAt: now,
              ),
            );
        await _db.into(_db.routineDays).insert(
              RoutineDaysCompanion.insert(
                id: dayId,
                routineId: routineId,
                name: 'Día único',
                orderInRoutine: 0,
                createdAt: now.subtract(Duration(days: days)),
                updatedAt: now,
              ),
            );
        final plans = _routineTemplates[name]!;
        for (var i = 0; i < plans.length; i++) {
          final ex = byName[plans[i].exerciseName.toLowerCase()];
          if (ex == null) continue;
          await _db.into(_db.routineExercises).insert(
                RoutineExercisesCompanion.insert(
                  id: _idGen(),
                  routineDayId: dayId,
                  exerciseId: ex.id,
                  orderInDay: i,
                  targetSets: plans[i].working,
                  targetRepsMin: plans[i].reps.reduce(math.min),
                  targetRepsMax: plans[i].reps.reduce(math.max),
                  createdAt: now.subtract(Duration(days: days)),
                  updatedAt: now,
                ),
              );
        }
        routineCount++;
      }

      // ── Sesiones (4 por semana, P/P/L rotando, días intercalados) ──
      // 90 días / 1.75 = ~51 sesiones
      final intervalDays = 7 / 4;
      final totalSessions = (days / intervalDays).floor();
      for (var i = 0; i < totalSessions; i++) {
        final daysAgo = days - (i * intervalDays).round();
        if (daysAgo < 0) break;
        final routineName = routineNames[i % routineNames.length];
        final plans = _routineTemplates[routineName]!;
        final sessionIndexForRoutine = i ~/ routineNames.length;

        final base = now.subtract(Duration(days: daysAgo));
        final startedAt = DateTime(
          base.year,
          base.month,
          base.day,
          17 + rng.nextInt(3), // 17-19h
          rng.nextInt(60),
        );
        final durationMin = 45 + rng.nextInt(35); // 45-80 min
        final endedAt = startedAt.add(Duration(minutes: durationMin));

        final sessionId = _idGen();
        await _db.into(_db.workoutSessions).insert(
              WorkoutSessionsCompanion.insert(
                id: sessionId,
                startedAt: startedAt,
                endedAt: Value(endedAt),
                createdAt: startedAt,
                updatedAt: endedAt,
              ),
            );

        for (var exIdx = 0; exIdx < plans.length; exIdx++) {
          final plan = plans[exIdx];
          final ex = byName[plan.exerciseName.toLowerCase()];
          if (ex == null) continue;

          final loggedId = _idGen();
          await _db.into(_db.loggedExercises).insert(
                LoggedExercisesCompanion.insert(
                  id: loggedId,
                  sessionId: sessionId,
                  exerciseId: ex.id,
                  orderInSession: exIdx,
                  createdAt: startedAt,
                  updatedAt: startedAt,
                ),
              );

          final workingWeight = (plan.baseKg +
                  plan.increment * sessionIndexForRoutine) +
              (rng.nextDouble() - 0.5) * 1.0;
          final roundedWorking =
              (workingWeight * 2).round() / 2; // redondeo a 0.5

          var setNum = 1;

          // Warmup (40-60% del peso, salvo bodyweight)
          if (plan.baseKg > 0) {
            await _db.into(_db.loggedSets).insert(
                  LoggedSetsCompanion.insert(
                    id: _idGen(),
                    loggedExerciseId: loggedId,
                    setNumber: setNum++,
                    weightKg: (roundedWorking * 0.5 * 2).round() / 2,
                    reps: 10,
                    isWarmup: const Value(true),
                    completedAt: Value(startedAt),
                    createdAt: startedAt,
                    updatedAt: startedAt,
                  ),
                );
          }

          // Working sets
          for (var s = 0; s < plan.working; s++) {
            final reps = plan.reps[s.clamp(0, plan.reps.length - 1)];
            await _db.into(_db.loggedSets).insert(
                  LoggedSetsCompanion.insert(
                    id: _idGen(),
                    loggedExerciseId: loggedId,
                    setNumber: setNum++,
                    weightKg: roundedWorking,
                    reps: reps + (rng.nextDouble() < 0.2 ? 1 : 0),
                    rpe: Value<double?>(
                      7.0 + rng.nextInt(3).toDouble() * 0.5,
                    ),
                    completedAt: Value(startedAt.add(
                      Duration(minutes: exIdx * 8 + s * 2),
                    )),
                    createdAt: startedAt,
                    updatedAt: startedAt,
                  ),
                );
          }
        }
        sessionCount++;
      }

      // ── Peso corporal (2-3 entradas por semana, tendencia +3.5kg) ──
      const startWeight = 70.0;
      const endWeight = 73.5;
      final weightEntries = (days * 2.5 / 7).round();
      for (var i = 0; i < weightEntries; i++) {
        final progress = i / weightEntries;
        final daysAgo = days - (progress * days).round();
        final weight = startWeight +
            (endWeight - startWeight) * progress +
            (rng.nextDouble() - 0.5) * 0.8;
        final rounded = (weight * 10).round() / 10;
        final measuredAt = now.subtract(Duration(days: daysAgo, hours: 8));
        await _db.into(_db.bodyweightEntries).insert(
              BodyweightEntriesCompanion.insert(
                id: _idGen(),
                weightKg: rounded,
                measuredAt: measuredAt,
                createdAt: measuredAt,
                updatedAt: measuredAt,
              ),
            );
        weightCount++;
      }
    });

    return DemoDataResult(
      sessions: sessionCount,
      routines: routineCount,
      bodyweightEntries: weightCount,
    );
  }

  Future<void> clearAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.loggedSets).go();
      await _db.delete(_db.loggedExercises).go();
      await _db.delete(_db.workoutSessions).go();
      await _db.delete(_db.routineExercises).go();
      await _db.delete(_db.routineDays).go();
      await _db.delete(_db.routines).go();
      await _db.delete(_db.bodyweightEntries).go();
    });
  }
}

class _ExercisePlan {
  const _ExercisePlan(
    this.exerciseName, {
    required this.baseKg,
    required this.increment,
    required this.working,
    required this.reps,
  });

  final String exerciseName;
  final double baseKg;
  final double increment;
  final int working;
  final List<int> reps;
}
