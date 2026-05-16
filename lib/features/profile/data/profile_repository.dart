import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/id_provider.dart';

class ProfileRepository {
  ProfileRepository({
    required AppDatabase database,
    required Clock clock,
    required IdGenerator idGenerator,
  })  : _db = database,
        _clock = clock,
        _idGenerator = idGenerator;

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _idGenerator;

  Stream<List<BodyweightEntryRow>> watchBodyweightEntries() {
    final query = _db.select(_db.bodyweightEntries)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)]);
    return query.watch();
  }

  Future<BodyweightEntryRow> addEntry({
    required double weightKg,
    DateTime? measuredAt,
  }) async {
    final now = _clock();
    final id = _idGenerator();
    await _db.into(_db.bodyweightEntries).insert(
          BodyweightEntriesCompanion.insert(
            id: id,
            weightKg: weightKg,
            measuredAt: measuredAt ?? now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (_db.select(_db.bodyweightEntries)
          ..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<void> updateEntry({
    required String id,
    required double weightKg,
    required DateTime measuredAt,
  }) async {
    final now = _clock();
    await (_db.update(_db.bodyweightEntries)
          ..where((t) => t.id.equals(id)))
        .write(
      BodyweightEntriesCompanion(
        weightKg: Value(weightKg),
        measuredAt: Value(measuredAt),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteEntry(String id) async {
    final now = _clock();
    await (_db.update(_db.bodyweightEntries)
          ..where((t) => t.id.equals(id)))
        .write(
      BodyweightEntriesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
