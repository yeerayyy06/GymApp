import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/muscle_group.dart';
import '../../../core/utils/formatters.dart';
import '../../history/providers/history_providers.dart';

/// Tarjeta de volumen por grupo muscular con silueta estilizada (vista
/// frontal + dorsal) coloreada por intensidad + barras laterales con el
/// volumen acumulado.
class MuscleVolumeCard extends ConsumerWidget {
  const MuscleVolumeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMap = ref.watch(volumeByMuscleProvider);
    final days = ref.watch(muscleVolumeWindowProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHigh,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessibility_new_rounded,
                    size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Volumen por músculo',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                ),
                const Spacer(),
                _WindowToggle(currentDays: days),
              ],
            ),
            const SizedBox(height: 14),
            asyncMap.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e'),
              data: (volumes) {
                if (volumes.isEmpty) {
                  return _EmptyState(days: days);
                }
                return _Body(volumes: volumes);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowToggle extends ConsumerWidget {
  const _WindowToggle({required this.currentDays});
  final int currentDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('7d')),
        ButtonSegment(value: 30, label: Text('30d')),
        ButtonSegment(value: 90, label: Text('90d')),
      ],
      selected: {currentDays},
      onSelectionChanged: (s) =>
          ref.read(muscleVolumeWindowProvider.notifier).state = s.first,
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'Sin volumen registrado en los últimos $days días',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.volumes});
  final Map<MuscleGroup, double> volumes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxVolume = volumes.values.fold<double>(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _BodyPainter(
                    volumes: volumes,
                    maxVolume: maxVolume,
                    inactiveColor: scheme.surfaceContainerHighest,
                    outlineColor: scheme.outlineVariant,
                    accent: scheme.primary,
                    secondary: scheme.tertiary,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _TopMuscles(volumes: volumes, maxVolume: maxVolume),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _LegendDot(color: scheme.surfaceContainerHighest, label: 'Bajo'),
            _LegendDot(
              color: scheme.primary.withValues(alpha: 0.55),
              label: 'Medio',
            ),
            _LegendDot(color: scheme.primary, label: 'Alto'),
            _LegendDot(color: scheme.tertiary, label: 'Muy alto'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _TopMuscles extends StatelessWidget {
  const _TopMuscles({required this.volumes, required this.maxVolume});
  final Map<MuscleGroup, double> volumes;
  final double maxVolume;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sorted = volumes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in top)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.5),
            child: _MuscleRow(
              muscle: entry.key,
              volume: entry.value,
              ratio: maxVolume == 0 ? 0 : entry.value / maxVolume,
              scheme: scheme,
            ),
          ),
      ],
    );
  }
}

