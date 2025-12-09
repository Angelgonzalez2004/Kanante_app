import 'package:flutter/material.dart';
import '../../models/publication_model.dart';
import '../../services/firebase_service.dart';
import '../professional/professional_profile_viewer_page.dart'; // To view professional profile
import '../professional/new_publication_page.dart'; // To edit publication

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
    _loadPublications();
  }

  void _loadPublications() {
    setState(() {
      // Fetch all publications for admin moderation
      _publicationsFuture = _firebaseService.getAllPublications();
    });
  }

  Future<void> _updatePublicationStatus(String publicationId, String newStatus) async {
    try {
      await _firebaseService.updatePublicationStatus(publicationId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado de publicación actualizado a $newStatus.')),
        );
        _loadPublications(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar estado: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePublication(String publicationId) async {
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta publicación permanentemente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await _firebaseService.deletePublication(publicationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publicación eliminada con éxito.')),
          );
          _loadPublications(); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar publicación: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
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
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900.0), // Max width for the list on large screens
            child: ListView.builder(
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
                        Text('Estado: ${publication.status}', style: const TextStyle(fontStyle: FontStyle.italic)),
                        const SizedBox(height: 8),
                        Text(
                          publication.contentAsPlainText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Divider(height: 20),
                        // Professional Info
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfessionalProfileViewerPage(professionalUid: publication.professionalUid),
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
                        const Divider(height: 20),
                        // Moderation Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NewPublicationPage(publicationId: publication.id),
                                ),
                              ),
                              icon: const Icon(Icons.edit),
                              label: const Text('Editar'),
                            ),
                            if (publication.status == 'published')
                              ElevatedButton.icon(
                                onPressed: () => _updatePublicationStatus(publication.id, 'unpublished'),
                                icon: const Icon(Icons.visibility_off),
                                label: const Text('Despublicar'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () => _updatePublicationStatus(publication.id, 'published'),
                                icon: const Icon(Icons.visibility),
                                label: const Text('Publicar'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                            ElevatedButton.icon(
                              onPressed: () => _deletePublication(publication.id),
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('Eliminar'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
