import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuth
import 'package:share_plus/share_plus.dart'; // Import for sharing functionality
import '../../models/publication_model.dart';
import '../../services/firebase_service.dart';

import 'comments_screen.dart'; // Placeholder for comments screen

class UserHomeContent extends StatefulWidget {
  const UserHomeContent({super.key});

  @override
  State<UserHomeContent> createState() => _UserHomeContentState();
}

class _UserHomeContentState extends State<UserHomeContent> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance; // FirebaseAuth instance
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
                          maxLines: 4, // Allow more lines for content
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              icon: publication.likedBy.contains(_auth.currentUser?.uid) ? Icons.favorite : Icons.favorite_border,
                              color: publication.likedBy.contains(_auth.currentUser?.uid) ? Colors.red : Colors.white,
                              label: '${publication.likes}',
                              onTap: () => _toggleLike(publication),
                            ),
                            _buildActionButton(
                              icon: Icons.comment_outlined,
                              color: Colors.white,
                              label: '${publication.comments.length}', // Display comment count
                              onTap: () => _showComments(publication.id),
                            ),
                            _buildActionButton(
                              icon: Icons.share,
                              color: Colors.white,
                              label: 'Compartir',
                              onTap: () => _sharePublication(publication),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
            
              Widget _buildActionButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
                return GestureDetector(
                  onTap: onTap,
                  child: Column(
                    children: [
                      Icon(icon, color: color, size: 24),
                      const SizedBox(height: 4),
                      Text(label, style: TextStyle(color: color, fontSize: 12)),
                    ],
                  ),
                );
              }
            
              Future<void> _toggleLike(Publication publication) async {
                final userId = _auth.currentUser?.uid;
                if (userId == null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debes iniciar sesión para dar "Me gusta".')),
                  );
                  return;
                }
            
                try {
                  await _firebaseService.toggleLikePublication(publication.id, userId);
                  // Re-fetch publications to update UI, or update locally if performance is critical
                  setState(() {
                    _publicationsFuture = _firebaseService.getAllPublications();
                  });
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al dar "Me gusta": $e')),
                  );
                }
              }
            
              void _sharePublication(Publication publication) {
                // Construct a shareable link. This might require a deep link or web URL for the publication.
                // For now, a generic link or direct text share.
                final String shareLink = 'Mira esta publicación en Kananté: https://kanante.app/publication/${publication.id}'; // Placeholder link
                Share.share(shareLink, subject: publication.title);
              }
            
              void _showComments(String publicationId) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CommentsScreen(publicationId: publicationId)),
                );
              }
            }
            