import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Pequeño wrapper sobre Web Audio API para generar pitidos sin
/// necesidad de bundlear ningún asset. En plataformas no-web hace
/// no-op silenciosamente.
class AudioService {
  static web.AudioContext? _ctx;

  /// Llamar en un user gesture (p.ej. cuando arranca el rest timer)
  /// para que el AudioContext esté listo y los siguientes beeps
  /// no caigan por la política de autoplay.
  static void warmUp() {
    if (!kIsWeb) return;
    try {
      _ctx ??= web.AudioContext();
      if (_ctx!.state == 'suspended') {
        _ctx!.resume();
      }
    } catch (_) {}
  }

  /// Beep de un solo tono.
  static void beep({double freq = 880, double duration = 0.15}) {
    if (!kIsWeb) return;
    try {
      _ctx ??= web.AudioContext();
      final ctx = _ctx!;
      if (ctx.state == 'suspended') {
        ctx.resume();
      }
      final osc = ctx.createOscillator();
      osc.frequency.value = freq;
      osc.type = 'sine';

      final gain = ctx.createGain();
      gain.gain.value = 0;
      final now = ctx.currentTime;
      gain.gain.linearRampToValueAtTime(0.28, now + 0.01);
      gain.gain.linearRampToValueAtTime(0, now + duration);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start();
      osc.stop(now + duration + 0.02);
    } catch (_) {}
  }

  /// "¡Listo!": dos tonos descendentes, estilo timbre suave.
  static void timerEnd() {
    if (!kIsWeb) return;
    beep(freq: 880, duration: 0.12);
    Future<void>.delayed(
      const Duration(milliseconds: 140),
      () => beep(freq: 660, duration: 0.18),
    );
  }
}
