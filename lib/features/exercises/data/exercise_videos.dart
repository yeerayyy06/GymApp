import 'package:url_launcher/url_launcher.dart';

/// Devuelve una URL de búsqueda en YouTube para el ejercicio dado.
/// Usamos la búsqueda en lugar de IDs fijos porque YouTube ranking
/// nos da siempre tutoriales actuales y populares sin tener que
/// mantener una lista curada.
String exerciseVideoSearchUrl(String exerciseName) {
  final query = Uri.encodeQueryComponent(
    'cómo hacer $exerciseName técnica correcta',
  );
  return 'https://www.youtube.com/results?search_query=$query';
}

/// Abre YouTube con la búsqueda del ejercicio. En web abre nueva
/// pestaña; en móvil abre la app de YouTube si está instalada.
Future<void> openExerciseVideo(String exerciseName) async {
  final uri = Uri.parse(exerciseVideoSearchUrl(exerciseName));
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
