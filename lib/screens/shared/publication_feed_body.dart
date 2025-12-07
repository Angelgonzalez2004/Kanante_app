import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/publication_model.dart';
import '../../services/firebase_service.dart';
import '../user/professional_profile_page.dart';

class PublicationFeedBody extends StatefulWidget {
  final Color textColor;
  const PublicationFeedBody({super.key, this.textColor = Colors.white});

  @override
  State<PublicationFeedBody> createState() => _PublicationFeedBodyState();
}

class _PublicationFeedBodyState extends State<PublicationFeedBody> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Publication>> _publicationsFuture;

  @override
  void initState() {
    super.initState();
    _publicationsFuture = _firebaseService.getAllPublications();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Publication>>(
      future: _publicationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('No hay publicaciones disponibles.', style: TextStyle(color: widget.textColor)),
          );
        }

        final publications = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800.0), // Max width for feed items on large screens
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: publications.length,
              itemBuilder: (context, index) {
                return _buildFeedItem(publications[index]);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedItem(Publication publication) {
    // This logic remains the same, just using widget.textColor
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        image: publication.attachments.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(publication.attachments.first),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withAlpha(102), BlendMode.darken),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0) + const EdgeInsets.only(bottom: 60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfessionalProfilePage(professionalId: publication.professionalUid),
                  ),
                );
              },
              child: Row(
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
                    style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (publication.authorVerificationStatus == 'verified')
                    Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: Icon(Icons.verified, color: widget.textColor, size: 16),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              publication.title,
              style: TextStyle(color: widget.textColor, fontSize: 24, fontWeight: FontWeight.bold, shadows: const [Shadow(blurRadius: 4)]),
            ),
            const SizedBox(height: 8),
            Text(
              publication.contentAsPlainText,
              style: TextStyle(color: widget.textColor, fontSize: 16, shadows: const [Shadow(blurRadius: 2)]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
