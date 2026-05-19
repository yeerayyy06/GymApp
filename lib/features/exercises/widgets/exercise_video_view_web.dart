import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Reproductor embebido de YouTube via iframe. Usa el endpoint
/// listType=search para mostrar la búsqueda de la técnica del
/// ejercicio sin necesidad de mantener IDs curados.
class ExerciseVideoView extends StatefulWidget {
  const ExerciseVideoView({super.key, required this.exerciseName});

  final String exerciseName;

  @override
  State<ExerciseVideoView> createState() => _ExerciseVideoViewState();
}

class _ExerciseVideoViewState extends State<ExerciseVideoView> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'yt-${widget.exerciseName.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
    final query = Uri.encodeQueryComponent(
      'cómo hacer ${widget.exerciseName} técnica correcta tutorial',
    );
    final src = 'https://www.youtube.com/embed?listType=search&list=$query';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = web.HTMLIFrameElement()
          ..src = src
          ..allow =
              'autoplay; encrypted-media; picture-in-picture; fullscreen'
          ..allowFullscreen = true;
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.style.backgroundColor = '#000';
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
