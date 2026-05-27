import 'package:flutter/material.dart';

/// Icono de mancuerna dibujado con CustomPaint, más característico
/// que el genérico Icons.fitness_center. Escala con [size] y toma
/// el [color] dado.
class DumbbellIcon extends StatelessWidget {
  const DumbbellIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DumbbellPainter(color: color),
      ),
    );
  }
}

class _DumbbellPainter extends CustomPainter {
  _DumbbellPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;

    // Trabajamos en una diagonal ligera para dar dinamismo.
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-0.5);
    canvas.translate(-w / 2, -h / 2);

    final cy = h / 2;
    final barH = h * 0.14;
    // Barra central
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(w / 2, cy), width: w * 0.42, height: barH),
        Radius.circular(barH / 2),
      ),
      paint,
    );

    // Discos: dos a cada lado (grande exterior + pequeño interior)
    void plate(double cx, double width, double height) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: width, height: height),
          Radius.circular(width * 0.4),
        ),
        paint,
      );
    }

    // Izquierda
    plate(w * 0.16, w * 0.12, h * 0.62);
    plate(w * 0.30, w * 0.10, h * 0.44);
    // Derecha
    plate(w * 0.84, w * 0.12, h * 0.62);
    plate(w * 0.70, w * 0.10, h * 0.44);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DumbbellPainter old) => old.color != color;
}
