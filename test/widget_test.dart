import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/providers/settings_providers.dart';
import 'package:gym_tracker/features/workout/providers/workout_providers.dart';
import 'package:gym_tracker/main.dart';

void main() {
  testWidgets('App boots and renders floating navigation', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.hasCompletedOnboarding': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          bootstrapProvider.overrideWith((ref) async {}),
          activeSessionProvider.overrideWith(
            (ref) => Stream<WorkoutSessionRow?>.value(null),
          ),
        ],
        child: const GymTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // La barra de navegación flotante muestra las tres pestañas.
    expect(find.text('Historial'), findsWidgets);
    expect(find.text('Entrenar'), findsWidgets);
    expect(find.text('Perfil'), findsWidgets);
  });
}
