import 'package:flutter/material.dart';
import 'admin_publication_list.dart'; // Import the new list widget

class AdminPublicationViewPage extends StatelessWidget {
  const AdminPublicationViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisar Publicaciones'),
        backgroundColor: Colors.indigo,
      ),
      body: const AdminPublicationList(), // Use the new, purpose-built list
    );
  }
}
