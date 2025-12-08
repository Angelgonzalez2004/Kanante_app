import 'package:flutter/material.dart';

class CommentsScreen extends StatelessWidget {
  final String publicationId;

  const CommentsScreen({super.key, required this.publicationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarios'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Pantalla de Comentarios para la publicación:'),
            Text(publicationId),
            const SizedBox(height: 20),
            const Text('¡Funcionalidad de comentarios en construcción!'),
          ],
        ),
      ),
    );
  }
}
