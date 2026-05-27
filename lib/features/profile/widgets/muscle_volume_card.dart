import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/muscle_color.dart';
import '../../../core/domain/muscle_group.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../history/providers/history_providers.dart';

/// Tarjeta de volumen por grupo muscular con silueta anatómica (vista
/// frontal + dorsal) coloreada por intensidad + barras laterales con el
/// volumen acumulado.
class MuscleVolumeCard extends ConsumerWidget {
  const MuscleVolumeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMap = ref.watch(volumeByMuscleProvider);
    final days = ref.watch(muscleVolumeWindowProvider);
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
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
                height: 220,
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
    final maxVolume =
        volumes.values.fold<double>(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) {
                    return CustomPaint(
                      painter: _BodyPainter(
                        volumes: volumes,
                        maxVolume: maxVolume,
                        bodyColor: scheme.surfaceContainerHighest,
                        bodyShadow: scheme.surfaceContainerLow,
                        accent: scheme.primary,
                        secondary: scheme.tertiary,
                        labelColor: scheme.onSurfaceVariant
                            .withValues(alpha: 0.55),
                        progress: progress,
                      ),
                      child: const SizedBox.expand(),
                    );
                  },
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
            _LegendDot(
                color: scheme.surfaceContainerHighest, label: 'Bajo'),
            _LegendDot(
                color: scheme.primary.withValues(alpha: 0.55),
                label: 'Medio'),
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
    final color = muscle.brandColor;
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

/// CustomPainter que dibuja una silueta anatómica con paths Bézier.
/// ViewBox normalizado 100x240 por vista (frente / espalda).
class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.volumes,
    required this.maxVolume,
    required this.bodyColor,
    required this.bodyShadow,
    required this.accent,
    required this.secondary,
    required this.labelColor,
    this.progress = 1.0,
  });

  final Map<MuscleGroup, double> volumes;
  final double maxVolume;
  final Color bodyColor;
  final Color bodyShadow;
  final Color accent;
  final Color secondary;
  final Color labelColor;
  final double progress;

  Color _colorFor(MuscleGroup m) {
    final v = volumes[m] ?? 0;
    if (v == 0 || maxVolume == 0) return bodyShadow;
    final ratio = v / maxVolume;
    final target = ratio > 0.85
        ? secondary
        : ratio > 0.5
            ? accent
            : accent.withValues(alpha: 0.55);
    // Los músculos se "encienden" desde el color base hasta su color
    // objetivo según el progreso de la animación. Los de más volumen
    // arrancan antes (umbral menor) para un efecto escalonado.
    final start = 1.0 - ratio; // más volumen → empieza antes
    final local = ((progress - start) / (1 - start)).clamp(0.0, 1.0);
    return Color.lerp(bodyShadow, target, local) ?? target;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final halfW = size.width / 2;
    _paintBody(canvas,
        bounds: Rect.fromLTWH(0, 0, halfW, size.height), front: true);
    _paintBody(canvas,
        bounds: Rect.fromLTWH(halfW, 0, halfW, size.height), front: false);
  }

  void _paintBody(
    Canvas canvas, {
    required Rect bounds,
    required bool front,
  }) {
    canvas.save();
    const viewW = 100.0;
    const viewH = 260.0;
    final scale = math.min(bounds.width / viewW, bounds.height / viewH);
    canvas.translate(
      bounds.left + (bounds.width - viewW * scale) / 2,
      bounds.top + (bounds.height - viewH * scale) / 2,
    );
    canvas.scale(scale, scale);

    // Silueta base
    final body = _bodyOutline();
    canvas.drawPath(body, Paint()..color = bodyColor);

    // Una línea fina interior para separar mitad izquierda y derecha
    // (sutil acento visual)
    final centerLinePaint = Paint()
      ..color = bodyShadow.withValues(alpha: 0.5)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      const Offset(50, 38),
      const Offset(50, 138),
      centerLinePaint,
    );

    // Overlay muscular
    if (front) {
      _draw(canvas, _pecPath(left: true), MuscleGroup.chest);
      _draw(canvas, _pecPath(left: false), MuscleGroup.chest);
      _draw(canvas, _frontDeltPath(left: true), MuscleGroup.frontDelts);
      _draw(canvas, _frontDeltPath(left: false), MuscleGroup.frontDelts);
      _draw(canvas, _sideDeltPath(left: true), MuscleGroup.sideDelts);
      _draw(canvas, _sideDeltPath(left: false), MuscleGroup.sideDelts);
      _draw(canvas, _bicepPath(left: true), MuscleGroup.biceps);
      _draw(canvas, _bicepPath(left: false), MuscleGroup.biceps);
      _draw(canvas, _forearmFrontPath(left: true), MuscleGroup.forearms);
      _draw(canvas, _forearmFrontPath(left: false), MuscleGroup.forearms);
      _draw(canvas, _absPath(), MuscleGroup.abs);
      _draw(canvas, _obliquePath(left: true), MuscleGroup.obliques);
      _draw(canvas, _obliquePath(left: false), MuscleGroup.obliques);
      _draw(canvas, _quadPath(left: true), MuscleGroup.quads);
      _draw(canvas, _quadPath(left: false), MuscleGroup.quads);
    } else {
      _draw(canvas, _trapPath(), MuscleGroup.traps);
      _draw(canvas, _upperBackPath(left: true), MuscleGroup.upperBack);
      _draw(canvas, _upperBackPath(left: false), MuscleGroup.upperBack);
      _draw(canvas, _rearDeltPath(left: true), MuscleGroup.rearDelts);
      _draw(canvas, _rearDeltPath(left: false), MuscleGroup.rearDelts);
      _draw(canvas, _tricepPath(left: true), MuscleGroup.triceps);
      _draw(canvas, _tricepPath(left: false), MuscleGroup.triceps);
      _draw(canvas, _forearmBackPath(left: true), MuscleGroup.forearms);
      _draw(canvas, _forearmBackPath(left: false), MuscleGroup.forearms);
      _draw(canvas, _latPath(left: true), MuscleGroup.lats);
      _draw(canvas, _latPath(left: false), MuscleGroup.lats);
      _draw(canvas, _lowerBackPath(), MuscleGroup.lowerBack);
      _draw(canvas, _glutePath(left: true), MuscleGroup.glutes);
      _draw(canvas, _glutePath(left: false), MuscleGroup.glutes);
      _draw(canvas, _hamstringPath(left: true), MuscleGroup.hamstrings);
      _draw(canvas, _hamstringPath(left: false), MuscleGroup.hamstrings);
      _draw(canvas, _calfPath(left: true), MuscleGroup.calves);
      _draw(canvas, _calfPath(left: false), MuscleGroup.calves);
    }

    // Etiqueta vista
    final tp = TextPainter(
      text: TextSpan(
        text: front ? 'FRENTE' : 'ESPALDA',
        style: TextStyle(
          color: labelColor,
          fontSize: 9,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((viewW - tp.width) / 2, viewH - 14));

    canvas.restore();
  }

  void _draw(Canvas canvas, Path p, MuscleGroup g) {
    canvas.drawPath(p, Paint()..color = _colorFor(g));
  }

  // ── Silueta base ──────────────────────────────────────────────
  // ViewBox 100×240. Cabeza centrada en (50,17) r=11.
  // Cuerpo simétrico, definido lado izquierdo + espejo.

  Path _bodyOutline() {
    return Path()
      // Cabeza
      ..addOval(Rect.fromCenter(
          center: const Offset(50, 18), width: 22, height: 26))
      // Cuello + cuerpo (closed path)
      ..moveTo(45, 30)
      ..lineTo(43, 39)
      // Trapecio sube hacia hombro izquierdo
      ..cubicTo(40, 39, 30, 41, 25, 47)
      // Deltoide externo izquierdo
      ..cubicTo(22, 50, 19, 55, 18, 62)
      // Borde externo brazo (deltoide → bíceps → codo)
      ..cubicTo(17, 70, 18, 82, 20, 100)
      // Codo izquierdo
      ..cubicTo(20, 110, 20, 120, 22, 140)
      // Antebrazo externo
      ..cubicTo(23, 155, 24, 165, 25, 170)
      // Mano izquierda (puño)
      ..cubicTo(24, 175, 24, 178, 26, 179)
      ..lineTo(31, 179)
      ..cubicTo(33, 178, 33, 175, 32, 170)
      // Antebrazo interno hacia codo
      ..cubicTo(30, 160, 29, 145, 29, 135)
      // Bíceps interno
      ..cubicTo(29, 120, 30, 105, 32, 90)
      // Axila
      ..cubicTo(34, 78, 36, 70, 38, 65)
      // Lateral pecho → cintura
      ..cubicTo(38, 80, 38, 95, 38, 110)
      ..cubicTo(37, 118, 35, 125, 33, 128)
      // Cadera saliente izquierda
      ..cubicTo(32, 130, 31, 134, 31, 140)
      // Muslo externo
      ..cubicTo(31, 155, 32, 175, 34, 190)
      // Rodilla externa
      ..cubicTo(34, 205, 35, 220, 35, 230)
      // Gemelo / tobillo
      ..cubicTo(35, 235, 36, 238, 38, 239)
      ..lineTo(45, 239)
      ..cubicTo(46, 238, 47, 235, 47, 230)
      // Pierna interna sube
      ..cubicTo(47, 220, 47, 200, 47, 180)
      ..cubicTo(47, 165, 47, 150, 48, 140)
      // Entrepierna
      ..lineTo(50, 140)
      // ─── Espejo derecho ───
      ..lineTo(52, 140)
      ..cubicTo(53, 150, 53, 165, 53, 180)
      ..cubicTo(53, 200, 53, 220, 53, 230)
      ..cubicTo(53, 235, 54, 238, 55, 239)
      ..lineTo(62, 239)
      ..cubicTo(64, 238, 65, 235, 65, 230)
      ..cubicTo(65, 220, 66, 205, 66, 190)
      ..cubicTo(68, 175, 69, 155, 69, 140)
      ..cubicTo(69, 134, 68, 130, 67, 128)
      ..cubicTo(65, 125, 63, 118, 62, 110)
      ..cubicTo(62, 95, 62, 80, 62, 65)
      ..cubicTo(64, 70, 66, 78, 68, 90)
      ..cubicTo(70, 105, 71, 120, 71, 135)
      ..cubicTo(71, 145, 70, 160, 68, 170)
      ..cubicTo(67, 175, 67, 178, 69, 179)
      ..lineTo(74, 179)
      ..cubicTo(76, 178, 76, 175, 75, 170)
      ..cubicTo(76, 165, 77, 155, 78, 140)
      ..cubicTo(80, 120, 80, 110, 80, 100)
      ..cubicTo(82, 82, 83, 70, 82, 62)
      ..cubicTo(81, 55, 78, 50, 75, 47)
      ..cubicTo(70, 41, 60, 39, 57, 39)
      ..lineTo(55, 30)
      ..close();
  }

  // ── Pectoral ─────────────────────────────────────────────────
  Path _pecPath({required bool left}) {
    // Pec va desde el centro (esternón) hacia el hombro y abajo a la cintura
    final p = Path();
    if (left) {
      p.moveTo(49, 44);
      p.cubicTo(44, 44, 38, 47, 34, 52);
      p.cubicTo(31, 58, 31, 66, 33, 72);
      p.cubicTo(38, 76, 44, 75, 48, 72);
      p.cubicTo(49, 67, 49, 56, 49, 44);
    } else {
      p.moveTo(51, 44);
      p.cubicTo(56, 44, 62, 47, 66, 52);
      p.cubicTo(69, 58, 69, 66, 67, 72);
      p.cubicTo(62, 76, 56, 75, 52, 72);
      p.cubicTo(51, 67, 51, 56, 51, 44);
    }
    p.close();
    return p;
  }

  // ── Deltoide frontal ─────────────────────────────────────────
  Path _frontDeltPath({required bool left}) {
    final p = Path();
    if (left) {
      p.moveTo(38, 44);
      p.cubicTo(32, 44, 26, 48, 24, 56);
      p.cubicTo(24, 62, 27, 68, 32, 68);
      p.cubicTo(35, 64, 38, 56, 38, 44);
    } else {
      p.moveTo(62, 44);
      p.cubicTo(68, 44, 74, 48, 76, 56);
      p.cubicTo(76, 62, 73, 68, 68, 68);
      p.cubicTo(65, 64, 62, 56, 62, 44);
    }
    p.close();
    return p;
  }

  // ── Deltoide lateral ────────────────────────────────────────
  Path _sideDeltPath({required bool left}) {
    final p = Path();
    if (left) {
      p.moveTo(20, 56);
      p.cubicTo(19, 62, 19, 70, 22, 76);
      p.cubicTo(28, 76, 32, 70, 32, 64);
      p.cubicTo(28, 58, 24, 56, 20, 56);
    } else {
      p.moveTo(80, 56);
      p.cubicTo(81, 62, 81, 70, 78, 76);
      p.cubicTo(72, 76, 68, 70, 68, 64);
      p.cubicTo(72, 58, 76, 56, 80, 56);
    }
    p.close();
    return p;
  }

  // ── Bíceps ──────────────────────────────────────────────────
  Path _bicepPath({required bool left}) {
    final p = Path();
    if (left) {
      p.moveTo(22, 75);
      p.cubicTo(19, 85, 19, 95, 22, 102);
      p.cubicTo(28, 104, 32, 96, 32, 88);
      p.cubicTo(31, 80, 27, 76, 22, 75);
    } else {
      p.moveTo(78, 75);
      p.cubicTo(81, 85, 81, 95, 78, 102);
      p.cubicTo(72, 104, 68, 96, 68, 88);
      p.cubicTo(69, 80, 73, 76, 78, 75);
    }
    p.close();
    return p;
  }

  // ── Antebrazo (frontal) ─────────────────────────────────────
  Path _forearmFrontPath({required bool left}) {
    final p = Path();
    if (left) {
      p.moveTo(22, 118);
      p.cubicTo(20, 130, 21, 145, 23, 158);
      p.cubicTo(28, 158, 30, 145, 30, 130);
      p.cubicTo(28, 122, 24, 118, 22, 118);
    } else {
      p.moveTo(78, 118);
      p.cubicTo(80, 130, 79, 145, 77, 158);
      p.cubicTo(72, 158, 70, 145, 70, 130);
      p.cubicTo(72, 122, 76, 118, 78, 118);
    }
    p.close();
    return p;
  }

  // ── Antebrazo (dorsal) ──────────────────────────────────────
  Path _forearmBackPath({required bool left}) {
    return _forearmFrontPath(left: left);
  }

  // ── Abdominales: 6-pack + V de oblicuo bajo ────────────────
  Path _absPath() {
    final p = Path();
    // 3 filas de 2 ovales
    for (var row = 0; row < 3; row++) {
      final cy = 82.0 + row * 9.5;
      final h = row == 2 ? 8.5 : 8.0; // fila baja un poco más alta
      // izquierdo
      p.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(46.5, cy), width: 7, height: h),
        const Radius.circular(2),
      ));
      // derecho
      p.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(53.5, cy), width: 7, height: h),
        const Radius.circular(2),
      ));
    }
    // V-cut bajo el ombligo
    final v = Path()
      ..moveTo(43, 112)
      ..lineTo(50, 124)
      ..lineTo(57, 112)
      ..lineTo(55, 112)
      ..lineTo(50, 120)
      ..lineTo(45, 112)
      ..close();
    p.addPath(v, Offset.zero);
    return p;
  }

  // ── Oblicuos ───────────────────────────────────────────────
  Path _obliquePath({required bool left}) {
    final p = Path();
    if (left) {
      p.moveTo(38, 90);
      p.cubicTo(36, 100, 36, 112, 40, 120);
      p.lineTo(43, 115);
      p.cubicTo(42, 105, 42, 95, 40, 88);
    } else {
      p.moveTo(62, 90);
      p.cubicTo(64, 100, 64, 112, 60, 120);
      p.lineTo(57, 115);
      p.cubicTo(58, 105, 58, 95, 60, 88);
    }
    p.close();
    return p;
  }

  // ── Cuádriceps (con 3 cabezas) ─────────────────────────────
  Path _quadPath({required bool left}) {
    final p = Path();
    // Forma exterior (perfil de muslo)
    if (left) {
      p.moveTo(34, 146);
      p.cubicTo(31, 165, 32, 185, 36, 200);
      p.cubicTo(40, 202, 44, 200, 46, 195);
      p.cubicTo(47, 175, 47, 155, 46, 146);
      p.close();
    } else {
      p.moveTo(66, 146);
      p.cubicTo(69, 165, 68, 185, 64, 200);
      p.cubicTo(60, 202, 56, 200, 54, 195);
      p.cubicTo(53, 175, 53, 155, 54, 146);
      p.close();
    }
    return p;
  }

  // ── Trapecios ──────────────────────────────────────────────
  Path _trapPath() {
    return Path()
      ..moveTo(44, 33)
      ..cubicTo(36, 38, 28, 44, 24, 50)
      ..cubicTo(30, 56, 38, 62, 46, 64)
      ..lineTo(54, 64)
      ..cubicTo(62, 62, 70, 56, 76, 50)
      ..cubicTo(72, 44, 64, 38, 56, 33)
      ..close();
  }

  // ── Espalda alta (rhomboids) ───────────────────────────────
  Path _upperBackPath({required bool left}) {
    final p = Path();
    if (left) {
      p.moveTo(40, 66);
      p.cubicTo(36, 70, 35, 80, 38, 88);
      p.lineTo(48, 88);
      p.lineTo(48, 66);
      p.close();
    } else {
      p.moveTo(60, 66);
      p.cubicTo(64, 70, 65, 80, 62, 88);
      p.lineTo(52, 88);
      p.lineTo(52, 66);
      p.close();
    }
    return p;
  }

  // ── Dorsales (lats) ────────────────────────────────────────
  Path _latPath({required bool left}) {
    final p = Path();
    if (left) {
      p.moveTo(36, 72);
      p.cubicTo(30, 80, 30, 95, 32, 110);
      p.cubicTo(36, 118, 42, 120, 48, 118);
      p.lineTo(48, 90);
      p.cubicTo(46, 80, 42, 74, 36, 72);
    } else {
      p.moveTo(64, 72);
      p.cubicTo(70, 80, 70, 95, 68, 110);
      p.cubicTo(64, 118, 58, 120, 52, 118);
      p.lineTo(52, 90);
      p.cubicTo(54, 80, 58, 74, 64, 72);
    }
    p.close();
    return p;
  }

  // ── Lumbar (erectores) ─────────────────────────────────────
  Path _lowerBackPath() {
    final p = Path();
    // Dos columnas erectoras
    for (var side in [-1, 1]) {
      final cx = 50 + side * 3.5;
      p.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 122), width: 5, height: 14),
        const Radius.circular(2),
      ));
    }
    return p;
  }

  // ── Deltoide trasero ───────────────────────────────────────
  Path _rearDeltPath({required bool left}) {
    final p = Path();
    if (left) {
      p.moveTo(22, 56);
      p.cubicTo(20, 62, 20, 70, 24, 76);
      p.cubicTo(30, 76, 36, 70, 36, 62);
      p.cubicTo(32, 56, 26, 54, 22, 56);
    } else {
      p.moveTo(78, 56);
      p.cubicTo(80, 62, 80, 70, 76, 76);
      p.cubicTo(70, 76, 64, 70, 64, 62);
      p.cubicTo(68, 56, 74, 54, 78, 56);
    }
    p.close();
    return p;
  }

  // ── Tríceps ────────────────────────────────────────────────
  Path _tricepPath({required bool left}) {
    final p = Path();
    if (left) {
      p.moveTo(20, 76);
      p.cubicTo(18, 90, 19, 105, 22, 115);
      p.cubicTo(26, 115, 30, 100, 30, 88);
      p.cubicTo(28, 78, 24, 75, 20, 76);
    } else {
      p.moveTo(80, 76);
      p.cubicTo(82, 90, 81, 105, 78, 115);
      p.cubicTo(74, 115, 70, 100, 70, 88);
      p.cubicTo(72, 78, 76, 75, 80, 76);
    }
    p.close();
    return p;
  }

  // ── Glúteo ────────────────────────────────────────────────
  Path _glutePath({required bool left}) {
    final p = Path();
    if (left) {
      p.moveTo(34, 132);
      p.cubicTo(30, 138, 30, 148, 34, 154);
      p.cubicTo(40, 156, 47, 154, 49, 148);
      p.lineTo(49, 134);
      p.cubicTo(44, 130, 38, 130, 34, 132);
    } else {
      p.moveTo(66, 132);
      p.cubicTo(70, 138, 70, 148, 66, 154);
      p.cubicTo(60, 156, 53, 154, 51, 148);
      p.lineTo(51, 134);
      p.cubicTo(56, 130, 62, 130, 66, 132);
    }
    p.close();
    return p;
  }

  // ── Isquiotibiales ────────────────────────────────────────
  Path _hamstringPath({required bool left}) {
    final p = Path();
    if (left) {
      p.moveTo(34, 160);
      p.cubicTo(31, 175, 32, 190, 36, 200);
      p.cubicTo(40, 202, 44, 200, 46, 195);
      p.cubicTo(47, 180, 47, 165, 46, 160);
      p.close();
    } else {
      p.moveTo(66, 160);
      p.cubicTo(69, 175, 68, 190, 64, 200);
      p.cubicTo(60, 202, 56, 200, 54, 195);
      p.cubicTo(53, 180, 53, 165, 54, 160);
      p.close();
    }
    return p;
  }

  // ── Gemelos (gastrocnemios) ──────────────────────────────
  Path _calfPath({required bool left}) {
    final p = Path();
    if (left) {
      p.moveTo(36, 205);
      p.cubicTo(33, 215, 34, 225, 38, 230);
      p.cubicTo(44, 230, 46, 220, 46, 212);
      p.cubicTo(44, 206, 40, 204, 36, 205);
    } else {
      p.moveTo(64, 205);
      p.cubicTo(67, 215, 66, 225, 62, 230);
      p.cubicTo(56, 230, 54, 220, 54, 212);
      p.cubicTo(56, 206, 60, 204, 64, 205);
    }
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) {
    return old.volumes != volumes ||
        old.maxVolume != maxVolume ||
        old.accent != accent ||
        old.secondary != secondary ||
        old.bodyColor != bodyColor ||
        old.progress != progress;
  }
}
