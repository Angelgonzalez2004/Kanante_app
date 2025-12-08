import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kanante_app/models/publication_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:intl/intl.dart';

class ProfessionalPublicationsListScreen extends StatefulWidget {
  final String professionalUid;

  const ProfessionalPublicationsListScreen({super.key, required this.professionalUid});

  @override
  State<ProfessionalPublicationsListScreen> createState() => _ProfessionalPublicationsListScreenState();
}

class _ProfessionalPublicationsListScreenState extends State<ProfessionalPublicationsListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Publication>> _publicationsFuture;

  @override
  void initState() {
    super.initState();
    _publicationsFuture = _firebaseService.getPublicationsForProfessional(widget.professionalUid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Publication>>(
      future: _publicationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Este profesional aún no tiene publicaciones.'));
        }

        final publications = snapshot.data!;
        return ListView.builder(
          itemCount: publications.length,
          itemBuilder: (context, index) {
            final publication = publications[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (publication.attachments.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: publication.attachments.first,
                      fit: BoxFit.cover,
                      height: 200,
                      width: double.infinity,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(publication.title, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(publication.contentAsPlainText, maxLines: 3, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text('Publicado el: ${DateFormat('dd/MM/yyyy').format(publication.createdAt)}'),
                        // Add like/comment/share buttons here if needed for this view,
                        // but the main feed is already interactive.
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
