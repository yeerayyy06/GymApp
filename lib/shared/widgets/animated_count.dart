import 'package:flutter/material.dart';

/// Anima un número entero desde 0 (o desde el valor previo) hasta
/// [value] con un tween. Usa TweenAnimationBuilder<int> para
/// rebuild eficiente sin AnimationController manual.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeOutCubic,
  });

  final int value;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, v, _) {
        return Text(
          v.round().toString(),
          style: style,
        );
      },
    );
  }
}
