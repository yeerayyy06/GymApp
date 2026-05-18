import 'dart:ui';

import 'package:flutter/material.dart';

/// Muestra un diálogo con fondo borroso (frosted glass) detrás.
/// API similar a showDialog pero con backdrop blur.
Future<T?> showBlurredDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: 'dialog',
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, anim, _) {
      return Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
          Center(child: builder(context)),
        ],
      );
    },
    transitionBuilder: (context, anim, _, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curve,
        child: Transform.scale(
          scale: 0.94 + curve.value * 0.06,
          child: child,
        ),
      );
    },
  );
}
