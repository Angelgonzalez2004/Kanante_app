import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/publication_model.dart';
import '../../services/firebase_service.dart';

class UserHomeContent extends StatefulWidget {
  const UserHomeContent({super.key});

  @override
  State<UserHomeContent> createState() => _UserHomeContentState();
}

class _UserHomeContentState extends State<UserHomeContent> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Publication>> _publicationsFuture;

  @override
  void initState() {
    super.initState();
    _publicationsFuture = _firebaseService.getAllPublications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Publication>>(
        future: _publicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay publicaciones disponibles.', style: TextStyle(color: Colors.white)),
            );
          }

          final publications = snapshot.data!;
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: publications.length,
            itemBuilder: (context, index) {
              return _buildFeedItem(publications[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildFeedItem(Publication publication) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        image: publication.attachments.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(publication.attachments.first),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withAlpha(77), BlendMode.darken),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0) + const EdgeInsets.only(bottom: 60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: publication.authorImageUrl != null
                      ? CachedNetworkImageProvider(publication.authorImageUrl!)
                      : null,
                  child: publication.authorImageUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Text(
                  publication.authorName ?? 'Autor Desconocido',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              publication.title,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4)]),
            ),
            const SizedBox(height: 8),
            Text(
              publication.contentAsPlainText,
              style: const TextStyle(color: Colors.white, fontSize: 16, shadows: [Shadow(blurRadius: 2)]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}