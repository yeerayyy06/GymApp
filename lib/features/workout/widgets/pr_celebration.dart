import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PRKind { weight, oneRm }

class PRCelebration {
  static Future<void> show(
    BuildContext context, {
    required String exerciseName,
    required double weightKg,
    required int reps,
    required Set<PRKind> kinds,
  }) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog(
      context: context,
      barrierLabel: 'PR',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) {
        return _PRCelebrationContent(
          exerciseName: exerciseName,
          weightKg: weightKg,
          reps: reps,
          kinds: kinds,
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }
}

class _PRCelebrationContent extends StatefulWidget {
  const _PRCelebrationContent({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.kinds,
  });

  final String exerciseName;
  final double weightKg;
  final int reps;
  final Set<PRKind> kinds;

  @override
  State<_PRCelebrationContent> createState() => _PRCelebrationContentState();
}

class _PRCelebrationContentState extends State<_PRCelebrationContent> {
  late final ConfettiController _confetti;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 1500));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confetti.play();
    });
    _autoDismiss = Timer(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  String _fmtWeight(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String _kindLabel() {
    if (widget.kinds.length == 2) return 'Peso y 1RM estimado';
    if (widget.kinds.contains(PRKind.weight)) return 'Peso máximo';
    return '1RM estimado';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Confeti centrado
        Align(
          alignment: const Alignment(0, -0.3),
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 24,
            maxBlastForce: 22,
            minBlastForce: 8,
            emissionFrequency: 0.04,
            gravity: 0.35,
            colors: [
              scheme.primary,
              scheme.secondary,
              scheme.tertiary,
              const Color(0xFFFFD54F),
              const Color(0xFFEC407A),
            ],
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: scheme.surfaceContainerHigh,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary,
                              scheme.tertiary,
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¡PR!',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [
                                    scheme.primary,
                                    scheme.tertiary,
                                  ],
                                ).createShader(
                                  const Rect.fromLTWH(0, 0, 200, 60),
                                ),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _kindLabel(),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.exerciseName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_fmtWeight(widget.weightKg)} kg × ${widget.reps}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Tap para cerrar',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Secundario emisor desde abajo izquierda y derecha
        Positioned(
          left: 24,
          bottom: 24,
          child: Transform.rotate(
            angle: -math.pi / 4,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: 0,
              shouldLoop: false,
              numberOfParticles: 10,
              maxBlastForce: 18,
              gravity: 0.4,
              colors: [
                scheme.primary,
                scheme.tertiary,
              ],
            ),
          ),
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: Transform.rotate(
            angle: math.pi + math.pi / 4,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: 0,
              shouldLoop: false,
              numberOfParticles: 10,
              maxBlastForce: 18,
              gravity: 0.4,
              colors: [
                scheme.primary,
                scheme.tertiary,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
