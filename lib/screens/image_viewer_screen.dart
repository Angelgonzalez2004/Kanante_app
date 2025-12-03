import 'package:flutter/material.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewerScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Ver Imagen', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true, // Allows panning
          minScale: 0.5, // Minimum scale factor
          maxScale: 4.0, // Maximum scale factor
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain, // Ensure the whole image is visible
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.error, color: Colors.red, size: 50),
              );
            },
          ),
        ),
      ),
    );
  }
}
