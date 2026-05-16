import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/catalog_source.dart';
import '../domain/muscle_group.dart';

class MuscleGroupListConverter
    extends TypeConverter<List<MuscleGroup>, String> {
  const MuscleGroupListConverter();

  @override
  List<MuscleGroup> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return decoded
        .cast<String>()
        .map((name) => MuscleGroup.values.byName(name))
        .toList(growable: false);
  }

  @override
  String toSql(List<MuscleGroup> value) =>
      jsonEncode(value.map((m) => m.name).toList());
}

class CatalogSourceConverter extends TypeConverter<CatalogSource, String> {
  const CatalogSourceConverter();

  @override
  CatalogSource fromSql(String fromDb) => CatalogSource.values.byName(fromDb);

  @override
  String toSql(CatalogSource value) => value.name;
}
