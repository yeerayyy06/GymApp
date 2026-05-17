import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../shared/widgets/app_gradients.dart';
import '../../../shared/widgets/bento_tile.dart';
import '../../history/providers/history_providers.dart';

class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(currentStreakProvider);
    final statsAsync = ref.watch(historyStatsProvider);
    final now = ref.watch(clockProvider)();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: BentoTile(
              gradient: AppGradients.fire,
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
            child: BentoTile(
              gradient: AppGradients.ocean,
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
