import 'package:flutter/material.dart';

/// Tarjeta tipo bento: icono + label arriba, valor enorme abajo,
/// fondo con gradiente o color sólido. Usada en headers de tabs.
class BentoTile extends StatelessWidget {
  const BentoTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.gradient,
    this.color,
    this.onTap,
    this.compact = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.fromLTRB(14, compact ? 10 : 12, 14, compact ? 12 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: gradient,
        color: gradient == null ? color : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon,
                    color: Colors.white.withValues(alpha: 0.9), size: 16),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (compact
                    ? Theme.of(context).textTheme.headlineMedium
                    : Theme.of(context).textTheme.displaySmall)
                ?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: content,
      ),
    );
  }
}
