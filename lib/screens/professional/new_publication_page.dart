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
  final QuillController _contentController = QuillController.basic();
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  bool _isLoading = false;
  final _picker = ImagePicker();
  final List<XFile> _attachments = [];
  final TextEditingController _imageUrlController = TextEditingController(); // New
  bool _useImageUrl = false; // New

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
    _imageUrlController.dispose(); // Dispose the new controller
    super.dispose();
  }

  Future<void> _loadPublicationData() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _db.child('publications').child(widget.publicationId!).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _titleController.text = data['title'];
        _contentController.document = Document.fromJson(data['content']);
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
                      _useImageUrl = false; // Ensure we're not using URL if local picked
                      _imageUrlController.clear();
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
                      _useImageUrl = false;
                      _imageUrlController.clear();
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
                    _attachments.clear(); // Clear local attachments if URL is used
                    _useImageUrl = true;
                    // Add the URL as a string to attachments for consistent handling later
                    _attachments.add(XFile(url)); // Store URL as XFile.path
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
      children: _attachments.map((file) {
        return LayoutBuilder(
          builder: (context, constraints) {
            Widget imageWidget;
            if (_useImageUrl && file.path == _imageUrlController.text.trim()) {
              imageWidget = Image.network(
                file.path,
                width: constraints.maxWidth * 0.2,
                height: constraints.maxWidth * 0.2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: constraints.maxWidth * 0.2,
                  height: constraints.maxWidth * 0.2,
                  color: Colors.grey,
                  child: const Icon(Icons.broken_image, color: Colors.white),
                ),
              );
            } else {
              imageWidget = Image.file(
                File(file.path),
                width: constraints.maxWidth * 0.2,
                height: constraints.maxWidth * 0.2,
                fit: BoxFit.cover,
              );
            }

            return Stack(
              children: [
                imageWidget,
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _attachments.remove(file);
                        _useImageUrl = false; // Reset if the URL image is removed
                        _imageUrlController.clear();
                      });
                    },
                  ),
                ),
              ],
            );
          },
        );
      }).toList(),
    );
  }

  Future<List<String>> _uploadAttachments() async {
    final List<String> attachmentUrls = [];

    if (_useImageUrl && _imageUrlController.text.trim().isNotEmpty) {
      attachmentUrls.add(_imageUrlController.text.trim());
    } else {
      for (final file in _attachments) {
        // Skip if it's the URL placeholder from XFile
        if (file.path == _imageUrlController.text.trim() && _useImageUrl) continue;

        final fileName = file.name;
        final ref = _storage.ref().child('publication_attachments/$fileName');
        final uploadTask = await ref.putFile(File(file.path));
        final url = await uploadTask.ref.getDownloadURL();
        attachmentUrls.add(url);
      }
    }
    return attachmentUrls;
  }

  Future<void> _publish() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_titleController.text.isEmpty || _contentController.document.isEmpty()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un título y contenido.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final attachmentUrls = await _uploadAttachments();

      final publicationData = {
        'professionalUid': user.uid,
        'title': _titleController.text.trim(),
        'content': _contentController.document.toDelta().toJson(),
        'createdAt': ServerValue.timestamp,
        'attachments': attachmentUrls,
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
                      Text('Contenido de la publicación', style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: size.height * 0.01), // Responsive spacing
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            QuillToolbar.simple(
                              configurations: QuillSimpleToolbarConfigurations(
                                controller: _contentController,
                                sharedConfigurations: const QuillSharedConfigurations(
                                  locale: Locale('es'),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            SizedBox(
                              height: size.height * 0.4, // Responsive height
                              child: QuillEditor.basic(
                                configurations: QuillEditorConfigurations(
                                  controller: _contentController,
                                  padding: const EdgeInsets.all(16),
                                  sharedConfigurations: const QuillSharedConfigurations(
                                    locale: Locale('es'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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