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
  _NewPublicationPageState createState() => _NewPublicationPageState();
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

  @override
  void initState() {
    super.initState();
    if (widget.publicationId != null) {
      _loadPublicationData();
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la publicación: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAttachment() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _attachments.add(pickedFile);
      });
    }
  }

  Widget _buildAttachmentsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _attachments.map((file) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Image.file(
                  File(file.path),
                  width: constraints.maxWidth * 0.2,
                  height: constraints.maxWidth * 0.2,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _attachments.remove(file);
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
    for (final file in _attachments) {
      final fileName = file.name;
      final ref = _storage.ref().child('publication_attachments/$fileName');
      final uploadTask = await ref.putFile(File(file.path));
      final url = await uploadTask.ref.getDownloadURL();
      attachmentUrls.add(url);
    }
    return attachmentUrls;
  }

  Future<void> _publish() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_titleController.text.isEmpty || _contentController.document.isEmpty()) {
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

      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                    const SizedBox(height: 24),
                    _buildAttachmentsSection(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    Text('Contenido de la publicación', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
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
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: QuillEditor.basic(
                              configurations: QuillEditorConfigurations(
                                controller: _contentController,
                                readOnly: false,
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
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Archivos adjuntos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _attachments.isEmpty
            ? const Text('No se han añadido archivos.')
            : _buildAttachmentsList(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickAttachment,
          icon: const Icon(Icons.attach_file_rounded),
          label: const Text('Añadir Imagen'),
        ),
      ],
    );
  }
}
