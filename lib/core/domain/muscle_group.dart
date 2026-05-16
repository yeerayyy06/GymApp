enum MuscleGroup {
  chest,
  upperBack,
  lats,
  traps,
  lowerBack,
  frontDelts,
  sideDelts,
  rearDelts,
  biceps,
  triceps,
  forearms,
  abs,
  obliques,
  glutes,
  quads,
  hamstrings,
  calves,
  adductors,
  abductors,
  neck,
}

extension MuscleGroupX on MuscleGroup {
  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Pecho';
      case MuscleGroup.upperBack:
        return 'Espalda alta';
      case MuscleGroup.lats:
        return 'Dorsales';
      case MuscleGroup.traps:
        return 'Trapecios';
      case MuscleGroup.lowerBack:
        return 'Espalda baja';
      case MuscleGroup.frontDelts:
        return 'Deltoides anterior';
      case MuscleGroup.sideDelts:
        return 'Deltoides lateral';
      case MuscleGroup.rearDelts:
        return 'Deltoides posterior';
      case MuscleGroup.biceps:
        return 'Bíceps';
      case MuscleGroup.triceps:
        return 'Tríceps';
      case MuscleGroup.forearms:
        return 'Antebrazos';
      case MuscleGroup.abs:
        return 'Abdominales';
      case MuscleGroup.obliques:
        return 'Oblicuos';
      case MuscleGroup.glutes:
        return 'Glúteos';
      case MuscleGroup.quads:
        return 'Cuádriceps';
      case MuscleGroup.hamstrings:
        return 'Isquiotibiales';
      case MuscleGroup.calves:
        return 'Gemelos';
      case MuscleGroup.adductors:
        return 'Aductores';
      case MuscleGroup.abductors:
        return 'Abductores';
      case MuscleGroup.neck:
        return 'Cuello';
    }
  }
}
