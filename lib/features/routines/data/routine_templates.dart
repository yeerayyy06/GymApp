/// Plantillas de rutinas preconfiguradas que el usuario puede instalar
/// con un tap. Los ejercicios se referencian por NOMBRE; al instalarlas
/// se buscan en la tabla de ejercicios. Si alguno no existe se omite
/// silenciosamente.
class RoutineTemplate {
  const RoutineTemplate({
    required this.name,
    required this.description,
    required this.exercises,
    this.icon = '🏋️',
    this.colorIndex = 0,
  });

  final String name;
  final String description;
  final List<RoutineTemplateExercise> exercises;
  final String icon;
  final int colorIndex;
}

class RoutineTemplateExercise {
  const RoutineTemplateExercise({
    required this.exerciseName,
    this.targetSets = 3,
    this.targetRepsMin = 8,
    this.targetRepsMax = 12,
  });

  final String exerciseName;
  final int targetSets;
  final int targetRepsMin;
  final int targetRepsMax;
}

const List<RoutineTemplate> routineTemplates = [
  RoutineTemplate(
    name: 'Push',
    description: 'Pecho, hombro y tríceps',
    icon: '💪',
    colorIndex: 0,
    exercises: [
      RoutineTemplateExercise(
          exerciseName: 'Press de banca',
          targetSets: 4,
          targetRepsMin: 6,
          targetRepsMax: 8),
      RoutineTemplateExercise(
          exerciseName: 'Press militar',
          targetSets: 3,
          targetRepsMin: 8,
          targetRepsMax: 10),
      RoutineTemplateExercise(
          exerciseName: 'Elevaciones laterales',
          targetSets: 3,
          targetRepsMin: 12,
          targetRepsMax: 15),
      RoutineTemplateExercise(
          exerciseName: 'Extensión de tríceps en polea',
          targetSets: 3,
          targetRepsMin: 10,
          targetRepsMax: 12),
    ],
  ),
  RoutineTemplate(
    name: 'Pull',
    description: 'Espalda y bíceps',
    icon: '🎯',
    colorIndex: 1,
    exercises: [
      RoutineTemplateExercise(
          exerciseName: 'Dominadas',
          targetSets: 4,
          targetRepsMin: 6,
          targetRepsMax: 10),
      RoutineTemplateExercise(
          exerciseName: 'Remo con barra',
          targetSets: 4,
          targetRepsMin: 8,
          targetRepsMax: 10),
      RoutineTemplateExercise(
          exerciseName: 'Curl con barra',
          targetSets: 3,
          targetRepsMin: 10,
          targetRepsMax: 12),
    ],
  ),
  RoutineTemplate(
    name: 'Piernas',
    description: 'Tren inferior completo',
    icon: '🦵',
    colorIndex: 2,
    exercises: [
      RoutineTemplateExercise(
          exerciseName: 'Sentadilla',
          targetSets: 4,
          targetRepsMin: 5,
          targetRepsMax: 8),
      RoutineTemplateExercise(
          exerciseName: 'Peso muerto',
          targetSets: 3,
          targetRepsMin: 5,
          targetRepsMax: 6),
      RoutineTemplateExercise(
          exerciseName: 'Hip thrust',
          targetSets: 3,
          targetRepsMin: 8,
          targetRepsMax: 10),
      RoutineTemplateExercise(
          exerciseName: 'Curl de pierna',
          targetSets: 3,
          targetRepsMin: 10,
          targetRepsMax: 12),
      RoutineTemplateExercise(
          exerciseName: 'Elevaciones de gemelo',
          targetSets: 4,
          targetRepsMin: 12,
          targetRepsMax: 15),
    ],
  ),
  RoutineTemplate(
    name: 'Upper',
    description: 'Tren superior en un día',
    icon: '⬆️',
    colorIndex: 3,
    exercises: [
      RoutineTemplateExercise(
          exerciseName: 'Press de banca',
          targetSets: 4,
          targetRepsMin: 6,
          targetRepsMax: 8),
      RoutineTemplateExercise(
          exerciseName: 'Remo con barra',
          targetSets: 4,
          targetRepsMin: 8,
          targetRepsMax: 10),
      RoutineTemplateExercise(
          exerciseName: 'Press militar',
          targetSets: 3,
          targetRepsMin: 8,
          targetRepsMax: 10),
      RoutineTemplateExercise(
          exerciseName: 'Curl con barra',
          targetSets: 3,
          targetRepsMin: 10,
          targetRepsMax: 12),
      RoutineTemplateExercise(
          exerciseName: 'Extensión de tríceps en polea',
          targetSets: 3,
          targetRepsMin: 10,
          targetRepsMax: 12),
    ],
  ),
  RoutineTemplate(
    name: 'Lower',
    description: 'Tren inferior en un día',
    icon: '⬇️',
    colorIndex: 4,
    exercises: [
      RoutineTemplateExercise(
          exerciseName: 'Sentadilla',
          targetSets: 4,
          targetRepsMin: 5,
          targetRepsMax: 8),
      RoutineTemplateExercise(
          exerciseName: 'Peso muerto',
          targetSets: 3,
          targetRepsMin: 5,
          targetRepsMax: 6),
      RoutineTemplateExercise(
          exerciseName: 'Hip thrust',
          targetSets: 3,
          targetRepsMin: 8,
          targetRepsMax: 10),
      RoutineTemplateExercise(
          exerciseName: 'Curl de pierna',
          targetSets: 3,
          targetRepsMin: 10,
          targetRepsMax: 12),
    ],
  ),
  RoutineTemplate(
    name: 'Full Body',
    description: 'Cuerpo completo de una sentada',
    icon: '🔥',
    colorIndex: 5,
    exercises: [
      RoutineTemplateExercise(
          exerciseName: 'Sentadilla',
          targetSets: 3,
          targetRepsMin: 6,
          targetRepsMax: 8),
      RoutineTemplateExercise(
          exerciseName: 'Press de banca',
          targetSets: 3,
          targetRepsMin: 6,
          targetRepsMax: 8),
      RoutineTemplateExercise(
          exerciseName: 'Remo con barra',
          targetSets: 3,
          targetRepsMin: 8,
          targetRepsMax: 10),
      RoutineTemplateExercise(
          exerciseName: 'Press militar',
          targetSets: 2,
          targetRepsMin: 8,
          targetRepsMax: 10),
      RoutineTemplateExercise(
          exerciseName: 'Hip thrust',
          targetSets: 2,
          targetRepsMin: 8,
          targetRepsMax: 10),
    ],
  ),
];
