import 'package:drift/drift.dart';

import '../converters.dart';

@DataClassName('ExerciseRow')
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get primaryMuscles =>
      text().map(const MuscleGroupListConverter())();
  TextColumn get secondaryMuscles =>
      text().map(const MuscleGroupListConverter()).withDefault(
            const Constant('[]'),
          )();
  TextColumn get equipment => text().nullable()();
  TextColumn get source => text().map(const CatalogSourceConverter())();
  TextColumn get sourceId => text().nullable()();
  BoolColumn get isCompound =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
