import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Importa el servicio de Firebase
import 'package:kanante_app/services/firebase_service.dart';

// ESTA ES LA LÍNEA CLAVE QUE DEBES ASEGURARTE DE TENER:
import 'package:kanante_app/models/publication_model.dart'; 

// Importa la página de perfil del profesional
import '../professional/professional_profile_viewer_page.dart';

class ProfessionalContentScreen extends StatefulWidget {
  const ProfessionalContentScreen({super.key});

  @override
  State<ProfessionalContentScreen> createState() => _ProfessionalContentScreenState();
}

class _ProfessionalContentScreenState extends State<ProfessionalContentScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Publication>> _publicationsFuture;

  @override
  void initState() {
    super.initState();
    _publicationsFuture = _firebaseService.getAllPublications();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800.0), // Max width for the feed
        child: FutureBuilder<List<Publication>>(
          future: _publicationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No hay publicaciones disponibles.',
                  style: TextStyle(color: Colors.white),
                ),
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
                // 2. CORRECCIÓN: Actualizado para Flutter 3.27+ (antes withOpacity)
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.3), 
                  BlendMode.darken,
                ),
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
                    builder: (context) => ProfessionalProfileViewerPage(
                      professionalUid: publication.professionalUid,
                    ),
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
                    child: publication.authorImageUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    publication.authorName ?? 'Autor Desconocido',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (publication.authorVerificationStatus == 'verified')
                    const Padding(
                      padding: EdgeInsets.only(left: 6.0),
                      child: Icon(Icons.verified, color: Colors.white, size: 16),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              publication.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              publication.contentAsPlainText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [Shadow(blurRadius: 2)],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}