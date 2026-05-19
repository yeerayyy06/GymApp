import 'package:flutter/material.dart';

/// Marca compacta de la app: monograma "GT" en un cuadrado con
/// gradiente primary→tertiary. Pensada para usarse en AppBar.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: Text(
        'GT',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.5,
          letterSpacing: -0.4,
          height: 1,
        ),
      ),
    );
  }
}

/// Título del AppBar con el logo a la izquierda + texto.
class AppBarTitle extends StatelessWidget {
  const AppBarTitle({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(size: 22),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
