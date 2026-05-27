import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

@immutable
class SleepEntry {
  const SleepEntry({required this.minutes, required this.quality});
  final int minutes; // duración total dormida
  final int quality; // 1-5

  double get hours => minutes / 60.0;
}

@immutable
class HealthData {
  const HealthData({
    this.sleepByDate = const {},
    this.waterByDate = const {},
    this.energyByDate = const {},
    this.sleepGoalMinutes = 480, // 8h
    this.waterGoalGlasses = 8,
  });

  final Map<String, SleepEntry> sleepByDate;
  final Map<String, int> waterByDate;
  final Map<String, int> energyByDate;
  final int sleepGoalMinutes;
  final int waterGoalGlasses;

  SleepEntry? sleepFor(DateTime d) => sleepByDate[dayKey(d)];
  int waterFor(DateTime d) => waterByDate[dayKey(d)] ?? 0;
  int? energyFor(DateTime d) => energyByDate[dayKey(d)];

  HealthData copyWith({
    Map<String, SleepEntry>? sleepByDate,
    Map<String, int>? waterByDate,
    Map<String, int>? energyByDate,
    int? sleepGoalMinutes,
    int? waterGoalGlasses,
  }) {
    return HealthData(
      sleepByDate: sleepByDate ?? this.sleepByDate,
      waterByDate: waterByDate ?? this.waterByDate,
      energyByDate: energyByDate ?? this.energyByDate,
      sleepGoalMinutes: sleepGoalMinutes ?? this.sleepGoalMinutes,
      waterGoalGlasses: waterGoalGlasses ?? this.waterGoalGlasses,
    );
  }
}

class HealthService {
  HealthService(this._prefs);

  final SharedPreferences _prefs;

  static const _sleepPrefix = 'health.sleep.';
  static const _waterPrefix = 'health.water.';
  static const _energyPrefix = 'health.energy.';
  static const _sleepGoalKey = 'health.goal.sleepMinutes';
  static const _waterGoalKey = 'health.goal.waterGlasses';

  HealthData load() {
    final sleep = <String, SleepEntry>{};
    final water = <String, int>{};
    final energy = <String, int>{};
    for (final key in _prefs.getKeys()) {
      if (key.startsWith(_sleepPrefix)) {
        final raw = _prefs.getString(key);
        if (raw != null) {
          final parts = raw.split(':');
          if (parts.length == 2) {
            sleep[key.substring(_sleepPrefix.length)] = SleepEntry(
              minutes: int.tryParse(parts[0]) ?? 0,
              quality: int.tryParse(parts[1]) ?? 3,
            );
          }
        }
      } else if (key.startsWith(_waterPrefix)) {
        final v = _prefs.getInt(key);
        if (v != null) water[key.substring(_waterPrefix.length)] = v;
      } else if (key.startsWith(_energyPrefix)) {
        final v = _prefs.getInt(key);
        if (v != null) energy[key.substring(_energyPrefix.length)] = v;
      }
    }
    return HealthData(
      sleepByDate: sleep,
      waterByDate: water,
      energyByDate: energy,
      sleepGoalMinutes: _prefs.getInt(_sleepGoalKey) ?? 480,
      waterGoalGlasses: _prefs.getInt(_waterGoalKey) ?? 8,
    );
  }

  Future<void> saveSleep(DateTime d, int minutes, int quality) =>
      _prefs.setString('$_sleepPrefix${dayKey(d)}', '$minutes:$quality');

  Future<void> saveWater(DateTime d, int glasses) =>
      _prefs.setInt('$_waterPrefix${dayKey(d)}', glasses);

  Future<void> saveEnergy(DateTime d, int value) =>
      _prefs.setInt('$_energyPrefix${dayKey(d)}', value);

  Future<void> saveSleepGoal(int minutes) =>
      _prefs.setInt(_sleepGoalKey, minutes);

  Future<void> saveWaterGoal(int glasses) =>
      _prefs.setInt(_waterGoalKey, glasses);
}
