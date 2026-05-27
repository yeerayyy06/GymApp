import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/settings_providers.dart';
import '../../../core/services/health_service.dart';
import '../../../core/utils/formatters.dart';
import '../../history/providers/history_providers.dart';

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService(ref.watch(sharedPreferencesProvider));
});

class HealthNotifier extends StateNotifier<HealthData> {
  HealthNotifier(this._service) : super(_service.load());

  final HealthService _service;

  Future<void> setSleep(DateTime day, int minutes, int quality) async {
    final map = Map<String, SleepEntry>.from(state.sleepByDate);
    map[dayKey(day)] = SleepEntry(minutes: minutes, quality: quality);
    state = state.copyWith(sleepByDate: map);
    await _service.saveSleep(day, minutes, quality);
  }

  Future<void> setWater(DateTime day, int glasses) async {
    final clamped = glasses < 0 ? 0 : glasses;
    final map = Map<String, int>.from(state.waterByDate);
    map[dayKey(day)] = clamped;
    state = state.copyWith(waterByDate: map);
    await _service.saveWater(day, clamped);
  }

  Future<void> setEnergy(DateTime day, int value) async {
    final map = Map<String, int>.from(state.energyByDate);
    map[dayKey(day)] = value;
    state = state.copyWith(energyByDate: map);
    await _service.saveEnergy(day, value);
  }

  Future<void> setSleepGoal(int minutes) async {
    state = state.copyWith(sleepGoalMinutes: minutes);
    await _service.saveSleepGoal(minutes);
  }

  Future<void> setWaterGoal(int glasses) async {
    state = state.copyWith(waterGoalGlasses: glasses);
    await _service.saveWaterGoal(glasses);
  }
}

final healthProvider =
    StateNotifierProvider<HealthNotifier, HealthData>((ref) {
  return HealthNotifier(ref.watch(healthServiceProvider));
});

/// Series de trabajo registradas hoy (para el anillo de entreno).
final todaySetsProvider = Provider<int>((ref) {
  final now = ref.watch(clockProvider)();
  final today = startOfDay(now);
  final async = ref.watch(sessionSummariesProvider);
  return async.maybeWhen(
    data: (sums) {
      var total = 0;
      for (final s in sums) {
        if (startOfDay(s.session.startedAt) == today) {
          total += s.totalSets;
        }
      }
      return total;
    },
    orElse: () => 0,
  );
});

/// Objetivo de series diarias (fijo por ahora).
const dailySetsGoal = 12;
