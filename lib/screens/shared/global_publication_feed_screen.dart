import 'package:flutter/material.dart';
import 'package:kanante_app/models/publication_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class GlobalPublicationFeedScreen extends StatefulWidget {
  const GlobalPublicationFeedScreen({super.key});

  @override
  State<GlobalPublicationFeedScreen> createState() => _GlobalPublicationFeedScreenState();
}

class _GlobalPublicationFeedScreenState extends State<GlobalPublicationFeedScreen> {
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
      appBar: AppBar(
        title: const Text('Feed de Publicaciones'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: FutureBuilder<List<Publication>>(
        future: _publicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar publicaciones: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay publicaciones disponibles.'));
          }

          final publications = snapshot.data!;
          return ListView.builder(
            itemCount: publications.length,
            itemBuilder: (context, index) {
              final publication = publications[index];
              return PublicationCard(publication: publication);
            },
          );
        },
      ),
    );
  }
}

class PublicationCard extends StatelessWidget {
  final Publication publication;
  const PublicationCard({super.key, required this.publication});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAuthorInfo(context),
            const SizedBox(height: 12),
            Text(
              publication.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              publication.contentAsPlainText, // Display plain text content
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (publication.attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildAttachments(context),
            ],
            const SizedBox(height: 12),
            _buildActionButtons(context), // Placeholder for like, comment, share
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: publication.authorImageUrl != null && publication.authorImageUrl!.isNotEmpty
              ? CachedNetworkImageProvider(publication.authorImageUrl!)
              : null,
          child: (publication.authorImageUrl == null || publication.authorImageUrl!.isEmpty)
              ? const Icon(Icons.person, size: 20)
              : null,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              publication.authorName ?? 'Profesional Desconocido',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('dd MMM yyyy').format(publication.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        if (publication.authorVerificationStatus == 'verified')
          const Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Icon(Icons.verified, color: Colors.blue, size: 18),
          ),
      ],
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return SizedBox(
      height: 200, // Fixed height for image display
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: publication.attachments.length,
        itemBuilder: (context, index) {
          final imageUrl = publication.attachments[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 180,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TextButton.icon(
          onPressed: () {
            // TODO: Implement Like functionality
          },
          icon: const Icon(Icons.thumb_up_alt_outlined),
          label: const Text('Like (0)'),
        ),
        TextButton.icon(
          onPressed: () {
            // TODO: Implement Comment functionality
          },
          icon: const Icon(Icons.comment_outlined),
          label: const Text('Comentar'),
        ),
        TextButton.icon(
          onPressed: () {
            // TODO: Implement Share functionality
          },
          icon: const Icon(Icons.share_outlined),
          label: const Text('Compartir'),
        ),
      ],
    );
  }
}