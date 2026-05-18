import 'package:flutter/material.dart';

/// Tarjeta tipo bento: icono + label arriba, valor enorme abajo,
/// fondo con gradiente o color sólido. Usada en headers de tabs.
class BentoTile extends StatefulWidget {
  const BentoTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.gradient,
    this.color,
    this.onTap,
    this.widget.compact = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback? onTap;
  final bool widget.compact;

  @override
  State<BentoTile> createState() => _BentoTileState();
}

class _BentoTileState extends State<BentoTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.fromLTRB(14, widget.compact ? 10 : 12, 14, widget.compact ? 12 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: widget.gradient,
        color: widget.gradient == null ? widget.color : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    color: Colors.white.withValues(alpha: 0.9), size: 16),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  widget.label,
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
          SizedBox(height: widget.compact ? 6 : 8),
          Text(
            widget.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (widget.compact
                    ? Theme.of(context).textTheme.headlineMedium
                    : Theme.of(context).textTheme.displaySmall)
                ?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.subtitle!,
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

    final scaledContent = AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: content,
    );

    if (widget.onTap == null) return scaledContent;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        borderRadius: BorderRadius.circular(18),
        child: scaledContent,
      ),
    );
  }
}
