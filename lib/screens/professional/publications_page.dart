import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:intl/intl.dart';

import 'new_publication_page.dart';
import 'publication_detail_page.dart';
import '../image_viewer_screen.dart'; // Import the new image viewer screen
import 'edit_publication_page.dart'; // Import the new edit publication screen


class PublicationsPage extends StatefulWidget {
  const PublicationsPage({super.key});

  @override
  _PublicationsPageState createState() => _PublicationsPageState();
}

class _PublicationsPageState extends State<PublicationsPage> {
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  late Query _publicationsQuery;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _publicationsQuery = _db.child('publications').orderByChild('professionalUid').equalTo(user.uid);
    } else {
      _publicationsQuery = _db.child('publications').limitToFirst(0);
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Inicia sesión para ver tus publicaciones.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Publicaciones'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar publicaciones...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _publicationsQuery.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rawData = snapshot.data!.snapshot.value;
                print('DEBUG: Raw data from Firebase: $rawData');

                Map<String, dynamic> publicationsMap = {};
                if (rawData is Map) {
                  publicationsMap = Map<String, dynamic>.from(rawData);
                } else {
                  print('DEBUG: Unexpected data format (not a Map): $rawData');
                  return const Center(child: Text('Formato de publicaciones inesperado.'));
                }

                final publications = publicationsMap;
                final publicationList = publications.entries.toList();
                print('DEBUG: Processed publication list: $publicationList');

                final filteredPublicationList = publicationList.where((entry) {
                  final publication = Map<String, dynamic>.from(entry.value);
                  final title = publication['title']?.toString().toLowerCase() ?? '';
                  return title.contains(_searchQuery.toLowerCase());
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: filteredPublicationList.length,
                  itemBuilder: (context, index) {
                    final publicationId = filteredPublicationList[index].key;
                    final publication = Map<String, dynamic>.from(filteredPublicationList[index].value);
                    return _PublicationCard(publication: publication, publicationId: publicationId, onDelete: _deletePublication);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NewPublicationPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deletePublication(String publicationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Publicación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta publicación?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.child('publications').child(publicationId).remove();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la publicación: ${e.toString()}')),
        );
      }
    }
  }
}

class _PublicationCard extends StatelessWidget {
  final Map<String, dynamic> publication;
  final String publicationId;
  final Function(String) onDelete;

  const _PublicationCard({
    Key? key,
    required this.publication,
    required this.publicationId,
    required this.onDelete,
  }) : super(key: key);

  static String _extractTextFromContent(dynamic content) {
    if (content == null) {
      return 'Sin contenido';
    }
    if (content is String) {
      return content;
    }
    if (content is List) {
      // Assuming content is a list of maps like [{insert: "text"}]
      return content.map((item) {
        if (item is Map && item.containsKey('insert')) {
          return item['insert'] as String;
        }
        return '';
      }).join(''); // Join all extracted text
    }
    return 'Formato de contenido desconocido';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PublicationDetailPage(publication: publication),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(4.0), // Reduced margin
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display images if available
              if (publication['attachments'] != null && publication['attachments'] is List && (publication['attachments'] as List).isNotEmpty)
                Builder(
                  builder: (context) {
                    final attachments = publication['attachments'] as List;
                    if (attachments.length == 1) {
                      final imageUrl = attachments.first;
                      return GestureDetector(
                        onTap: () {
                          print('DEBUG: Single image tapped! URL: $imageUrl');
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ImageViewerScreen(imageUrl: imageUrl),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4.0), // Reduced padding
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 120, // Reduced height
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 120, // Reduced height
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 120, // Reduced height
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.error, color: Colors.red),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Image carousel for multiple images
                      return SizedBox(
                        height: 120, // Reduced height
                        child: PageView.builder(
                          itemCount: attachments.length,
                          itemBuilder: (context, index) {
                            final imageUrl = attachments[index];
                            return GestureDetector(
                              onTap: () {
                                print('DEBUG: Carousel image tapped! URL: $imageUrl');
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ImageViewerScreen(imageUrl: imageUrl),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 4.0), // Reduced padding
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 120, // Reduced height
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 120, // Reduced height
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 120, // Reduced height
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.error, color: Colors.red),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  },
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4), // Reduced spacing
                      Text(
                        (publication['title'] is List)
                            ? (publication['title'] as List).map((e) => e.toString()).join(' ')
                            : publication['title'] ?? 'Sin título',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Slightly smaller font
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4), // Reduced spacing
                      Text(
                        _PublicationCard._extractTextFromContent(publication['content']),
                        maxLines: 2, // Reduced max lines
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12), // Slightly smaller font
                      ),
                      const SizedBox(height: 4), // Reduced spacing
                      // Display publication date
                      if (publication['createdAt'] != null)
                        Text(
                          'Publicado: ${DateFormat('dd/MM/yy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(publication['createdAt']))}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey), // Smaller font
                        ),
                      if (publication['updatedAt'] != null && publication['updatedAt'] != publication['createdAt'])
                        Text(
                          'Modificado: ${DateFormat('dd/MM/yy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(publication['updatedAt']))}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey), // Smaller font
                        ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20), // Smaller icon
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditPublicationPage(
                              publication: publication,
                              publicationId: publicationId,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20), // Smaller icon
                      onPressed: () => onDelete(publicationId),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
