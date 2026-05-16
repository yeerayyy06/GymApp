import 'package:drift/drift.dart';

import '../domain/catalog_source.dart';
import '../domain/muscle_group.dart';
import 'connection/connection.dart' as impl;
import 'converters.dart';
import 'tables/body_metrics.dart';
import 'tables/exercises.dart';
import 'tables/routines.dart';
import 'tables/sessions.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    Routines,
    RoutineDays,
    RoutineExercises,
    WorkoutSessions,
    LoggedExercises,
    LoggedSets,
    BodyweightEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
