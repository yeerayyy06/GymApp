import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/settings_providers.dart';
import '../../core/services/settings_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      await ref.read(settingsProvider.notifier).completeOnboarding();
      if (!mounted) return;
      context.go('/workout');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(3, (i) {
                      final active = i <= _page;
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 22 : 8,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: active
                              ? scheme.primary
                              : scheme.surfaceContainerHigh,
                        ),
                      );
                    }),
                  ),
                  if (_page < 2)
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(settingsProvider.notifier)
                            .completeOnboarding();
                        if (!context.mounted) return;
                        context.go('/workout');
                      },
                      child: const Text('Saltar'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _page = p),
                children: const [
                  _WelcomePage(),
                  _UnitsPage(),
                  _RestPage(),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_page < 2 ? 'Siguiente' : 'Empezar'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _ConcentricPainter(
                primary: scheme.primary,
                tertiary: scheme.tertiary,
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Bienvenido a\nGym Tracker',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Registra entrenamientos, sigue tu progreso y bate tus '
            'récords personales. Todos los datos se guardan en tu '
            'dispositivo.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _UnitsPage extends ConsumerWidget {
  const _UnitsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.straighten_rounded, size: 56, color: scheme.primary),
          const SizedBox(height: 24),
          Text(
            'Unidades de peso',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige cómo quieres ver los pesos en la app.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          for (final unit in WeightUnit.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SelectableTile(
                title: unit == WeightUnit.kg ? 'Kilogramos' : 'Libras',
                subtitle: unit == WeightUnit.kg ? 'kg · sistema métrico' : 'lb · sistema imperial',
                selected: settings.weightUnit == unit,
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setWeightUnit(unit),
              ),
            ),
        ],
      ),
    );
  }
}

class _RestPage extends ConsumerWidget {
  const _RestPage();

  String _format(int s) {
    final mm = s ~/ 60;
    final ss = s % 60;
    if (mm == 0) return '${ss}s';
    if (ss == 0) return '${mm}min';
    return '${mm}min ${ss}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.timer_rounded, size: 56, color: scheme.primary),
          const SizedBox(height: 24),
          Text(
            'Descanso por defecto',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'El cronómetro arrancará con este tiempo tras cada serie. '
            'Lo puedes cambiar después para cada ejercicio.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 28),
          Text(
            _format(settings.defaultRestSeconds),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: scheme.primary,
                ),
          ),
          Slider(
            value: settings.defaultRestSeconds.toDouble(),
            min: 30,
            max: 300,
            divisions: (300 - 30) ~/ 15,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .setDefaultRestSeconds(v.round()),
          ),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? scheme.primary.withValues(alpha: 0.15)
                : scheme.surfaceContainerHigh,
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected ? scheme.primary : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConcentricPainter extends CustomPainter {
  _ConcentricPainter({required this.primary, required this.tertiary});

  final Color primary;
  final Color tertiary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;

    // Anillos concéntricos
    for (var i = 4; i >= 1; i--) {
      final r = maxR * (i / 4);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            primary.withValues(alpha: 0.06 * i),
            primary.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, paint);
    }

    // Disco interior con gradiente
    final innerR = maxR * 0.36;
    final innerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, tertiary],
      ).createShader(Rect.fromCircle(center: center, radius: innerR));
    canvas.drawCircle(center, innerR, innerPaint);

    // Puntitos orbitales decorativos
    final dotPaint = Paint()..color = tertiary.withValues(alpha: 0.55);
    for (var i = 0; i < 6; i++) {
      final angle = i * (math.pi * 2 / 6);
      final r = maxR * 0.72;
      final p = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricPainter old) =>
      old.primary != primary || old.tertiary != tertiary;
}
