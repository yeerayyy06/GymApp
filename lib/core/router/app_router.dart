import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/history/exercise_history_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/history/session_detail_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/routines/routine_edit_screen.dart';
import '../../features/routines/routines_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/workout/workout_screen.dart';
import '../../shared/main_layout.dart';
import '../providers/settings_providers.dart';

abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const history = '/history';
  static const workout = '/workout';
  static const profile = '/profile';

  static String historySession(String id) => '$history/session/$id';
  static String historyExercise(String id) => '$history/exercise/$id';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.workout,
    redirect: (context, state) {
      final completed = ref.read(settingsProvider).hasCompletedOnboarding;
      final goingToOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!completed && !goingToOnboarding) {
        return AppRoutes.onboarding;
      }
      if (completed && goingToOnboarding) {
        return AppRoutes.workout;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            MainLayout(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) {
          return _AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'session/:id',
                    builder: (context, state) => SessionDetailScreen(
                      sessionId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'exercise/:id',
                    builder: (context, state) => ExerciseHistoryScreen(
                      exerciseId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.workout,
                builder: (context, state) => const WorkoutScreen(),
                routes: [
                  GoRoute(
                    path: 'routines',
                    builder: (context, state) => const RoutinesScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) =>
                            const RoutineEditScreen(),
                      ),
                      GoRoute(
                        path: ':id/edit',
                        builder: (context, state) => RoutineEditScreen(
                          routineId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Contenedor de ramas con crossfade + scale al cambiar de pestaña.
/// Mantiene el estado de cada rama vivo (Offstage + IgnorePointer
/// para las inactivas) como hace StatefulShellRoute.indexedStack,
/// pero añade una transición suave.
class _AnimatedBranchContainer extends StatelessWidget {
  const _AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < children.length; i++)
          _branch(active: i == currentIndex, child: children[i]),
      ],
    );
  }

  Widget _branch({required bool active, required Widget child}) {
    return AnimatedScale(
      scale: active ? 1.0 : 0.98,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: active ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: IgnorePointer(
          ignoring: !active,
          child: TickerMode(
            enabled: active,
            child: child,
          ),
        ),
      ),
    );
  }
}
