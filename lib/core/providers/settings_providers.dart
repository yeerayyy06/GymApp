import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/csv_export_service.dart';
import '../services/demo_data_service.dart';
import '../services/settings_service.dart';
import 'clock_provider.dart';
import 'database_provider.dart';
import 'id_provider.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() before runApp.',
  );
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(sharedPreferencesProvider));
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._service) : super(_service.load());

  final SettingsService _service;

  Future<void> setDefaultRestSeconds(int seconds) async {
    state = state.copyWith(defaultRestSeconds: seconds);
    await _service.saveDefaultRestSeconds(seconds);
  }

  Future<void> setExerciseRestSeconds(
    String exerciseId,
    int? seconds,
  ) async {
    final map = Map<String, int>.from(state.exerciseRestSeconds);
    if (seconds == null) {
      map.remove(exerciseId);
    } else {
      map[exerciseId] = seconds;
    }
    state = state.copyWith(exerciseRestSeconds: map);
    await _service.saveExerciseRestSeconds(exerciseId, seconds);
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    state = state.copyWith(weightUnit: unit);
    await _service.saveWeightUnit(unit);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(hasCompletedOnboarding: true);
    await _service.saveOnboardingCompleted(true);
  }

  Future<void> setRestNotificationsEnabled(bool value) async {
    state = state.copyWith(restNotificationsEnabled: value);
    await _service.saveRestNotificationsEnabled(value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.watch(settingsServiceProvider));
});

final demoDataServiceProvider = Provider<DemoDataService>((ref) {
  return DemoDataService(
    db: ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
});

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  return CsvExportService(ref.watch(databaseProvider));
});
