import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/settings_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/weight_format.dart';
import '../../../shared/widgets/mini_body_map.dart';
import '../data/history_models.dart';
import '../providers/history_providers.dart';

/// SearchDelegate que filtra sesiones del historial por nombre de
/// ejercicio. Resultados muestran tarjeta compacta clickable.
class HistorySearchDelegate extends SearchDelegate<void> {
  HistorySearchDelegate()
      : super(searchFieldLabel: 'Buscar por ejercicio');

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: base.colorScheme.surface,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        filled: false,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final asyncSums = ref.watch(sessionSummariesProvider);
        final scheme = Theme.of(context).colorScheme;
        return asyncSums.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (sums) {
            final q = query.trim().toLowerCase();
            if (q.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 40,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Busca un ejercicio para filtrar sesiones',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            }
            final filtered = sums.where((s) {
              return s.exerciseNames.any(
                (n) => n.toLowerCase().contains(q),
              );
            }).toList();
            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Sin resultados',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                return _ResultRow(
                  summary: filtered[i],
                  query: q,
                  onTap: () {
                    close(context, null);
                    context.push(
                        '/history/session/${filtered[i].session.id}');
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ResultRow extends ConsumerWidget {
  const _ResultRow({
    required this.summary,
    required this.query,
    required this.onTap,
  });

  final SessionSummary summary;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final now = ref.watch(clockProvider)();
    final unit = ref.watch(settingsProvider).weightUnit;
    final hits =
        summary.exerciseNames.where((n) => n.toLowerCase().contains(query));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: scheme.surfaceContainerHigh,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatRelativeDate(summary.session.startedAt, now),
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        formatTime(summary.session.startedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final n in hits.take(3))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color:
                                    scheme.primary.withValues(alpha: 0.16),
                              ),
                              child: Text(
                                n,
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary.totalSets} series · ${formatVolumeInUnit(summary.totalVolumeKg, unit)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                MiniBodyMap(
                  activeMuscles: summary.muscleGroups,
                  size: const Size(34, 80),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
