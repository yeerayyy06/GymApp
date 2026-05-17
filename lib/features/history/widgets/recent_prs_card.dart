import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/muscle_color.dart';
import '../../../core/domain/muscle_group.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/settings_providers.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/weight_format.dart';
import '../data/history_models.dart';
import '../providers/history_providers.dart';

class RecentPRsCard extends ConsumerWidget {
  const RecentPRsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvents = ref.watch(recentPRsProvider);
    final scheme = Theme.of(context).colorScheme;

    return asyncEvents.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        final now = ref.watch(clockProvider)();
        final unit = ref.watch(settingsProvider).weightUnit;
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 18,
                      color: scheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PRs recientes',
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                    ),
                    const Spacer(),
                    Text(
                      '${events.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 138,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => _PrCard(
                    event: events[i],
                    now: now,
                    unit: unit,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrCard extends StatelessWidget {
  const _PrCard({
    required this.event,
    required this.now,
    required this.unit,
  });

  final PrEvent event;
  final DateTime now;
  final WeightUnit unit;

  MuscleGroup get _primaryMuscle =>
      event.exercise.primaryMuscles.isEmpty
          ? MuscleGroup.chest
          : event.exercise.primaryMuscles.first;

  String _ago() {
    final days = now.difference(event.when).inDays;
    if (days == 0) return 'hoy';
    if (days == 1) return 'ayer';
    if (days < 7) return 'hace ${days}d';
    if (days < 30) return 'hace ${(days / 7).round()}sem';
    return 'hace ${(days / 30).round()}m';
  }

  String _kindLabel() {
    if (event.isWeightPR && event.is1RMPR) return 'PESO + 1RM';
    if (event.isWeightPR) return 'PESO MÁX';
    return '1RM EST.';
  }

  @override
  Widget build(BuildContext context) {
    final color = _primaryMuscle.brandColor;
    return Container(
      width: 200,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.35) ?? color,
          ],
        ),
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
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                child: Text(
                  _kindLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
          const Spacer(),
          Text(
            event.exercise.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatWeight(event.weightKg, unit)} × ${event.reps}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _ago(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
