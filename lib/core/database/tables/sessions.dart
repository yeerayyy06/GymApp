import 'package:drift/drift.dart';

import 'exercises.dart';
import 'routines.dart';

@DataClassName('WorkoutSessionRow')
class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get routineDayId =>
      text().nullable().references(RoutineDays, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LoggedExerciseRow')
class LoggedExercises extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId =>
      text().references(Exercises, #id, onDelete: KeyAction.restrict)();
  IntColumn get orderInSession => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LoggedSetRow')
class LoggedSets extends Table {
  TextColumn get id => text()();
  TextColumn get loggedExerciseId => text()
      .references(LoggedExercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get setNumber => integer()();
  RealColumn get weightKg => real()();
  IntColumn get reps => integer()();
  RealColumn get rpe => real().nullable()();
  BoolColumn get isWarmup =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(true))();
  IntColumn get restSeconds => integer().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
