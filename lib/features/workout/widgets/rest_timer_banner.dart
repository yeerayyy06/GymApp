import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_providers.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/notification_service.dart';
import '../providers/rest_timer_provider.dart';

class RestTimerBanner extends ConsumerStatefulWidget {
  const RestTimerBanner({super.key});

  @override
  ConsumerState<RestTimerBanner> createState() => _RestTimerBannerState();
}

class _RestTimerBannerState extends ConsumerState<RestTimerBanner> {
  Timer? _ticker;
  bool _alerted = false;
  RestTimerConfig? _lastConfig;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    final total = d.inSeconds;
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(restTimerProvider);

    if (config != _lastConfig) {
      _lastConfig = config;
      _alerted = false;
    }

    if (config == null) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final remaining = config.endsAt.difference(now);
    final isFinished = remaining.inMilliseconds <= 0;
    final shownRemaining =
        isFinished ? Duration.zero : remaining;

    if (isFinished && !_alerted) {
      _alerted = true;
      HapticFeedback.mediumImpact();
      AudioService.timerEnd();
      final notify = ref.read(settingsProvider).restNotificationsEnabled;
      if (notify) {
        WebNotificationService.show(
          '¡Descanso terminado!',
          body: config.exerciseName == null
              ? 'Toca para volver a la app'
              : 'Toca para volver: ${config.exerciseName}',
        );
      }
    }

    final progress = config.totalSeconds <= 0
        ? 1.0
        : 1.0 -
            (shownRemaining.inMilliseconds /
                    (config.totalSeconds * 1000))
                .clamp(0.0, 1.0);

    final color = isFinished ? scheme.tertiary : scheme.primary;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: const ValueKey('rest-timer-active'),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isFinished
                      ? Icons.check_circle_rounded
                      : Icons.timer_rounded,
                  color: color,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              config.exerciseName == null
                                  ? (isFinished ? '¡Listo!' : 'Descanso')
                                  : '${isFinished ? "Listo · " : "Descanso · "}${config.exerciseName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatRemaining(shownRemaining),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
                _CircleButton(
                  label: '−15',
                  onTap: () => ref
                      .read(restTimerProvider.notifier)
                      .addSeconds(-15),
                  color: color,
                ),
                const SizedBox(width: 6),
                _CircleButton(
                  label: '+15',
                  onTap: () => ref
                      .read(restTimerProvider.notifier)
                      .addSeconds(15),
                  color: color,
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  tooltip: 'Más',
                  icon: Icon(Icons.more_vert_rounded, color: color),
                  onSelected: (value) async {
                    switch (value) {
                      case 'save_default':
                        if (config.exerciseId == null) return;
                        await ref
                            .read(settingsProvider.notifier)
                            .setExerciseRestSeconds(
                              config.exerciseId!,
                              config.totalSeconds,
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Descanso de ${config.totalSeconds}s guardado para ${config.exerciseName}',
                            ),
                          ),
                        );
                      case 'skip':
                        ref.read(restTimerProvider.notifier).skip();
                    }
                  },
                  itemBuilder: (_) => [
                    if (config.exerciseId != null)
                      PopupMenuItem(
                        value: 'save_default',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.bookmark_add_outlined),
                          title: Text(
                            'Guardar ${config.totalSeconds}s como default',
                          ),
                          subtitle: config.exerciseName == null
                              ? null
                              : Text('Para ${config.exerciseName}'),
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'skip',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.skip_next_rounded),
                        title: Text('Saltar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: math.min(1.0, math.max(0.0, progress)),
                minHeight: 4,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
