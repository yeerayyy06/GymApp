import 'package:drift/drift.dart';

import '../domain/catalog_source.dart';
import '../domain/muscle_group.dart';
import 'app_database.dart';

class _ExerciseSeed {
  const _ExerciseSeed({
    required this.name,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    this.equipment,
    this.isCompound = false,
  });

  final String name;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final String? equipment;
  final bool isCompound;
}

const List<_ExerciseSeed> _seedExercises = [
  _ExerciseSeed(
    name: 'Sentadilla',
    primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.lowerBack],
    equipment: 'Barra',
    isCompound: true,
  ),
  _ExerciseSeed(
    name: 'Peso muerto',
    primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.lowerBack, MuscleGroup.lats, MuscleGroup.traps],
    equipment: 'Barra',
    isCompound: true,
  ),
  _ExerciseSeed(
    name: 'Press de banca',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.frontDelts],
    equipment: 'Barra',
    isCompound: true,
  ),
  _ExerciseSeed(
    name: 'Press militar',
    primaryMuscles: [MuscleGroup.frontDelts, MuscleGroup.sideDelts],
    secondaryMuscles: [MuscleGroup.triceps],
    equipment: 'Barra',
    isCompound: true,
  ),
  _ExerciseSeed(
    name: 'Dominadas',
    primaryMuscles: [MuscleGroup.lats],
    secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.rearDelts],
    equipment: 'Peso corporal',
    isCompound: true,
  ),
  _ExerciseSeed(
    name: 'Remo con barra',
    primaryMuscles: [MuscleGroup.upperBack, MuscleGroup.lats],
    secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.rearDelts],
    equipment: 'Barra',
    isCompound: true,
  ),
  _ExerciseSeed(
    name: 'Hip thrust',
    primaryMuscles: [MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings],
    equipment: 'Barra',
    isCompound: true,
  ),
  _ExerciseSeed(
    name: 'Curl con barra',
    primaryMuscles: [MuscleGroup.biceps],
    secondaryMuscles: [MuscleGroup.forearms],
    equipment: 'Barra',
  ),
  _ExerciseSeed(
    name: 'Extensión de tríceps en polea',
    primaryMuscles: [MuscleGroup.triceps],
    equipment: 'Polea',
  ),
  _ExerciseSeed(
    name: 'Elevaciones laterales',
    primaryMuscles: [MuscleGroup.sideDelts],
    equipment: 'Mancuernas',
  ),
  _ExerciseSeed(
    name: 'Curl de pierna',
    primaryMuscles: [MuscleGroup.hamstrings],
    equipment: 'Máquina',
  ),
  _ExerciseSeed(
    name: 'Elevaciones de gemelo',
    primaryMuscles: [MuscleGroup.calves],
    equipment: 'Máquina',
  ),
];

Future<void> seedExercisesIfEmpty({
  required AppDatabase db,
  required DateTime Function() now,
  required String Function() idGenerator,
}) async {
  final existing = await db.select(db.exercises).get();
  if (existing.isNotEmpty) return;

  final timestamp = now();
  await db.batch((batch) {
    for (final seed in _seedExercises) {
      batch.insert(
        db.exercises,
        ExercisesCompanion.insert(
          id: idGenerator(),
          name: seed.name,
          primaryMuscles: seed.primaryMuscles,
          secondaryMuscles: Value(seed.secondaryMuscles),
          equipment: Value(seed.equipment),
          source: CatalogSource.user,
          isCompound: Value(seed.isCompound),
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }
  });
}
