import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:file_saver/file_saver.dart';

import '../database/app_database.dart';

class CsvExportService {
  CsvExportService(this._db);

  final AppDatabase _db;

  /// Exporta todas las sesiones (no borradas) con sus ejercicios y
  /// series a un CSV plano. Cada fila = un set.
  Future<int> exportSessions() async {
    final query = _db.select(_db.workoutSessions).join([
      innerJoin(
        _db.loggedExercises,
        _db.loggedExercises.sessionId.equalsExp(_db.workoutSessions.id),
      ),
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.loggedExercises.exerciseId),
      ),
      innerJoin(
        _db.loggedSets,
        _db.loggedSets.loggedExerciseId
            .equalsExp(_db.loggedExercises.id),
      ),
    ])
      ..where(
        _db.workoutSessions.deletedAt.isNull() &
            _db.loggedExercises.deletedAt.isNull() &
            _db.loggedSets.deletedAt.isNull(),
      )
      ..orderBy([
        OrderingTerm.asc(_db.workoutSessions.startedAt),
        OrderingTerm.asc(_db.loggedExercises.orderInSession),
        OrderingTerm.asc(_db.loggedSets.setNumber),
      ]);

    final rows = await query.get();

    final buf = StringBuffer();
    buf.writeln(
      'session_id,session_started_at,session_ended_at,exercise_id,exercise_name,'
      'set_number,is_warmup,weight_kg,reps,rpe,completed_at,session_notes',
    );
    for (final row in rows) {
      final session = row.readTable(_db.workoutSessions);
      final ex = row.readTable(_db.exercises);
      final set = row.readTable(_db.loggedSets);
      buf.writeln([
        _csv(session.id),
        _csv(session.startedAt.toIso8601String()),
        _csv(session.endedAt?.toIso8601String() ?? ''),
        _csv(ex.id),
        _csv(ex.name),
        set.setNumber,
        set.isWarmup ? 1 : 0,
        set.weightKg,
        set.reps,
        set.rpe ?? '',
        _csv(set.completedAt?.toIso8601String() ?? ''),
        _csv(session.notes ?? ''),
      ].join(','));
    }

    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    await FileSaver.instance.saveFile(
      name: 'gym_tracker_$stamp',
      bytes: Uint8List.fromList(utf8.encode(buf.toString())),
      ext: 'csv',
      mimeType: MimeType.csv,
    );

    return rows.length;
  }

  /// Exporta el historial de peso corporal a CSV.
  Future<int> exportBodyweight() async {
    final rows = await (_db.select(_db.bodyweightEntries)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.measuredAt)]))
        .get();

    final buf = StringBuffer();
    buf.writeln('id,measured_at,weight_kg');
    for (final r in rows) {
      buf.writeln([
        _csv(r.id),
        _csv(r.measuredAt.toIso8601String()),
        r.weightKg,
      ].join(','));
    }

    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    await FileSaver.instance.saveFile(
      name: 'gym_tracker_bodyweight_$stamp',
      bytes: Uint8List.fromList(utf8.encode(buf.toString())),
      ext: 'csv',
      mimeType: MimeType.csv,
    );
    return rows.length;
  }

  String _csv(String value) {
    // Escapa comillas dobles + envuelve si lleva coma o salto de línea
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}
