import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/muscle_color.dart';
import '../../../core/domain/muscle_group.dart';
import '../../../core/providers/settings_providers.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/weight_format.dart';
import '../../history/data/history_models.dart';
import '../../history/providers/history_providers.dart';

class NearPRCard extends ConsumerWidget {
  const NearPRCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(nearPRsProvider);
    return asyncList.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final unit = ref.watch(settingsProvider).weightUnit;
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      size: 18, color: scheme.tertiary),
                  const SizedBox(width: 6),
                  Text(
                    'PRs al alcance',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) =>
                      _NearCard(near: list[i], unit: unit),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NearCard extends StatelessWidget {
  const _NearCard({required this.near, required this.unit});

  final NearPR near;
  final WeightUnit unit;

  MuscleGroup get _primary => near.exercise.primaryMuscles.isEmpty
      ? MuscleGroup.chest
      : near.exercise.primaryMuscles.first;

  @override
  Widget build(BuildContext context) {
    final color = _primary.brandColor;
    final gap = unit.fromKg(near.gapKg);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            context.push('/history/exercise/${near.exercise.id}'),
        child: Container(
          width: 200,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
            color: color.withValues(alpha: 0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: color.withValues(alpha: 0.2),
                    ),
                    child: Text(
                      'CERCA',
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.bolt_rounded, size: 16, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                near.exercise.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                'A ${gap.toStringAsFixed(gap < 10 ? 1 : 0)} ${unit.label}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'PR: ${formatWeight(near.bestKg, unit)}  ·  últ ${formatWeight(near.lastKg, unit)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: near.progressRatio,
                  minHeight: 4,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
