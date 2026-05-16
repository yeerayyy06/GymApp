import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_tracker/main.dart';

void main() {
  testWidgets('App boots and renders bottom navigation', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GymTrackerApp()));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
