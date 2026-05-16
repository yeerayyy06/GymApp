import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import 'providers/history_providers.dart';
import 'widgets/history_calendar.dart';
import 'widgets/session_card.dart';
import 'widgets/stats_summary_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSummariesAsync = ref.watch(sessionSummariesProvider);
    final filteredAsync = ref.watch(filteredSessionSummariesProvider);
    final selectedDay = ref.watch(selectedDayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: allSummariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: HistoryCalendar()),
              if (selectedDay != null)
                SliverToBoxAdapter(
                  child: _SelectedDayBanner(day: selectedDay),
                ),
              const SliverToBoxAdapter(child: StatsSummaryCard()),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No hay entrenamientos este día',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      SessionCard(summary: filtered[index]),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Filtrando por ${formatDate(day)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(selectedDayProvider.notifier).state = null,
            child: const Text('Quitar filtro'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 72),
            const SizedBox(height: 16),
            Text(
              'Sin entrenamientos aún',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando termines una sesión aparecerá aquí, con tus PRs, '
              'volumen total y progresión por ejercicio.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
