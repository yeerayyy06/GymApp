import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/clock_provider.dart';
import '../../core/services/health_service.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/line_chart_card.dart';
import 'providers/health_providers.dart';
import 'widgets/activity_rings.dart';
import 'widgets/sleep_sheet.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthProvider);
    final now = ref.watch(clockProvider)();
    final scheme = Theme.of(context).colorScheme;
    final today = now;

    final sleep = health.sleepFor(today);
    final water = health.waterFor(today);
    final sets = ref.watch(todaySetsProvider);

    final sleepProgress = sleep == null
        ? 0.0
        : sleep.minutes / health.sleepGoalMinutes;
    final waterProgress = health.waterGoalGlasses == 0
        ? 0.0
        : water / health.waterGoalGlasses;
    final trainProgress = sets / dailySetsGoal;

    return Scaffold(
      appBar: AppBar(title: const AppBarTitle(label: 'Salud')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          // ── Anillos ──
          Container(
            margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.12),
                  scheme.tertiary.withValues(alpha: 0.06),
                ],
              ),
            ),
            child: Column(
              children: [
                ActivityRings(
                  size: 190,
                  rings: [
                    RingData(
                      progress: sleepProgress,
                      color: const Color(0xFF60A5FA),
                      trackColor:
                          const Color(0xFF60A5FA).withValues(alpha: 0.18),
                      icon: Icons.bedtime_rounded,
                    ),
                    RingData(
                      progress: trainProgress,
                      color: const Color(0xFF34D399),
                      trackColor:
                          const Color(0xFF34D399).withValues(alpha: 0.18),
                      icon: Icons.fitness_center_rounded,
                    ),
                    RingData(
                      progress: waterProgress,
                      color: const Color(0xFF22D3EE),
                      trackColor:
                          const Color(0xFF22D3EE).withValues(alpha: 0.18),
                      icon: Icons.water_drop_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RingLegend(
                      color: const Color(0xFF60A5FA),
                      label: 'Sueño',
                      value: sleep == null
                          ? '—'
                          : '${sleep.hours.toStringAsFixed(1)}h',
                    ),
                    _RingLegend(
                      color: const Color(0xFF34D399),
                      label: 'Entreno',
                      value: '$sets ser',
                    ),
                    _RingLegend(
                      color: const Color(0xFF22D3EE),
                      label: 'Agua',
                      value: '$water vasos',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // ── Sueño ──
          _SleepCard(health: health, now: now),
          // ── Agua ──
          _WaterCard(health: health, now: now),
          // ── Tendencia de sueño ──
          LineChartCard(
            title: 'Sueño (últimos 30 días)',
            icon: Icons.bedtime_rounded,
            points: _sleepPoints(health, now),
            unit: ' h',
            daysWindow: 30,
            emptyMessage: 'Registra al menos 2 noches para ver la tendencia',
          ),
        ],
      ),
    );
  }

  List<ChartPoint> _sleepPoints(HealthData health, DateTime now) {
    final points = <ChartPoint>[];
    health.sleepByDate.forEach((key, entry) {
      final parts = key.split('-');
      if (parts.length == 3) {
        final d = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        points.add(ChartPoint(time: d, value: entry.hours));
      }
    });
    return points;
  }
}

class _RingLegend extends StatelessWidget {
  const _RingLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _SleepCard extends ConsumerWidget {
  const _SleepCard({required this.health, required this.now});

  final HealthData health;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final entry = health.sleepFor(now);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHigh,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF60A5FA).withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.bedtime_rounded,
                color: Color(0xFF60A5FA), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sueño de hoy',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  entry == null
                      ? 'Sin registrar'
                      : '${entry.hours.toStringAsFixed(1)} h · calidad ${entry.quality}/5',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => SleepSheet.show(context, ref, now),
            child: Text(entry == null ? 'Registrar' : 'Editar'),
          ),
        ],
      ),
    );
  }
}

class _WaterCard extends ConsumerWidget {
  const _WaterCard({required this.health, required this.now});

  final HealthData health;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final glasses = health.waterFor(now);
    final goal = health.waterGoalGlasses;
    const cyan = Color(0xFF22D3EE);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: cyan.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.water_drop_rounded,
                    color: cyan, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hidratación',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$glasses de $goal vasos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: cyan,
                onPressed: glasses > 0
                    ? () => ref
                        .read(healthProvider.notifier)
                        .setWater(now, glasses - 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_rounded),
                color: cyan,
                onPressed: () => ref
                    .read(healthProvider.notifier)
                    .setWater(now, glasses + 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < goal; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: i < glasses
                            ? cyan
                            : scheme.surfaceContainerHighest,
                      ),
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
