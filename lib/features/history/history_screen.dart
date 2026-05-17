import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../shared/widgets/skeleton.dart';
import 'providers/history_providers.dart';
import 'widgets/history_calendar.dart';
import 'widgets/recent_prs_card.dart';
import 'widgets/session_card.dart';
import 'widgets/stats_summary_card.dart';
import 'widgets/weekly_volume_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSummariesAsync = ref.watch(sessionSummariesProvider);
    final filteredAsync = ref.watch(filteredSessionSummariesProvider);
    final selectedDay = ref.watch(selectedDayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: allSummariesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.fromLTRB(12, 16, 12, 0),
          child: SkeletonList(itemCount: 5, itemHeight: 130),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $error'),
          ),
        ),
        data: (allSummaries) {
          if (allSummaries.isEmpty) {
            return const _EmptyHistoryView();
          }
          final filtered = filteredAsync.valueOrNull ?? allSummaries;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sessionSummariesProvider);
              ref.invalidate(volumeByMuscleProvider);
              ref.invalidate(recentPRsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              const SliverToBoxAdapter(child: HistoryCalendar()),
              if (selectedDay != null)
                SliverToBoxAdapter(
                  child: _SelectedDayBanner(day: selectedDay),
                ),
              const SliverToBoxAdapter(child: StatsSummaryCard()),
              const SliverToBoxAdapter(child: RecentPRsCard()),
              const SliverToBoxAdapter(child: WeeklyVolumeCard()),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay entrenamientos este día',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Entrenamientos',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => SessionCard(
                    summary: filtered[index],
                  ),
                ),
              ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelectedDayBanner extends ConsumerWidget {
  const _SelectedDayBanner({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt_rounded,
            size: 18,
            color: scheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              formatDate(day),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          SizedBox(
            height: 28,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () =>
                  ref.read(selectedDayProvider.notifier).state = null,
              child: const Text('Quitar filtro'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.15),
                    scheme.tertiary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 48,
                color: scheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin entrenamientos aún',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando termines una sesión aparecerá aquí, con tus PRs, '
              'volumen total y progresión por ejercicio.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