class _MuscleRow extends StatelessWidget {
  const _MuscleRow({
    required this.muscle,
    required this.volume,
    required this.ratio,
    required this.scheme,
  });
  final MuscleGroup muscle;
  final double volume;
  final double ratio;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final color = ratio > 0.85
        ? scheme.tertiary
        : ratio > 0.5
            ? scheme.primary
            : scheme.primary.withValues(alpha: 0.55);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                muscle.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              formatVolume(volume),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

/// Pinta una silueta estilizada (vista frontal + dorsal) con los grupos
/// musculares coloreados según su intensidad.
class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.volumes,
    required this.maxVolume,
    required this.inactiveColor,
    required this.outlineColor,
    required this.accent,
    required this.secondary,
  });

  final Map<MuscleGroup, double> volumes;
  final double maxVolume;
  final Color inactiveColor;
  final Color outlineColor;
  final Color accent;
  final Color secondary;

  Color _colorFor(MuscleGroup m) {
    final v = volumes[m] ?? 0;
    if (v == 0 || maxVolume == 0) return inactiveColor;
    final ratio = v / maxVolume;
    if (ratio > 0.85) return secondary;
    if (ratio > 0.5) return accent;
    return accent.withValues(alpha: 0.55);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Dos siluetas: frontal a la izquierda, dorsal a la derecha
    final halfW = size.width / 2;
    _paintBody(
      canvas,
      Offset(0, 0),
      Size(halfW, size.height),
      front: true,
    );
    _paintBody(
      canvas,
      Offset(halfW, 0),
      Size(halfW, size.height),
      front: false,
    );
  }

  void _paintBody(
    Canvas canvas,
    Offset origin,
    Size size, {
    required bool front,
  }) {
    final cx = origin.dx + size.width / 2;
    final outline = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.fill;

    // Cabeza
    final head = Rect.fromCircle(
      center: Offset(cx, origin.dy + size.height * 0.08),
      radius: size.height * 0.055,
    );
    canvas.drawOval(head, outline);

    // Cuello
    final neck = Rect.fromCenter(
      center: Offset(cx, origin.dy + size.height * 0.13),
      width: size.width * 0.08,
      height: size.height * 0.03,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(neck, const Radius.circular(3)),
      outline,
    );

    // Torso (trapezoide redondeado)
    final torsoTopW = size.width * 0.42;
    final torsoBottomW = size.width * 0.30;
    final torsoTop = origin.dy + size.height * 0.155;
    final torsoBottom = origin.dy + size.height * 0.50;
    final torsoPath = Path()
      ..moveTo(cx - torsoTopW / 2, torsoTop)
      ..lineTo(cx + torsoTopW / 2, torsoTop)
      ..lineTo(cx + torsoBottomW / 2, torsoBottom)
      ..lineTo(cx - torsoBottomW / 2, torsoBottom)
      ..close();
    canvas.drawPath(torsoPath, outline);

    // Brazos
    final armW = size.width * 0.085;
    final armH = size.height * 0.32;
    final armY = origin.dy + size.height * 0.17;
    final armLeftX = cx - size.width * 0.21 - armW / 2;
    final armRightX = cx + size.width * 0.21 - armW / 2;
    final armLeft = RRect.fromRectAndRadius(
      Rect.fromLTWH(armLeftX, armY, armW, armH),
      const Radius.circular(10),
    );
    final armRight = RRect.fromRectAndRadius(
      Rect.fromLTWH(armRightX, armY, armW, armH),
      const Radius.circular(10),
    );
    canvas.drawRRect(armLeft, outline);
    canvas.drawRRect(armRight, outline);

    // Piernas
    final legW = size.width * 0.12;
    final legH = size.height * 0.42;
    final legY = origin.dy + size.height * 0.50;
    final legLeftX = cx - size.width * 0.085 - legW / 2;
    final legRightX = cx + size.width * 0.085 - legW / 2;
    final legLeft = RRect.fromRectAndRadius(
      Rect.fromLTWH(legLeftX, legY, legW, legH),
      const Radius.circular(12),
    );
    final legRight = RRect.fromRectAndRadius(
      Rect.fromLTWH(legRightX, legY, legW, legH),
      const Radius.circular(12),
    );
    canvas.drawRRect(legLeft, outline);
    canvas.drawRRect(legRight, outline);

    // Etiqueta vista
    final viewLabel = TextPainter(
      text: TextSpan(
        text: front ? 'FRENTE' : 'ESPALDA',
        style: TextStyle(
          color: outlineColor,
          fontSize: 9,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    viewLabel.paint(
      canvas,
      Offset(cx - viewLabel.width / 2, origin.dy + size.height * 0.96),
    );

    // Overlay de músculos
    if (front) {
      _paintRegion(canvas,
          rect: Rect.fromCenter(
            center: Offset(cx - size.width * 0.085, torsoTop + size.height * 0.07),
            width: size.width * 0.16,
            height: size.height * 0.10,
          ),
          color: _colorFor(MuscleGroup.chest),
          radius: 8);
      _paintRegion(canvas,
          rect: Rect.fromCenter(
            center: Offset(cx + size.width * 0.085, torsoTop + size.height * 0.07),
            width: size.width * 0.16,
            height: size.height * 0.10,
          ),
          color: _colorFor(MuscleGroup.chest),
          radius: 8);
      // Hombros frontales
      _paintRegion(canvas,
          rect: Rect.fromCircle(
            center: Offset(armLeftX + armW / 2, torsoTop + size.height * 0.018),
            radius: size.width * 0.06,
          ),
          color: _colorFor(MuscleGroup.frontDelts),
          radius: 20);
      _paintRegion(canvas,
          rect: Rect.fromCircle(
            center: Offset(armRightX + armW / 2, torsoTop + size.height * 0.018),
            radius: size.width * 0.06,
          ),
          color: _colorFor(MuscleGroup.frontDelts),
          radius: 20);
      // Abs
      _paintRegion(canvas,
          rect: Rect.fromCenter(
            center: Offset(cx, torsoTop + size.height * 0.24),
            width: size.width * 0.18,
            height: size.height * 0.13,
          ),
          color: _colorFor(MuscleGroup.abs),
          radius: 6);
      // Bíceps
      _paintRegion(canvas,
          rect: Rect.fromLTWH(armLeftX, armY + size.height * 0.04,
              armW, size.height * 0.11),
          color: _colorFor(MuscleGroup.biceps),
          radius: 8);
      _paintRegion(canvas,
          rect: Rect.fromLTWH(armRightX, armY + size.height * 0.04,
              armW, size.height * 0.11),
          color: _colorFor(MuscleGroup.biceps),
          radius: 8);
      // Antebrazos
      _paintRegion(canvas,
          rect: Rect.fromLTWH(armLeftX, armY + size.height * 0.18,
              armW, size.height * 0.10),
          color: _colorFor(MuscleGroup.forearms),
          radius: 8);
      _paintRegion(canvas,
          rect: Rect.fromLTWH(armRightX, armY + size.height * 0.18,
              armW, size.height * 0.10),
          color: _colorFor(MuscleGroup.forearms),
          radius: 8);
      // Cuádriceps
      _paintRegion(canvas,
          rect: Rect.fromLTWH(legLeftX, legY + size.height * 0.04,
              legW, size.height * 0.16),
          color: _colorFor(MuscleGroup.quads),
          radius: 10);
      _paintRegion(canvas,
          rect: Rect.fromLTWH(legRightX, legY + size.height * 0.04,
              legW, size.height * 0.16),
          color: _colorFor(MuscleGroup.quads),
          radius: 10);
    } else {
      // Trapecios (parte alta de la espalda)
      _paintRegion(canvas,
          rect: Rect.fromCenter(
            center: Offset(cx, torsoTop + size.height * 0.04),
            width: size.width * 0.30,
            height: size.height * 0.07,
          ),
          color: _colorFor(MuscleGroup.traps),
          radius: 8);
      // Hombros traseros
      _paintRegion(canvas,
          rect: Rect.fromCircle(
            center: Offset(armLeftX + armW / 2, torsoTop + size.height * 0.018),
            radius: size.width * 0.06,
          ),
          color: _colorFor(MuscleGroup.rearDelts),
          radius: 20);
      _paintRegion(canvas,
          rect: Rect.fromCircle(
            center: Offset(armRightX + armW / 2, torsoTop + size.height * 0.018),
            radius: size.width * 0.06,
          ),
          color: _colorFor(MuscleGroup.rearDelts),
          radius: 20);
      // Espalda alta / dorsales
      _paintRegion(canvas,
          rect: Rect.fromCenter(
            center: Offset(cx, torsoTop + size.height * 0.16),
            width: size.width * 0.32,
            height: size.height * 0.15,
          ),
          color: _colorFor(MuscleGroup.lats),
          radius: 10);
      // Espalda baja
      _paintRegion(canvas,
          rect: Rect.fromCenter(
            center: Offset(cx, torsoTop + size.height * 0.30),
            width: size.width * 0.20,
            height: size.height * 0.06,
          ),
          color: _colorFor(MuscleGroup.lowerBack),
          radius: 6);
      // Tríceps
      _paintRegion(canvas,
          rect: Rect.fromLTWH(armLeftX, armY + size.height * 0.04,
              armW, size.height * 0.11),
          color: _colorFor(MuscleGroup.triceps),
          radius: 8);
      _paintRegion(canvas,
          rect: Rect.fromLTWH(armRightX, armY + size.height * 0.04,
              armW, size.height * 0.11),
          color: _colorFor(MuscleGroup.triceps),
          radius: 8);
      // Glúteos
      _paintRegion(canvas,
          rect: Rect.fromCenter(
            center: Offset(cx, legY + size.height * 0.025),
            width: size.width * 0.28,
            height: size.height * 0.08,
          ),
          color: _colorFor(MuscleGroup.glutes),
          radius: 10);
      // Isquios
      _paintRegion(canvas,
          rect: Rect.fromLTWH(legLeftX, legY + size.height * 0.10,
              legW, size.height * 0.16),
          color: _colorFor(MuscleGroup.hamstrings),
          radius: 10);
      _paintRegion(canvas,
          rect: Rect.fromLTWH(legRightX, legY + size.height * 0.10,
              legW, size.height * 0.16),
          color: _colorFor(MuscleGroup.hamstrings),
          radius: 10);
      // Gemelos
      _paintRegion(canvas,
          rect: Rect.fromLTWH(legLeftX, legY + size.height * 0.28,
              legW, size.height * 0.12),
          color: _colorFor(MuscleGroup.calves),
          radius: 10);
      _paintRegion(canvas,
          rect: Rect.fromLTWH(legRightX, legY + size.height * 0.28,
              legW, size.height * 0.12),
          color: _colorFor(MuscleGroup.calves),
          radius: 10);
    }
  }

  void _paintRegion(
    Canvas canvas, {
    required Rect rect,
    required Color color,
    required double radius,
  }) {
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) {
    return old.volumes != volumes ||
        old.maxVolume != maxVolume ||
        old.accent != accent ||
        old.secondary != secondary;
  }
}
