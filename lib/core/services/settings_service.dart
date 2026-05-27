import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeightUnit { kg, lbs }

enum AppearanceMode { mono, color }

extension AppearanceModeX on AppearanceMode {
  String get label =>
      this == AppearanceMode.mono ? 'Monocromo' : 'Color';
}

enum AccentColor { indigo, violet, green, orange, blue, pink }

extension AccentColorX on AccentColor {
  Color get seed {
    switch (this) {
      case AccentColor.indigo:
        return const Color(0xFF6366F1);
      case AccentColor.violet:
        return const Color(0xFF8B5CF6);
      case AccentColor.green:
        return const Color(0xFF10B981);
      case AccentColor.orange:
        return const Color(0xFFF97316);
      case AccentColor.blue:
        return const Color(0xFF3B82F6);
      case AccentColor.pink:
        return const Color(0xFFEC4899);
    }
  }

  String get label {
    switch (this) {
      case AccentColor.indigo:
        return 'Índigo';
      case AccentColor.violet:
        return 'Violeta';
      case AccentColor.green:
        return 'Verde';
      case AccentColor.orange:
        return 'Naranja';
      case AccentColor.blue:
        return 'Azul';
      case AccentColor.pink:
        return 'Rosa';
    }
  }
}

@immutable
class SettingsState {
  const SettingsState({
    this.defaultRestSeconds = 90,
    this.exerciseRestSeconds = const <String, int>{},
    this.weightUnit = WeightUnit.kg,
    this.hasCompletedOnboarding = false,
    this.restNotificationsEnabled = false,
    this.accentColor = AccentColor.indigo,
    this.appearanceMode = AppearanceMode.mono,
  });

  final int defaultRestSeconds;
  final Map<String, int> exerciseRestSeconds;
  final WeightUnit weightUnit;
  final bool hasCompletedOnboarding;
  final bool restNotificationsEnabled;
  final AccentColor accentColor;
  final AppearanceMode appearanceMode;

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
    AccentColor? accentColor,
    AppearanceMode? appearanceMode,
  }) {
    return SettingsState(
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      exerciseRestSeconds: exerciseRestSeconds ?? this.exerciseRestSeconds,
      weightUnit: weightUnit ?? this.weightUnit,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      restNotificationsEnabled:
          restNotificationsEnabled ?? this.restNotificationsEnabled,
      accentColor: accentColor ?? this.accentColor,
      appearanceMode: appearanceMode ?? this.appearanceMode,
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
  static const _accentKey = 'settings.accentColor';
  static const _appearanceKey = 'settings.appearanceMode';

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
    final accentName =
        _prefs.getString(_accentKey) ?? AccentColor.indigo.name;
    final accent = AccentColor.values.firstWhere(
      (a) => a.name == accentName,
      orElse: () => AccentColor.indigo,
    );
    final appearanceName =
        _prefs.getString(_appearanceKey) ?? AppearanceMode.mono.name;
    final appearance = AppearanceMode.values.firstWhere(
      (a) => a.name == appearanceName,
      orElse: () => AppearanceMode.mono,
    );
    return SettingsState(
      defaultRestSeconds: defaultRest,
      exerciseRestSeconds: perExercise,
      weightUnit: unit,
      hasCompletedOnboarding: _prefs.getBool(_onboardingKey) ?? false,
      restNotificationsEnabled: _prefs.getBool(_restNotifyKey) ?? false,
      accentColor: accent,
      appearanceMode: appearance,
    );
  }

  Future<void> saveAccentColor(AccentColor accent) async {
    await _prefs.setString(_accentKey, accent.name);
  }

  Future<void> saveAppearanceMode(AppearanceMode mode) async {
    await _prefs.setString(_appearanceKey, mode.name);
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
