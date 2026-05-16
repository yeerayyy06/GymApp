import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import '../domain/catalog_source.dart';
import '../domain/muscle_group.dart';
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
  AppDatabase() : super(_openConnection());

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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'gym_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
