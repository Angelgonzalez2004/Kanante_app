import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kanante_app/models/user_model.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/publication_model.dart';
import '../../services/firebase_service.dart';
import '../user/professional_profile_page.dart';
import 'comments_screen.dart';

class PublicationFeedBody extends StatefulWidget {
  final Color textColor;
  const PublicationFeedBody({super.key, this.textColor = Colors.white});

  @override
  State<PublicationFeedBody> createState() => _PublicationFeedBodyState();
}

class _PublicationFeedBodyState extends State<PublicationFeedBody> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userModel = await _firebaseService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _currentUser = userModel;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Publication>>(
      stream: _firebaseService.getPublicationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
           return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: widget.textColor)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('No hay publicaciones disponibles.', style: TextStyle(color: widget.textColor)),
          );
        }

        final publications = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800.0),
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
    final bool isLiked = _currentUser != null && publication.likedBy.contains(_currentUser!.id);
    final bool canInteract = _currentUser?.accountType == 'Usuario';

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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0) + const EdgeInsets.only(bottom: 60.0, right: 60.0),
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
          Positioned(
            bottom: 80,
            right: 10,
            child: Column(
              children: [
                 if (canInteract) ...[
                  _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '${publication.likes}',
                    color: isLiked ? Colors.red : widget.textColor,
                    onTap: () {
                      _firebaseService.toggleLikePublication(publication.id, _currentUser!.id);
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.comment,
                    label: '${publication.comments.length}',
                    color: widget.textColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommentsScreen(publication: publication),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                 ],
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  color: widget.textColor,
                  onTap: () {
                    Share.share('Mira esta publicación de ${publication.authorName ?? "un profesional"} en Kananté: ${publication.title}');
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

    Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 35),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
