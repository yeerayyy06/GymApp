import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeightUnit { kg, lbs }

@immutable
class SettingsState {
  const SettingsState({
    this.defaultRestSeconds = 90,
    this.exerciseRestSeconds = const <String, int>{},
    this.weightUnit = WeightUnit.kg,
    this.hasCompletedOnboarding = false,
    this.restNotificationsEnabled = false,
  });

  final int defaultRestSeconds;
  final Map<String, int> exerciseRestSeconds;
  final WeightUnit weightUnit;
  final bool hasCompletedOnboarding;
  final bool restNotificationsEnabled;

  int restSecondsFor(String? exerciseId) {
    if (exerciseId == null) return defaultRestSeconds;
    return exerciseRestSeconds[exerciseId] ?? defaultRestSeconds;
  }

  bool hasCustomRest(String exerciseId) =>
      exerciseRestSeconds.containsKey(exerciseId);

  SettingsState copyWith({
    int? defaultRestSeconds,
    Map<String, int>? exerciseRestSeconds,
    WeightUnit? weightUnit,
    bool? hasCompletedOnboarding,
    bool? restNotificationsEnabled,
  }) {
    return SettingsState(
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      exerciseRestSeconds: exerciseRestSeconds ?? this.exerciseRestSeconds,
      weightUnit: weightUnit ?? this.weightUnit,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      restNotificationsEnabled:
          restNotificationsEnabled ?? this.restNotificationsEnabled,
    );
  }
}

class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const _defaultRestKey = 'settings.defaultRestSeconds';
  static const _exerciseRestPrefix = 'settings.restForExercise.';
  static const _weightUnitKey = 'settings.weightUnit';
  static const _onboardingKey = 'settings.hasCompletedOnboarding';
  static const _restNotifyKey = 'settings.restNotificationsEnabled';

  SettingsState load() {
    final defaultRest = _prefs.getInt(_defaultRestKey) ?? 90;
    final unitName =
        _prefs.getString(_weightUnitKey) ?? WeightUnit.kg.name;
    final unit = WeightUnit.values.firstWhere(
      (u) => u.name == unitName,
      orElse: () => WeightUnit.kg,
    );
    final perExercise = <String, int>{};
    for (final key in _prefs.getKeys()) {
      if (key.startsWith(_exerciseRestPrefix)) {
        final exerciseId = key.substring(_exerciseRestPrefix.length);
        final value = _prefs.getInt(key);
        if (value != null) perExercise[exerciseId] = value;
      }
    }
    return SettingsState(
      defaultRestSeconds: defaultRest,
      exerciseRestSeconds: perExercise,
      weightUnit: unit,
      hasCompletedOnboarding: _prefs.getBool(_onboardingKey) ?? false,
      restNotificationsEnabled: _prefs.getBool(_restNotifyKey) ?? false,
    );
  }

  Future<void> saveOnboardingCompleted(bool value) async {
    await _prefs.setBool(_onboardingKey, value);
  }

  Future<void> saveRestNotificationsEnabled(bool value) async {
    await _prefs.setBool(_restNotifyKey, value);
  }

  Future<void> saveDefaultRestSeconds(int seconds) async {
    await _prefs.setInt(_defaultRestKey, seconds);
  }

  Future<void> saveExerciseRestSeconds(String exerciseId, int? seconds) async {
    final key = '$_exerciseRestPrefix$exerciseId';
    if (seconds == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setInt(key, seconds);
    }
  }

  Future<void> saveWeightUnit(WeightUnit unit) async {
    await _prefs.setString(_weightUnitKey, unit.name);
  }
}
