import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../history/providers/history_providers.dart';

class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(currentStreakProvider);
    final statsAsync = ref.watch(historyStatsProvider);
    final scheme = Theme.of(context).colorScheme;
    final now = ref.watch(clockProvider)();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: _BigTile(
              gradient: const LinearGradient(
                colors: [Color(0xFFFB923C), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.local_fire_department_rounded,
              label: 'Racha',
              value: streakAsync.maybeWhen(
                data: (s) => '$s',
                orElse: () => '…',
              ),
              subtitle: streakAsync.maybeWhen(
                data: (s) =>
                    s == 0 ? 'Vamos a por ello' : (s == 1 ? 'día' : 'días'),
                orElse: () => '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BigTile(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.calendar_today_rounded,
              label: _monthLabel(now),
              value: statsAsync.maybeWhen(
                data: (s) => '${s.sessionsThisMonth}',
                orElse: () => '…',
              ),
              subtitle: statsAsync.maybeWhen(
                data: (s) => s.sessionsThisMonth == 1 ? 'sesión' : 'sesiones',
                orElse: () => '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime now) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return months[now.month - 1];
  }
}

class _BigTile extends StatelessWidget {
  const _BigTile({
    required this.gradient,
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final Gradient gradient;
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: gradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  height: 1,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
          ),
        ],
      ),
    );
  }
}
