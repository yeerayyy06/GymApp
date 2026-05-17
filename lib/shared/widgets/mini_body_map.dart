import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/domain/muscle_color.dart';
import '../../core/domain/muscle_group.dart';

/// Mini silueta humana (frontal) que colorea los grupos musculares
/// activos. Pensado para usarse dentro de cards (40-60 px de ancho).
class MiniBodyMap extends StatelessWidget {
  const MiniBodyMap({
    super.key,
    required this.activeMuscles,
    this.size = const Size(46, 96),
  });

  final Set<MuscleGroup> activeMuscles;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.fromSize(
      size: size,
      child: CustomPaint(
        painter: _MiniBodyPainter(
          activeMuscles: activeMuscles,
          baseColor: scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _MiniBodyPainter extends CustomPainter {
  _MiniBodyPainter({
    required this.activeMuscles,
    required this.baseColor,
  });

  final Set<MuscleGroup> activeMuscles;
  final Color baseColor;

  bool _hit(MuscleGroup m) => activeMuscles.contains(m);

  Color _colorOr(MuscleGroup m, Color fallback) =>
      _hit(m) ? m.brandColor : fallback;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // ViewBox 100×210 → escalado al tamaño dado
    const viewW = 100.0;
    const viewH = 210.0;
    final scale = math.min(size.width / viewW, size.height / viewH);
    canvas.translate(
      (size.width - viewW * scale) / 2,
      (size.height - viewH * scale) / 2,
    );
    canvas.scale(scale, scale);

    final bodyPaint = Paint()..color = baseColor;

    // Silueta base
    final body = _buildSilhouette();
    canvas.drawPath(body, bodyPaint);

    // Overlays
    final overlays = <MuscleGroup, Path>{
      MuscleGroup.frontDelts: _frontDelts(),
      MuscleGroup.sideDelts: _sideDelts(),
      MuscleGroup.chest: _chest(),
      MuscleGroup.abs: _abs(),
      MuscleGroup.obliques: _obliques(),
      MuscleGroup.biceps: _biceps(),
      MuscleGroup.forearms: _forearms(),
      MuscleGroup.quads: _quads(),
      MuscleGroup.calves: _calves(),
    };

    for (final entry in overlays.entries) {
      if (!_hit(entry.key)) continue;
      canvas.drawPath(entry.value, Paint()..color = _colorOr(entry.key, baseColor));
    }

    canvas.restore();
  }

  Path _buildSilhouette() {
    return Path()
      ..addOval(Rect.fromCenter(
          center: const Offset(50, 14), width: 20, height: 22))
      ..moveTo(46, 25)
      ..lineTo(44, 33)
      ..cubicTo(38, 33, 30, 36, 26, 42)
      ..cubicTo(23, 46, 21, 52, 21, 60)
      ..lineTo(22, 100)
      ..cubicTo(22, 110, 23, 120, 25, 132)
      ..lineTo(27, 138)
      ..lineTo(33, 138)
      ..lineTo(32, 132)
      ..cubicTo(31, 120, 30, 110, 30, 100)
      ..lineTo(32, 72)
      ..cubicTo(33, 62, 35, 56, 38, 54)
      // costado
      ..cubicTo(38, 70, 38, 88, 38, 102)
      ..cubicTo(37, 108, 35, 113, 33, 116)
      ..cubicTo(31, 120, 31, 124, 32, 130)
      ..lineTo(34, 162)
      ..lineTo(35, 195)
      ..lineTo(45, 195)
      ..lineTo(47, 162)
      ..lineTo(48, 130)
      ..lineTo(50, 130)
      // espejo derecho
      ..lineTo(52, 130)
      ..lineTo(53, 162)
      ..lineTo(55, 195)
      ..lineTo(65, 195)
      ..lineTo(66, 162)
      ..lineTo(68, 130)
      ..cubicTo(69, 124, 69, 120, 67, 116)
      ..cubicTo(65, 113, 63, 108, 62, 102)
      ..cubicTo(62, 88, 62, 70, 62, 54)
      ..cubicTo(65, 56, 67, 62, 68, 72)
      ..lineTo(70, 100)
      ..cubicTo(70, 110, 69, 120, 68, 132)
      ..lineTo(67, 138)
      ..lineTo(73, 138)
      ..lineTo(75, 132)
      ..cubicTo(77, 120, 78, 110, 78, 100)
      ..lineTo(79, 60)
      ..cubicTo(79, 52, 77, 46, 74, 42)
      ..cubicTo(70, 36, 62, 33, 56, 33)
      ..lineTo(54, 25)
      ..close();
  }

  Path _frontDelts() {
    final p = Path();
    p.addOval(Rect.fromCircle(center: const Offset(28, 46), radius: 6));
    p.addOval(Rect.fromCircle(center: const Offset(72, 46), radius: 6));
    return p;
  }

  Path _sideDelts() {
    final p = Path();
    p.addOval(Rect.fromCircle(center: const Offset(22, 56), radius: 5));
    p.addOval(Rect.fromCircle(center: const Offset(78, 56), radius: 5));
    return p;
  }

  Path _chest() {
    final p = Path();
    p.moveTo(50, 40);
    p.cubicTo(43, 41, 36, 44, 35, 52);
    p.cubicTo(35, 58, 41, 64, 49, 63);
    p.cubicTo(50, 56, 50, 48, 50, 40);
    p.close();
    p.moveTo(50, 40);
    p.cubicTo(57, 41, 64, 44, 65, 52);
    p.cubicTo(65, 58, 59, 64, 51, 63);
    p.cubicTo(50, 56, 50, 48, 50, 40);
    p.close();
    return p;
  }

  Path _abs() {
    final p = Path();
    for (var row = 0; row < 3; row++) {
      final cy = 72.0 + row * 7.0;
      p.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(47, cy), width: 5.5, height: 6),
        const Radius.circular(1.5),
      ));
      p.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(53, cy), width: 5.5, height: 6),
        const Radius.circular(1.5),
      ));
    }
    return p;
  }

  Path _obliques() {
    final p = Path();
    p.moveTo(38, 75);
    p.lineTo(36, 95);
    p.lineTo(41, 95);
    p.lineTo(42, 78);
    p.close();
    p.moveTo(62, 75);
    p.lineTo(64, 95);
    p.lineTo(59, 95);
    p.lineTo(58, 78);
    p.close();
    return p;
  }

  Path _biceps() {
    final p = Path();
    p.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(22, 60, 8, 22),
      const Radius.circular(4),
    ));
    p.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(70, 60, 8, 22),
      const Radius.circular(4),
    ));
    return p;
  }

  Path _forearms() {
    final p = Path();
    p.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(24, 96, 7, 28),
      const Radius.circular(4),
    ));
    p.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(69, 96, 7, 28),
      const Radius.circular(4),
    ));
    return p;
  }

  Path _quads() {
    final p = Path();
    p.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(34, 133, 12, 32),
      const Radius.circular(5),
    ));
    p.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(54, 133, 12, 32),
      const Radius.circular(5),
    ));
    return p;
  }

  Path _calves() {
    final p = Path();
    p.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(36, 170, 9, 22),
      const Radius.circular(4),
    ));
    p.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(55, 170, 9, 22),
      const Radius.circular(4),
    ));
    return p;
  }

  @override
  bool shouldRepaint(covariant _MiniBodyPainter old) {
    return old.activeMuscles != activeMuscles || old.baseColor != baseColor;
  }
}
