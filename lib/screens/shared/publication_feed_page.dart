import 'package:flutter/material.dart';
import 'publication_feed_body.dart'; // Import the new body widget

class PublicationFeedPage extends StatelessWidget {
  const PublicationFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Material( // Added Material widget
      type: MaterialType.transparency, // Use transparency to avoid visual changes
      child: PublicationFeedBody(), // Use the new reusable widget
    );
  }
}

