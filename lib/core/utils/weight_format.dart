import '../services/settings_service.dart';

const double _kgPerLb = 0.45359237;

extension WeightUnitFormat on WeightUnit {
  String get label => this == WeightUnit.kg ? 'kg' : 'lb';

  /// kg → valor en la unidad mostrada
  double fromKg(double kg) => this == WeightUnit.kg ? kg : kg / _kgPerLb;

  /// valor en la unidad mostrada → kg (para guardar en DB)
  double toKg(double value) => this == WeightUnit.kg ? value : value * _kgPerLb;
}

/// Formatea un peso (almacenado siempre en kg) en la unidad indicada,
/// con o sin sufijo " kg" / " lb".
String formatWeight(
  double kg,
  WeightUnit unit, {
  bool includeUnit = true,
}) {
  final v = unit.fromKg(kg);
  final s = v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(1);
  return includeUnit ? '$s ${unit.label}' : s;
}

/// Formatea un volumen acumulado (kg·rep). Cuando supera el umbral
/// salta a toneladas / kilolibras.
String formatVolumeInUnit(double kg, WeightUnit unit) {
  final v = unit.fromKg(kg);
  if (unit == WeightUnit.kg) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} t';
    return '${v.toStringAsFixed(0)} kg';
  } else {
    if (v >= 2000) return '${(v / 1000).toStringAsFixed(1)} klb';
    return '${v.toStringAsFixed(0)} lb';
  }
}
