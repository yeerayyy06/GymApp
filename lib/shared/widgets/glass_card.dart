import 'dart:ui';

import 'package:flutter/material.dart';

/// Tarjeta con efecto cristal esmerilado: blur del fondo + relleno
/// translúcido + borde luminoso + ligero gradiente. Da sensación
/// premium en superficies destacadas.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(12, 8, 12, 4),
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tintColor = tint ?? scheme.primary;
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tintColor.withValues(alpha: 0.10),
                  scheme.surfaceContainerHigh.withValues(alpha: 0.55),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
