import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kanante_app/screens/professional/professional_profile_page.dart';
import 'package:kanante_app/screens/professional/image_viewer_page.dart'; // Import ImageViewerPage
import 'package:kanante_app/screens/search/search_page.dart'; // Import SearchPage
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:share_plus/share_plus.dart'; // Import share_plus

class PublicationDetailPage extends StatefulWidget {
  final Map<String, dynamic> publication;

  const PublicationDetailPage({super.key, required this.publication});

  @override
  PublicationDetailPageState createState() => PublicationDetailPageState();
}

class PublicationDetailPageState extends State<PublicationDetailPage> {
  Map<String, dynamic>? _authorData;
  bool _isBookmarked = false; // New state variable for bookmark

  @override
  void initState() {
    super.initState();
    _fetchAuthorData();
    _checkBookmarkStatus(); // Check bookmark status on init
  }

  Future<void> _fetchAuthorData() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/${widget.publication['professionalUid']}')
          .get();
      if (snapshot.exists) {
        setState(() {
          _authorData = Map<String, dynamic>.from(snapshot.value as Map);
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  // New method to check bookmark status
  Future<void> _checkBookmarkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedPublications = prefs.getStringList('bookmarkedPublications') ?? [];
    setState(() {
      _isBookmarked = bookmarkedPublications.contains(widget.publication['id']);
    });
  }

  // New method to toggle bookmark status
  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookmarkedPublications = prefs.getStringList('bookmarkedPublications') ?? [];
    final publicationId = widget.publication['id'];

    if (_isBookmarked) {
      bookmarkedPublications.remove(publicationId);
    } else {
      bookmarkedPublications.add(publicationId);
    }

    await prefs.setStringList('bookmarkedPublications', bookmarkedPublications);
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
  }

  Document _safelyLoadDocument(dynamic content) {
    if (content == null) {
      return Document();
    }
    try {
      return Document.fromJson(content);
    } catch (e) {
      String text = '';
      if (content is String) {
        text = content;
      } else if (content is List) {
        text = content.map((item) {
          if (item is Map && item.containsKey('insert')) {
            final insertData = item['insert'];
            if (insertData is String) {
              return insertData;
            }
          }
          return '';
        }).join('');
      } else {
        text = content.toString();
      }

      if (!text.endsWith('\n')) {
        text += '\n';
      }
      
      final document = Document();
      document.insert(0, text);
      return document;
    }
  }

  String _getFormattedDate() {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(widget.publication['createdAt']);
    final updatedAt = widget.publication['updatedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(widget.publication['updatedAt'])
        : null;

    if (updatedAt != null && updatedAt != createdAt) {
      return 'Última modificación: ${updatedAt.toLocal().toString().split(' ')[0]}'; // Format as YYYY-MM-DD
    } else {
      return 'Publicado: ${createdAt.toLocal().toString().split(' ')[0]}'; // Format as YYYY-MM-DD
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.publication['title'] ?? 'Sin título';
    final content = widget.publication['content'];
    final attachments = widget.publication['attachments'] as List?;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.25,
            floating: false,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                onPressed: _toggleBookmark,
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  final String title = widget.publication['title'] ?? 'Publicación de Salud Mental';
                  final String contentSnippet = (widget.publication['content'] is List)
                      ? (widget.publication['content'] as List)
                          .map((item) => item is Map && item.containsKey('insert') ? item['insert'] : '')
                          .join('')
                          .substring(0, (widget.publication['content'] as List).length > 50 ? 50 : (widget.publication['content'] as List).length) // Take a snippet
                      : widget.publication['content'].toString().substring(0, widget.publication['content'].toString().length > 50 ? 50 : widget.publication['content'].toString().length);
                  Share.share('$title\n\n$contentSnippet...');
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(title, style: const TextStyle(color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  (attachments != null && attachments.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: attachments.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[300]),
                          errorWidget: (context, url, error) => Container(color: Colors.grey, child: Icon(Icons.error)),
                        )
                      : Container(color: Colors.grey),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: <Color>[
                          Colors.black87,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_authorData != null)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfessionalProfilePage(
                                professionalUid: widget.publication['professionalUid'],
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: _authorData!['profileImageUrl'] != null
                                    ? CachedNetworkImageProvider(_authorData!['profileImageUrl'])
                                    : null,
                                child: _authorData!['profileImageUrl'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                              Expanded(
                                child: Text(
                                  _authorData!['name'] ?? 'Autor desconocido',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16.0, color: Colors.grey),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                      Text(
                        _getFormattedDate(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                ],
              ),
            ),
          ),
          if (content != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: QuillEditor.basic(
                  configurations: QuillEditorConfigurations(
                    controller: QuillController(
                      document: _safelyLoadDocument(content),
                      selection: const TextSelection.collapsed(offset: 0),
                    ),
                    readOnly: true,
                  ),
                ),
              ),
            ),
          if (attachments != null && attachments.length > 1)
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: attachments.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    clipBehavior: Clip.antiAlias, // Ensures the image respects the card's rounded corners
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewerPage(
                              imageUrl: attachments[index],
                            ),
                          ),
                        );
                      },
                      child: CachedNetworkImage(
                        imageUrl: attachments[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[300]),
                        errorWidget: (context, url, error) => Container(color: Colors.grey, child: Icon(Icons.error)),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchPage()),
          );
        },
        child: const Icon(Icons.search),
      ),
    );
  }
}