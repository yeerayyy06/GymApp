import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/clock_provider.dart';
import '../../core/utils/formatters.dart';
import '../history/providers/history_providers.dart';
import 'providers/profile_providers.dart';
import 'widgets/bodyweight_form_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _addEntry(BuildContext context, WidgetRef ref) async {
    final result = await BodyweightFormDialog.show(context);
    if (result == null) return;
    await ref.read(profileRepositoryProvider).addEntry(
          weightKg: result.weightKg,
          measuredAt: result.measuredAt,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(bodyweightEntriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEntry(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar peso'),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (entries) => _ProfileBody(entries: entries),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.entries});

  final List<BodyweightEntryRow> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final latest = entries.isEmpty ? null : entries.first;
    final previous = entries.length >= 2 ? entries[1] : null;
    final delta =
        latest != null && previous != null ? latest.weightKg - previous.weightKg : null;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _BodyweightHeader(latest: latest, delta: delta, now: now),
        const _TrainingSummaryCard(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Historial de peso',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Aún no hay registros de peso')),
          )
        else
          ...entries.map(
            (entry) => _BodyweightTile(entry: entry, now: now),
          ),
      ],
    );
  }
}

class _BodyweightHeader extends StatelessWidget {
  const _BodyweightHeader({
    required this.latest,
    required this.delta,
    required this.now,
  });

  final BodyweightEntryRow? latest;
  final double? delta;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Peso corporal',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            if (latest == null)
              Text(
                'Sin registros',
                style: Theme.of(context).textTheme.headlineSmall,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatWeightKg(latest!.weightKg),
                    style:
                        Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                  const SizedBox(width: 12),
                  if (delta != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _DeltaChip(delta: delta!),
                    ),
                ],
              ),
            const SizedBox(height: 4),
            if (latest != null)
              Text(
                formatRelativeDate(latest!.measuredAt, now),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPositive = delta > 0;
    final isZero = delta.abs() < 0.05;
    final color = isZero
        ? scheme.onSurfaceVariant
        : (isPositive ? scheme.tertiary : scheme.primary);
    final icon = isZero
        ? Icons.remove
        : (isPositive ? Icons.arrow_upward : Icons.arrow_downward);
    final text = isZero
        ? '0 kg'
        : '${isPositive ? '+' : '−'}${delta.abs().toStringAsFixed(1)} kg';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingSummaryCard extends ConsumerWidget {
  const _TrainingSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(historyStatsProvider);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: statsAsync.when(
          loading: () => const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Error: $error'),
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrenamientos',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _SummaryBlock(
                    value: '${stats.totalSessions}',
                    label: 'Sesiones',
                  ),
                  _SummaryBlock(
                    value: '${stats.totalSets}',
                    label: 'Series',
                  ),
                  _SummaryBlock(
                    value: formatVolume(stats.totalVolumeKg),
                    label: 'Volumen',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _BodyweightTile extends ConsumerWidget {
  const _BodyweightTile({required this.entry, required this.now});

  final BodyweightEntryRow entry;
  final DateTime now;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await BodyweightFormDialog.show(
      context,
      initialWeightKg: entry.weightKg,
      initialMeasuredAt: entry.measuredAt,
      isEditing: true,
    );
    if (result == null) return;
    await ref.read(profileRepositoryProvider).updateEntry(
          id: entry.id,
          weightKg: result.weightKg,
          measuredAt: result.measuredAt,
        );
  }

  Future<void> _delete(WidgetRef ref) async {
    await ref.read(profileRepositoryProvider).deleteEntry(entry.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => _delete(ref),
      child: ListTile(
        onTap: () => _edit(context, ref),
        title: Text(formatWeightKg(entry.weightKg)),
        subtitle: Text(formatRelativeDate(entry.measuredAt, now)),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    );
  }
}
