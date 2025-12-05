import 'package:flutter/material.dart';

class ProfessionalProfileViewerPage extends StatelessWidget {
  final String professionalUid;

  const ProfessionalProfileViewerPage({super.key, required this.professionalUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Profesional'),
      ),
      body: Center(
        child: Text('Perfil del profesional con UID: $professionalUid'),
      ),
    );
  }
}
