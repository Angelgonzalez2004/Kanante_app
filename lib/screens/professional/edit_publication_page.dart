import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';

class EditPublicationPage extends StatefulWidget {
  final Map<String, dynamic> publication;
  final String publicationId;

  const EditPublicationPage({super.key, required this.publication, required this.publicationId});

  @override
  State<EditPublicationPage> createState() => _EditPublicationPageState();
}

class _EditPublicationPageState extends State<EditPublicationPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late TextEditingController _titleController;
  late QuillController _contentController;
  List<String> _existingImageUrls = [];
  final List<XFile> _newPickedXFiles = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.publication['title']);
    
    _contentController = QuillController.basic();
    final content = widget.publication['content'];
    if (content != null) {
      try {
        _contentController.document = Document.fromJson(content);
      } catch (e) {
        _contentController.document = Document()..insert(0, _extractTextFromContent(content));
      }
    }

    if (widget.publication['attachments'] != null && widget.publication['attachments'] is List) {
      _existingImageUrls = List<String>.from(widget.publication['attachments']);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _extractTextFromContent(dynamic content) {
    if (content == null) {
      return '';
    }
    if (content is String) {
      return content;
    }
    if (content is List) {
      return content.map((item) {
        if (item is Map && item.containsKey('insert')) {
          return item['insert'] as String;
        }
        return '';
      }).join('');
    }
    return '';
  }

  void _showSnackBar(String message, {Color color = Colors.teal}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _newPickedXFiles.addAll(picked);
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newPickedXFiles.removeAt(index);
    });
  }

  Future<String?> _uploadImage(XFile imageFile, String uid) async {
    try {
      Uint8List fileBytes = await imageFile.readAsBytes();
      String fileExtension = imageFile.name.split('.').last;
      String fileName = 'publication_attachments/${uid}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      Reference storageRef = _storage.ref().child(fileName);

      UploadTask uploadTask = storageRef.putData(fileBytes);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Error uploading image to Firebase Storage: ${e.message}');
      _showSnackBar('Error al subir imagen: ${e.message ?? "Error desconocido"}', color: Colors.orange);
      return null;
    } catch (e) {
      debugPrint('Error processing image: $e');
      _showSnackBar('Error al procesar la imagen: $e', color: Colors.orange);
      return null;
    }
  }

  Future<void> _updatePublication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_contentController.document.isEmpty()) {
      _showSnackBar('El contenido no puede estar vacío', color: Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showSnackBar('Debes iniciar sesión para editar una publicación.', color: Colors.red);
        setState(() => isLoading = false);
        return;
      }

      List<String> updatedImageUrls = List.from(_existingImageUrls);

      for (XFile newImage in _newPickedXFiles) {
        String? downloadUrl = await _uploadImage(newImage, user.uid);
        if (downloadUrl != null) {
          updatedImageUrls.add(downloadUrl);
        }
      }

      final updatedData = {
        'title': _titleController.text.trim(),
        'content': _contentController.document.toDelta().toJson(),
        'attachments': updatedImageUrls,
        'professionalUid': user.uid,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await _db.child('publications').child(widget.publicationId).update(updatedData);

      _showSnackBar('Publicación actualizada exitosamente 🎉', color: Colors.green);
      if (mounted) Navigator.of(context).pop(); // Go back to publications list
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Error de autenticación: ${e.message}', color: Colors.red);
    } catch (e) {
      _showSnackBar('Error inesperado: $e', color: Colors.red);
      debugPrint('DEBUG - Error general al actualizar publicación: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // Get screen size for responsiveness

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Publicación'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Center( // Added Center
            child: ConstrainedBox( // Added ConstrainedBox
              constraints: const BoxConstraints(maxWidth: 800.0), // Set max width
              child: SingleChildScrollView(
                padding: EdgeInsets.all(size.width * 0.04), // Responsive padding
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.isEmpty ? 'El título no puede estar vacío' : null,
                      ),
                      SizedBox(height: size.height * 0.02), // Responsive spacing
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
                              height: size.height * 0.4,
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
                      SizedBox(height: size.height * 0.02), // Responsive spacing

                      // Existing Images
                      if (_existingImageUrls.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Imágenes existentes:', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: size.height * 0.01), // Responsive spacing
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: _existingImageUrls.asMap().entries.map((entry) {
                                int idx = entry.key;
                                String imageUrl = entry.value;
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(imageUrl, width: 100, height: 100, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _removeExistingImage(idx),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.remove_circle, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                            SizedBox(height: size.height * 0.02), // Responsive spacing
                          ],
                        ),

                      // New Images
                      if (_newPickedXFiles.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nuevas imágenes a subir:', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: size.height * 0.01), // Responsive spacing
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: _newPickedXFiles.asMap().entries.map((entry) {
                                int idx = entry.key;
                                XFile imageFile = entry.value;
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: FutureBuilder<Uint8List>(
                                        future: imageFile.readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                            return Image.memory(
                                              snapshot.data!,
                                              width: 100, height: 100, fit: BoxFit.cover,
                                            );
                                          }
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[200],
                                            child: const Center(child: CircularProgressIndicator()),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _removeNewImage(idx),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.remove_circle, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                            SizedBox(height: size.height * 0.02), // Responsive spacing
                          ],
                        ),

                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Seleccionar imágenes'),
                      ),
                      SizedBox(height: size.height * 0.02), // Responsive spacing

                      ElevatedButton(
                        onPressed: isLoading ? null : _updatePublication,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Guardar Cambios'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              ),
            ),
        ],
      ),
    );
  }
}