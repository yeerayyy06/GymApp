import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/history_providers.dart';
import 'widgets/session_card.dart';
import 'widgets/stats_summary_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(sessionSummariesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: summariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $error'),
          ),
        ),
        data: (summaries) {
          if (summaries.isEmpty) {
            return const _EmptyHistoryView();
          }
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: StatsSummaryCard()),
              SliverList.builder(
                itemCount: summaries.length,
                itemBuilder: (context, index) =>
                    SessionCard(summary: summaries[index]),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            ],
          );
        },
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
