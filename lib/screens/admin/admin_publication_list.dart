import 'package:flutter/material.dart';
import '../../models/publication_model.dart';
import '../../services/firebase_service.dart';
import '../user/professional_profile_page.dart';

class AdminPublicationList extends StatefulWidget {
  const AdminPublicationList({super.key});

  @override
  State<AdminPublicationList> createState() => _AdminPublicationListState();
}

class _AdminPublicationListState extends State<AdminPublicationList> {
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
          return const Center(
            child: Text('No hay publicaciones disponibles para revisar.'),
          );
        }

        final publications = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: publications.length,
          itemBuilder: (context, index) {
            final publication = publications[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publication.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      publication.contentAsPlainText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Divider(height: 20),
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
                            radius: 16,
                            backgroundImage: publication.authorImageUrl != null
                                ? NetworkImage(publication.authorImageUrl!)
                                : null,
                            child: publication.authorImageUrl == null ? const Icon(Icons.person, size: 16) : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              publication.authorName ?? 'Autor Desconocido',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
