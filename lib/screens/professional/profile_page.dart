import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  XFile? _pickedProfileImage; // Variable para la nueva imagen de perfil

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rfcController = TextEditingController();
  final _birthController = TextEditingController();
  late QuillController _biographyQuillController;
  final _institutionNameController = TextEditingController();

  // ignore: unused_field
  static const List<String> _predefinedSpecialties = [
    'Psicología Clínica', 'Psicoterapia', 'Neuropsicología', 'Psiquiatría', 'Terapia Familiar',
  ];
  // ignore: unused_field
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
          _institutionNameController.text = ''; // Placeholder

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

  // Función para seleccionar imagen de perfil
  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedProfileImage = pickedFile;
        });
      }
    } catch (e) {
      _showAppSnackBar('Error al seleccionar imagen: $e', isError: true);
    }
  }
  
  Future<void> _saveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      // 1. Upload Documents
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

      // 2. Upload Profile Image (if changed)
      String? profileImageUrl = _user?.profileImageUrl;
      if (_pickedProfileImage != null) {
        final ref = _storage.ref().child('profile_images/$uid.jpg');
        TaskSnapshot uploadTask;
        if (kIsWeb) {
          final bytes = await _pickedProfileImage!.readAsBytes();
          uploadTask = await ref.putData(bytes);
        } else {
          uploadTask = await ref.putFile(File(_pickedProfileImage!.path));
        }
        profileImageUrl = await uploadTask.ref.getDownloadURL();
      }

      // 3. Update Database
      await _db.child('users/$uid').update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'rfc': _rfcController.text.trim(),
        'birthDate': _birthController.text.trim(),
        'bio': jsonEncode(_biographyQuillController.document.toDelta().toJson()),
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (_pickedDocuments.isNotEmpty) 'verificationStatus': 'pending',
        if (_pickedDocuments.isNotEmpty) 'verificationDocuments': documentUrls,
      });
      
      setState(() {
        _isEditing = false;
        _pickedDocuments = [];
        _pickedProfileImage = null;
      });
      _loadProfile(); 
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
        // --- Avatar / Foto de Perfil ---
        GestureDetector(
          onTap: _isEditing ? _pickProfileImage : null,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: _pickedProfileImage != null
                    ? (kIsWeb
                        ? NetworkImage(_pickedProfileImage!.path)
                        : FileImage(File(_pickedProfileImage!.path)) as ImageProvider)
                    : (_user?.profileImageUrl != null
                        ? CachedNetworkImageProvider(_user!.profileImageUrl!)
                        : null),
                child: (_pickedProfileImage == null && _user?.profileImageUrl == null)
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- Campos de Texto ---
        _buildTextField(_nameController, 'Nombre completo', Icons.person_outline, enabled: _isEditing),
        const SizedBox(height: 16),
        _buildTextField(_phoneController, 'Teléfono', Icons.phone_outlined, keyboardType: TextInputType.phone, enabled: _isEditing),
        const SizedBox(height: 16),
        _buildTextField(_rfcController, 'RFC / Cédula', Icons.badge_outlined, enabled: _isEditing),
        const SizedBox(height: 16),
        _buildTextField(_birthController, 'Fecha de Nacimiento (DD/MM/AAAA)', Icons.calendar_today_outlined, enabled: _isEditing),
        const SizedBox(height: 24),

        // --- Editor de Biografía ---
        Align(
          alignment: Alignment.centerLeft,
          child: Text("Biografía / Sobre mí", style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
               if (_isEditing)
                QuillToolbar.simple(
                  configurations: QuillSimpleToolbarConfigurations(
                    controller: _biographyQuillController,
                    sharedConfigurations: const QuillSharedConfigurations(
                      locale: Locale('es'),
                    ),
                  ),
                ),
               if (_isEditing) const Divider(),
               SizedBox(
                 height: 200,
                 child: Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: QuillEditor.basic(
                     configurations: QuillEditorConfigurations(
                       controller: _biographyQuillController,
                       sharedConfigurations: const QuillSharedConfigurations(
                         locale: Locale('es'),
                       ),
                       // En modo lectura bloqueamos el foco
                       // Si _isEditing es false, no permitimos editar
                     ),
                     focusNode: FocusNode(canRequestFocus: _isEditing),
                   ),
                 ),
               ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        // Verification Card is now part of the form when editing to upload docs
        if (_isEditing) _buildVerificationCard(),
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
            // Solo mostramos el botón de subir si está editando Y no está verificada (o fue rechazada)
            if (status != 'verified' && _isEditing)
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
                  child: Text(
                    'Se enviarán ${_pickedDocuments.length} documentos al guardar.',
                    style: TextStyle(color: Colors.orange[800], fontStyle: FontStyle.italic),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        // CORRECCIÓN: withAlpha espera entero, withValues es mejor en versiones nuevas, pero withAlpha funciona bien aquí.
        // Si tienes Flutter 3.27+ estricto, usa: Colors.grey.withValues(alpha: 0.1)
        fillColor: enabled ? Theme.of(context).colorScheme.surface : Colors.grey.withAlpha(50), 
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}