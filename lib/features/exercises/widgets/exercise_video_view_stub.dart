import 'package:flutter/material.dart';

import '../data/exercise_videos.dart';

/// Fallback para plataformas no-web: muestra un botón que abre
/// YouTube externamente. En web el bundle utilizará la
/// implementación con iframe embebido.
class ExerciseVideoView extends StatelessWidget {
  const ExerciseVideoView({super.key, required this.exerciseName});

  final String exerciseName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_circle_outline_rounded,
              color: Colors.white,
              size: 72,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => openExerciseVideo(exerciseName),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Abrir en YouTube'),
            ),
          ],
        ),
      ),
    );
  }
}
