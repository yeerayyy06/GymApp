const List<String> _monthsAbbrEs = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

const List<String> _weekdaysEs = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

String formatDuration(Duration d) {
  if (d.inHours > 0) {
    final mins = d.inMinutes.remainder(60);
    return '${d.inHours}h ${mins}min';
  }
  if (d.inMinutes > 0) return '${d.inMinutes}min';
  return '${d.inSeconds}s';
}

String formatWeightKg(double kg) {
  if (kg == kg.roundToDouble()) return '${kg.toStringAsFixed(0)} kg';
  return '${kg.toStringAsFixed(1)} kg';
}

String formatVolume(double kg) {
  if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(1)} t';
  return '${kg.toStringAsFixed(0)} kg';
}

String formatNumber(num value) => value.toStringAsFixed(0);

String formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')} '
      '${_monthsAbbrEs[dt.month - 1]} '
      '${dt.year}';
}

String formatTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String formatRelativeDate(DateTime dt, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(dt.year, dt.month, dt.day);
  final diffDays = today.difference(target).inDays;
  if (diffDays == 0) return 'Hoy';
  if (diffDays == 1) return 'Ayer';
  if (diffDays > 1 && diffDays < 7) {
    return _weekdaysEs[dt.weekday - 1];
  }
  return formatDate(dt);
}

DateTime startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

DateTime startOfWeek(DateTime now) {
  final today = startOfDay(now);
  return today.subtract(Duration(days: today.weekday - DateTime.monday));
}

DateTime startOfMonth(DateTime now) => DateTime(now.year, now.month, 1);
