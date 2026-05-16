import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/features/workout/providers/workout_providers.dart';
import 'package:gym_tracker/main.dart';

void main() {
  testWidgets('App boots and renders bottom navigation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith((ref) async {}),
          activeSessionProvider.overrideWith(
            (ref) => Stream<WorkoutSessionRow?>.value(null),
          ),
        ],
        child: const GymTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
