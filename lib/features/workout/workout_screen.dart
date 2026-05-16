import 'package:flutter/material.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenar'),
      ),
      body: const Center(
        child: Text('Pantalla de Entrenamiento'),
      ),
    );
  }
}
