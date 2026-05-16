import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerConfig {
  const RestTimerConfig({
    required this.startedAt,
    required this.endsAt,
    required this.totalSeconds,
    this.exerciseId,
    this.exerciseName,
  });

  final DateTime startedAt;
  final DateTime endsAt;
  final int totalSeconds;
  final String? exerciseId;
  final String? exerciseName;

  RestTimerConfig copyWith({
    DateTime? endsAt,
    int? totalSeconds,
    String? exerciseId,
    String? exerciseName,
  }) {
    return RestTimerConfig(
      startedAt: startedAt,
      endsAt: endsAt ?? this.endsAt,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
    );
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerConfig?> {
  RestTimerNotifier() : super(null);

  static const Duration defaultDuration = Duration(seconds: 90);

  void start({
    Duration duration = defaultDuration,
    String? exerciseId,
    String? exerciseName,
  }) {
    final now = DateTime.now();
    state = RestTimerConfig(
      startedAt: now,
      endsAt: now.add(duration),
      totalSeconds: duration.inSeconds,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
    );
  }

  void addSeconds(int seconds) {
    final current = state;
    if (current == null) return;
    final newEnd = current.endsAt.add(Duration(seconds: seconds));
    if (newEnd.isBefore(current.startedAt)) {
      state = current.copyWith(
        endsAt: current.startedAt,
        totalSeconds: 0,
      );
      return;
    }
    state = current.copyWith(
      endsAt: newEnd,
      totalSeconds: current.totalSeconds + seconds,
    );
  }

  void skip() {
    state = null;
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerConfig?>((ref) {
  return RestTimerNotifier();
});
