import 'package:flutter/material.dart';

import 'muscle_group.dart';

/// Paleta de colores por grupo muscular para gráficos y badges.
/// Tonos sacados de Tailwind 500/600 con un ajuste de balance.
extension MuscleColorX on MuscleGroup {
  Color get brandColor {
    switch (this) {
      case MuscleGroup.chest:
        return const Color(0xFFEC4899); // pink
      case MuscleGroup.upperBack:
        return const Color(0xFF3B82F6); // blue
      case MuscleGroup.lats:
        return const Color(0xFF2563EB); // blue-600
      case MuscleGroup.traps:
        return const Color(0xFF1E40AF); // blue-800
      case MuscleGroup.lowerBack:
        return const Color(0xFF6366F1); // indigo
      case MuscleGroup.frontDelts:
        return const Color(0xFF06B6D4); // cyan
      case MuscleGroup.sideDelts:
        return const Color(0xFF0EA5E9); // sky
      case MuscleGroup.rearDelts:
        return const Color(0xFF0891B2); // cyan-600
      case MuscleGroup.biceps:
        return const Color(0xFF8B5CF6); // violet
      case MuscleGroup.triceps:
        return const Color(0xFFA855F7); // purple
      case MuscleGroup.forearms:
        return const Color(0xFFC084FC); // purple-300
      case MuscleGroup.abs:
        return const Color(0xFFF59E0B); // amber
      case MuscleGroup.obliques:
        return const Color(0xFFEAB308); // yellow
      case MuscleGroup.glutes:
        return const Color(0xFFEF4444); // red
      case MuscleGroup.quads:
        return const Color(0xFF10B981); // emerald
      case MuscleGroup.hamstrings:
        return const Color(0xFF14B8A6); // teal
      case MuscleGroup.calves:
        return const Color(0xFF22C55E); // green
      case MuscleGroup.adductors:
        return const Color(0xFF84CC16); // lime
      case MuscleGroup.abductors:
        return const Color(0xFF65A30D); // lime-700
      case MuscleGroup.neck:
        return const Color(0xFF94A3B8); // slate
    }
  }
}
