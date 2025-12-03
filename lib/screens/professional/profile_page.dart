// lib/screens/professional/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/user_model.dart';


class ProfessionalProfilePage extends StatefulWidget {
  final String? professionalUid;
  const ProfessionalProfilePage({super.key, this.professionalUid});

  @override
  State<ProfessionalProfilePage> createState() =>
      _ProfessionalProfilePageState();
}

class _ProfessionalProfilePageState extends State<ProfessionalProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  
  List<PlatformFile> _pickedDocuments = [];

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rfcController = TextEditingController();
  final _birthController = TextEditingController();
  late QuillController _biographyQuillController;
  final _institutionNameController = TextEditingController();

  static const List<String> _predefinedSpecialties = [
    'Psicología Clínica', 'Psicoterapia', 'Neuropsicología', 'Psiquiatría', 'Terapia Familiar',
  ];
  static const List<String> _currencies = ['MXN', 'USD', 'EUR', 'Otro'];

  void _showAppSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  void initState() {
    super.initState();
    _biographyQuillController = QuillController.basic();
    _loadProfile();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _rfcController.dispose();
    _birthController.dispose();
    _biographyQuillController.dispose();
    _institutionNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final targetUid = widget.professionalUid ?? _auth.currentUser?.uid;

    if (targetUid == null) {
      setState(() => _isLoading = false);
      return;
    }

    _isEditing = (widget.professionalUid == null || widget.professionalUid == _auth.currentUser?.uid);

    try {
      final snapshot = await _db.child('users/$targetUid').get();
      if (snapshot.exists) {
        final userModel = UserModel.fromMap(targetUid, Map<String, dynamic>.from(snapshot.value as Map));
        setState(() {
          _user = userModel;
          _nameController.text = _user!.name;
          _phoneController.text = _user!.phone ?? '';
          _rfcController.text = _user!.rfc ?? '';
          _birthController.text = _user!.birthDate ?? '';
          _institutionNameController.text = ''; // Placeholder, adjust as needed

          final biographyContent = _user!.bio;
          if (biographyContent != null && biographyContent.isNotEmpty) {
            try {
              _biographyQuillController.document = Document.fromJson(jsonDecode(biographyContent));
            } catch (e) {
              _biographyQuillController.document = Document()..insert(0, biographyContent);
            }
          } else {
            _biographyQuillController.document = Document();
          }
        });
      }
    } catch (e) {
      _showAppSnackBar('Error al cargar el perfil: ${e.toString()}', isError: true);
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDocuments() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _pickedDocuments = result.files;
      });
      _showAppSnackBar('${result.files.length} documento(s) seleccionado(s). Guárdalos para subirlos.');
    }
  }
  
  Future<void> _saveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      // --- Upload documents if any were picked ---
      List<String> documentUrls = List<String>.from(_user?.verificationDocuments ?? []);
      if (_pickedDocuments.isNotEmpty) {
        for (var doc in _pickedDocuments) {
          final ref = _storage.ref().child('verification_documents/$uid/${doc.name}');
          TaskSnapshot uploadTask;
          if (kIsWeb) {
            uploadTask = await ref.putData(doc.bytes!);
          } else {
            uploadTask = await ref.putFile(File(doc.path!));
          }
          final url = await uploadTask.ref.getDownloadURL();
          documentUrls.add(url);
        }
      }

      await _db.child('users/$uid').update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'rfc': _rfcController.text.trim(),
        'birthDate': _birthController.text.trim(),
        'bio': jsonEncode(_biographyQuillController.document.toDelta().toJson()),
        // If new documents were uploaded, set status to pending
        if (_pickedDocuments.isNotEmpty) 'verificationStatus': 'pending',
        if (_pickedDocuments.isNotEmpty) 'verificationDocuments': documentUrls,
      });
      
      setState(() {
        _isEditing = false;
        _pickedDocuments = [];
      });
      _loadProfile(); // Reload data from Firebase
      _showAppSnackBar('Perfil actualizado con éxito.');

    } catch (e) {
      _showAppSnackBar('Error al guardar el perfil: ${e.toString()}', isError: true);
    } finally {
       if(mounted) setState(() => _isLoading = false);
    }
  }

  // --- BUILD METHODS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Editar Perfil" : "Mi Perfil Profesional"),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.check), onPressed: _saveProfile),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => setState(() => _isEditing = true)),
        ],
      ),
      body: _isLoading || _user == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        children: [
                          _buildEditableForm(),
                          const SizedBox(height: 20),
                          if (!_isEditing) _buildVerificationCard(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEditableForm() {
    return Column(
      children: [
        // Other form fields...
        _buildTextField(_nameController, 'Nombre completo', Icons.person_outline),
        const SizedBox(height: 20),
        // Verification Card is now part of the form when editing
        _buildVerificationCard(),
        // More form fields...
      ],
    );
  }
  
  Widget _buildVerificationCard() {
    final status = _user?.verificationStatus ?? 'unverified';
    final notes = _user?.verificationNotes;
    final documents = _user?.verificationDocuments ?? [];

    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (status) {
      case 'verified':
        statusIcon = Icons.verified;
        statusColor = Colors.green;
        statusText = 'Cuenta Verificada';
        break;
      case 'pending':
        statusIcon = Icons.hourglass_top;
        statusColor = Colors.orange;
        statusText = 'Verificación Pendiente';
        break;
      case 'rejected':
        statusIcon = Icons.error;
        statusColor = Colors.red;
        statusText = 'Verificación Rechazada';
        break;
      default:
        statusIcon = Icons.shield_outlined;
        statusColor = Colors.grey;
        statusText = 'No Verificado';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verificación de Cuenta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(statusIcon, color: statusColor),
              title: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            ),
            if (status == 'rejected' && notes != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text('Motivo: $notes', style: const TextStyle(color: Colors.red)),
              ),
            if (documents.isNotEmpty) ...[
              const Divider(),
              const Text('Documentos Subidos:'),
              ...documents.map((doc) => ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(Uri.decodeFull(doc.split('/').last.split('?').first)),
                  )),
            ],
             if (_pickedDocuments.isNotEmpty) ...[
              const Divider(),
              const Text('Nuevos documentos para subir:'),
              ..._pickedDocuments.map((doc) => ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(doc.name),
                  )),
            ],
            const SizedBox(height: 16),
            if (status != 'verified')
              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickDocuments,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Subir Documentos'),
                ),
              ),
            if (_isEditing && _pickedDocuments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: TextButton(
                    onPressed: _saveProfile,
                    child: const Text('Guardar y enviar para verificación'),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withAlpha(150),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}
// Dummy widgets to avoid breaking the file, will be replaced by actual implementations
class QuillEditorConfigurations {
  final QuillController controller;
  final bool readOnly;
  final QuillSharedConfigurations sharedConfigurations;
  QuillEditorConfigurations({required this.controller, this.readOnly = false, required this.sharedConfigurations});
}

class QuillSharedConfigurations {
  final Locale locale;
  const QuillSharedConfigurations({required this.locale});
}

class QuillEditor extends StatelessWidget {
  final QuillEditorConfigurations configurations;
  const QuillEditor.basic({super.key, required this.configurations});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class Document {
  Document();
  void insert(int index, String text) {}
  factory Document.fromJson(dynamic json) => Document();
  dynamic toDelta() => {};
  bool isEmpty() => true;
}

class QuillController extends ChangeNotifier {
  Document document = Document();
  QuillController.basic();
}