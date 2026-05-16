import 'package:drift/drift.dart';

import 'exercises.dart';

@DataClassName('RoutineRow')
class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RoutineDayRow')
class RoutineDays extends Table {
  TextColumn get id => text()();
  TextColumn get routineId =>
      text().references(Routines, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get orderInRoutine => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RoutineExerciseRow')
class RoutineExercises extends Table {
  TextColumn get id => text()();
  TextColumn get routineDayId =>
      text().references(RoutineDays, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId =>
      text().references(Exercises, #id, onDelete: KeyAction.restrict)();
  IntColumn get orderInDay => integer()();
  IntColumn get targetSets => integer()();
  IntColumn get targetRepsMin => integer()();
  IntColumn get targetRepsMax => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
