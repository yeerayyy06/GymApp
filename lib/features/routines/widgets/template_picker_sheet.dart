import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_gradients.dart';
import '../../workout/providers/workout_providers.dart';
import '../data/routine_models.dart';
import '../data/routine_templates.dart';
import '../providers/routine_providers.dart';

class TemplatePickerSheet extends ConsumerWidget {
  const TemplatePickerSheet({super.key});

  static const _gradients = [
    AppGradients.fire,
    AppGradients.ocean,
    AppGradients.forest,
    AppGradients.violet,
    AppGradients.sunset,
    AppGradients.sky,
  ];

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const TemplatePickerSheet(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plantillas de rutinas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Empieza con una rutina común. Podrás editarla después.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: routineTemplates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final t = routineTemplates[i];
                    return _TemplateCard(
                      template: t,
                      gradient: _gradients[t.colorIndex % _gradients.length],
                      onInstall: () async {
                        final created =
                            await _install(ref, t, context);
                        if (!context.mounted) return;
                        if (created != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Rutina "${t.name}" creada'),
                            ),
                          );
                          Navigator.of(context).pop(true);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _install(
    WidgetRef ref,
    RoutineTemplate t,
    BuildContext context,
  ) async {
    final exercises =
        ref.read(exercisesProvider).valueOrNull ?? const [];
    final byName = <String, String>{
      for (final e in exercises) e.name.toLowerCase(): e.id,
    };
    final drafts = <RoutineExerciseDraft>[];
    for (final templateEx in t.exercises) {
      final id = byName[templateEx.exerciseName.toLowerCase()];
      if (id == null) continue;
      drafts.add(RoutineExerciseDraft(
        exerciseId: id,
        exerciseName: templateEx.exerciseName,
        targetSets: templateEx.targetSets,
        targetRepsMin: templateEx.targetRepsMin,
        targetRepsMax: templateEx.targetRepsMax,
      ));
    }
    if (drafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se han encontrado los ejercicios necesarios',
          ),
        ),
      );
      return null;
    }
    return ref.read(routineRepositoryProvider).createRoutine(
          name: t.name,
          description: t.description,
          exercises: drafts,
        );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.gradient,
    required this.onInstall,
  });

  final RoutineTemplate template;
  final Gradient gradient;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                template.icon,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                    ),
                    Text(
                      template.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: onInstall,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Instalar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final ex in template.exercises)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Text(
                    '${ex.exerciseName} · ${ex.targetSets}×${ex.targetRepsMin}-${ex.targetRepsMax}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
