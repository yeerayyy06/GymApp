import 'package:flutter/material.dart';

import '../../core/domain/muscle_color.dart';
import '../../core/domain/muscle_group.dart';

class MusclePill extends StatelessWidget {
  const MusclePill({
    super.key,
    required this.muscle,
    this.dense = false,
  });

  final MuscleGroup muscle;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = muscle.brandColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2 : 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: dense ? 4 : 5),
          Text(
            muscle.displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 10 : 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
