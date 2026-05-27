import 'dart:math' as math;

import 'package:flutter/material.dart';

class RingData {
  const RingData({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.icon,
  });

  final double progress; // 0..1+ (se capa visualmente a 1)
  final Color color;
  final Color trackColor;
  final IconData icon;
}

/// Anillos concéntricos animados estilo Apple Fitness.
class ActivityRings extends StatelessWidget {
  const ActivityRings({
    super.key,
    required this.rings,
    this.size = 180,
    this.strokeWidth = 16,
    this.gap = 6,
  });

  final List<RingData> rings;
  final double size;
  final double strokeWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingsPainter(
                  rings: rings,
                  strokeWidth: strokeWidth,
                  gap: gap,
                  anim: t,
                ),
              ),
              // Iconos de cada anillo dentro de su track (arriba)
              ...List.generate(rings.length, (i) {
                final r = (size / 2) - strokeWidth / 2 - i * (strokeWidth + gap);
                return Transform.translate(
                  offset: Offset(0, -r),
                  child: Icon(
                    rings[i].icon,
                    size: strokeWidth * 0.62,
                    color: Colors.white,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.rings,
    required this.strokeWidth,
    required this.gap,
    required this.anim,
  });

  final List<RingData> rings;
  final double strokeWidth;
  final double gap;
  final double anim;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < rings.length; i++) {
      final radius = (size.width / 2) -
          strokeWidth / 2 -
          i * (strokeWidth + gap);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final ring = rings[i];

      // Track
      final trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = ring.trackColor;
      canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

      // Progreso
      final p = (ring.progress.clamp(0.0, 1.0)) * anim;
      if (p <= 0) continue;
      final sweep = math.pi * 2 * p;
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          transform: const GradientRotation(-math.pi / 2),
          colors: [
            ring.color.withValues(alpha: 0.6),
            ring.color,
          ],
        ).createShader(rect);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.anim != anim || old.rings != rings;
}
