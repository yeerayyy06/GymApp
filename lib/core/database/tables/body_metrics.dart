import 'package:drift/drift.dart';

@DataClassName('BodyweightEntryRow')
class BodyweightEntries extends Table {
  TextColumn get id => text()();
  RealColumn get weightKg => real()();
  DateTimeColumn get measuredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
