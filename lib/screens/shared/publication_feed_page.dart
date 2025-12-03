import 'package:flutter/material.dart';
import 'publication_feed_body.dart'; // Import the new body widget

class PublicationFeedPage extends StatelessWidget {
  const PublicationFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Explorar', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: const PublicationFeedBody(), // Use the new reusable widget
    );
  }
}

