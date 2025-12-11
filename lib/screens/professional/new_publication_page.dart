import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class NewPublicationPage extends StatefulWidget {
  final String? publicationId;

  const NewPublicationPage({super.key, this.publicationId});

  @override
  State<NewPublicationPage> createState() => _NewPublicationPageState();
}

class _NewPublicationPageState extends State<NewPublicationPage> {
  final _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController(); // Changed to TextEditingController
  final TextEditingController _hashtagsController = TextEditingController(); // New controller for hashtags
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  bool _isLoading = false;
  final _picker = ImagePicker();
  final List<dynamic> _attachments = []; // Changed to dynamic to hold XFile or String (for URLs)
  final TextEditingController _imageUrlController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    if (widget.publicationId != null) {
      _loadPublicationData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _hashtagsController.dispose(); // Dispose new controller
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadPublicationData() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _db.child('publications').child(widget.publicationId!).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _titleController.text = data['title'];
        _contentController.text = data['content'] as String? ?? ''; // Load as plain text
        if (data['hashtags'] != null) {
          _hashtagsController.text = (data['hashtags'] as List<dynamic>).join(', '); // Load hashtags
        }
        if (data['attachments'] != null) {
          setState(() {
            _attachments.addAll(List<String>.from(data['attachments']));
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la publicación: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de Galería'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _attachments.add(pickedFile);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar Foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _attachments.add(pickedFile);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Pegar URL de Imagen'),
                onTap: () {
                  Navigator.pop(context);
                  _showImageUrlInputDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showImageUrlInputDialog() async {
    _imageUrlController.clear(); // Clear previous input

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pegar URL de Imagen'),
          content: TextField(
            controller: _imageUrlController,
            decoration: const InputDecoration(
              labelText: 'URL de la imagen',
              hintText: 'https://ejemplo.com/imagen.jpg',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Añadir'),
              onPressed: () {
                final url = _imageUrlController.text.trim();
                if (Uri.tryParse(url)?.hasAbsolutePath ?? false) {
                  // Basic URL validation
                  setState(() {
                    _attachments.add(url); // Add the URL string directly
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL inválida.'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttachmentsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _attachments.map((attachment) {
        Widget imageWidget;
        bool isNetworkImage = attachment is String; // Check if it's a URL string

        if (isNetworkImage) {
          imageWidget = Image.network(
            attachment,
            width: 100, // Fixed size for consistency
            height: 100, // Fixed size for consistency
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 100,
              height: 100,
              color: Colors.grey,
              child: const Icon(Icons.broken_image, color: Colors.white),
            ),
          );
        } else {
          // Assume it's an XFile for local image
          imageWidget = Image.file(
            File((attachment as XFile).path),
            width: 100, // Fixed size for consistency
            height: 100, // Fixed size for consistency
            fit: BoxFit.cover,
          );
        }

        return Stack(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageWidget,
              ),
            ),
            Positioned(
              top: -10,
              right: -10,
              child: IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red, size: 24),
                onPressed: () {
                  setState(() {
                    _attachments.remove(attachment);
                  });
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Future<List<String>> _uploadAttachments() async {
    final List<String> attachmentUrls = [];
    for (final attachment in _attachments) {
      if (attachment is String) { // It's a URL string
        attachmentUrls.add(attachment);
      } else if (attachment is XFile) { // It's a local file
        final fileName = attachment.name;
        final ref = _storage.ref().child('publication_attachments/$fileName');
        final uploadTask = await ref.putFile(File(attachment.path));
        final url = await uploadTask.ref.getDownloadURL();
        attachmentUrls.add(url);
      }
    }
    return attachmentUrls;
  }

  Future<void> _publish() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_titleController.text.isEmpty || _contentController.text.isEmpty) { // Check plain text content
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un título y contenido.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final attachmentUrls = await _uploadAttachments();
      // Parse hashtags
      final List<String> hashtags = _hashtagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final publicationData = {
        'professionalUid': user.uid,
        'title': _titleController.text.trim(),
        'content': _contentController.text, // Save as plain text
        'createdAt': ServerValue.timestamp,
        'attachments': attachmentUrls,
        'hashtags': hashtags, // Save hashtags
      };

      if (widget.publicationId == null) {
        final newPublicationRef = _db.child('publications').push();
        await newPublicationRef.set(publicationData);
      } else {
        await _db.child('publications').child(widget.publicationId!).update(publicationData);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // Get screen size for responsiveness

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.publicationId == null ? 'Nueva Publicación' : 'Editar Publicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.publish_rounded),
            onPressed: _isLoading ? null : _publish,
            tooltip: 'Publicar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center( // Added Center
              child: ConstrainedBox( // Added ConstrainedBox
                constraints: const BoxConstraints(maxWidth: 800.0), // Set max width
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(size.width * 0.04), // Responsive padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: const InputDecoration(
                          labelText: 'Título de la publicación',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: size.height * 0.03), // Responsive spacing
                      _buildAttachmentsSection(),
                      SizedBox(height: size.height * 0.03), // Responsive spacing
                      // Content input
                      TextFormField(
                        controller: _contentController,
                        maxLines: null, // Allows multiline input
                        minLines: 5,   // Starts with 5 lines
                        decoration: const InputDecoration(
                          labelText: 'Contenido de la publicación',
                          hintText: 'Escribe aquí tu publicación...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        keyboardType: TextInputType.multiline,
                      ),
                      SizedBox(height: size.height * 0.03), // Responsive spacing
                      // Hashtags input
                      TextFormField(
                        controller: _hashtagsController,
                        decoration: const InputDecoration(
                          labelText: 'Hashtags',
                          hintText: 'Ej: #salud, #bienestar, #nutricion',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAttachmentsSection() {
    final size = MediaQuery.of(context).size; // Get size for responsiveness
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Archivos adjuntos', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: size.height * 0.01), // Responsive spacing
        _attachments.isEmpty
            ? const Text('No se han añadido archivos.')
            : _buildAttachmentsList(),
        SizedBox(height: size.height * 0.02), // Responsive spacing
        OutlinedButton.icon(
          onPressed: _pickAttachment,
          icon: const Icon(Icons.attach_file_rounded),
          label: const Text('Añadir Imagen'),
        ),
      ],
    );
  }
}