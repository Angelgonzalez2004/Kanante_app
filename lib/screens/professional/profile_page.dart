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
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
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
  DateTime? _selectedBirthDate; // New: To store the DateTime object for birth date

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rfcController = TextEditingController();
  final _birthController = TextEditingController();
  String? _selectedGender; // Replaced _genderController
  final _websiteController = TextEditingController();
  final _educationController = TextEditingController();
  final _certificationsController = TextEditingController();
  late QuillController _biographyQuillController;
  final _institutionNameController = TextEditingController();

  // New controllers for social media
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();

  // ignore: unused_field
  static const List<String> _predefinedSpecialties = [
    'Psicología Clínica', 'Psicoterapia', 'Neuropsicología', 'Psiquiatría', 'Terapia Familiar',
  ];
  // ignore: unused_field
  static const List<String> _currencies = ['MXN', 'USD', 'EUR', 'Otro'];

  void _showAppSnackBar(String message, {bool isError = false, Duration duration = const Duration(seconds: 2)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green, duration: duration),
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
    _websiteController.dispose();
    _educationController.dispose();
    _certificationsController.dispose();
    _biographyQuillController.dispose();
    _institutionNameController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final targetUid = widget.professionalUid ?? _auth.currentUser?.uid;

    if (targetUid == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Determine if the current user is viewing their own profile or another's
    // If professionalUid is null, it's the current user's profile, so they can edit.
    // If professionalUid is provided and it matches current user's uid, they can edit.
    // Otherwise, it's a view-only for another professional.
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
          if (_user!.birthDate != null && _user!.birthDate!.isNotEmpty) {
            try {
              _selectedBirthDate = DateFormat('yyyy-MM-dd').parse(_user!.birthDate!);
              _birthController.text = DateFormat('dd/MM/yyyy').format(_selectedBirthDate!);
            } catch (e) {
              debugPrint("Error parsing birth date: $e");
              _birthController.text = _user!.birthDate!; // Fallback to original string
            }
          } else {
            _birthController.text = '';
          }
          _selectedGender = _user!.gender; // New: Assign directly
          _websiteController.text = _user!.website ?? ''; // New
          _educationController.text = _user!.education?.join(', ') ?? ''; // Placeholder
          _certificationsController.text = _user!.certifications?.join(', ') ?? ''; // Placeholder
          _institutionNameController.text = ''; // Placeholder

          // Load social media links
          _facebookController.text = _user!.socialMediaLinks?['facebook'] ?? '';
          _instagramController.text = _user!.socialMediaLinks?['instagram'] ?? '';
          _tiktokController.text = _user!.socialMediaLinks?['tiktok'] ?? '';
          _whatsappController.text = _user!.socialMediaLinks?['whatsapp'] ?? '';
          _emailController.text = _user!.socialMediaLinks?['email'] ?? '';

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
      _showAppSnackBar('${result.files.length} documento(s) seleccionado(s). Guárdalos para subirlos.', duration: const Duration(seconds: 3));
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
  
  Future<void> _deleteProfileImage() async {
    final user = _auth.currentUser;
    if (user == null || _user?.profileImageUrl == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Foto de Perfil'),
        content: const Text('¿Estás seguro de que quieres eliminar tu foto de perfil?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _storage.refFromURL(_user!.profileImageUrl!).delete();
        await _db.child('users/${user.uid}').update({
          'profileImageUrl': null, // Use null to delete field in Realtime Database
        });
        if (mounted) {
          setState(() {
            // _user!.profileImageUrl = null; // No longer needed, _loadProfile() will refresh
            _showAppSnackBar('Foto de perfil eliminada.', duration: const Duration(seconds: 3));
          });
        }
      } on FirebaseException catch (e) {
        _showAppSnackBar('Error al eliminar la imagen: ${e.message}', isError: true);
      } catch (e) {
        _showAppSnackBar('Error inesperado: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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

      // 2. Upload Profile Image (if changed AND not a Google user)
      String? profileImageUrl = _user?.profileImageUrl;
      if (_pickedProfileImage != null && !_isGoogleUser) { // Only upload if not Google user
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
      final socialLinks = {
        'facebook': _facebookController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'email': _emailController.text.trim(),
      };
      // Remove empty links before saving
      socialLinks.removeWhere((key, value) => value.isEmpty);

      await _db.child('users/$uid').update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'rfc': _rfcController.text.trim(),
        'birthDate': _selectedBirthDate != null ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!) : null, // Use selected date
        'gender': _selectedGender, // Save new field
        'website': _websiteController.text.trim(), // New
        'socialMediaLinks': socialLinks,
        'education': _educationController.text.trim().isNotEmpty // New
            ? _educationController.text.trim().split(',').map((e) => e.trim()).toList() // Convert to list
            : null,
        'certifications': _certificationsController.text.trim().isNotEmpty // New
            ? _certificationsController.text.trim().split(',').map((e) => e.trim()).toList() // Convert to list
            : null,
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
      _showAppSnackBar('Perfil actualizado con éxito.', duration: const Duration(seconds: 3));

    } catch (e) {
      _showAppSnackBar('Error al guardar el perfil: ${e.toString()}', isError: true);
    } finally {
       if(mounted) setState(() => _isLoading = false);
    }
  }

  // Check if the current user is a Google user
  bool get _isGoogleUser => _auth.currentUser?.providerData.any((info) => info.providerId == 'google.com') ?? false;
  // Professional can upload photo, but this is a user page.
  // So, manual user can upload photo.
  bool get _canManagePhoto => _isEditing && !_isGoogleUser;

  // --- BUILD METHODS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Profesional'),
        backgroundColor: Colors.teal,
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
                          const SizedBox(height: 30), // Spacing before action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isEditing)
                                Flexible( // Added Flexible
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.check),
                                    label: const Text('Guardar Cambios'),
                                    onPressed: _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                ),
                              if (_isEditing) const SizedBox(width: 16),
                              Flexible( // Added Flexible
                                child: ElevatedButton.icon(
                                  icon: Icon(_isEditing ? Icons.cancel : Icons.edit_outlined),
                                  label: Text(_isEditing ? 'Cancelar Edición' : 'Editar Perfil'),
                                  onPressed: () => setState(() {
                                    _isEditing = !_isEditing;
                                    if (!_isEditing) { // If canceling edit, reload original profile
                                      _loadProfile();
                                    }
                                  }),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isEditing ? Colors.red : Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
        Center(
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
              if (_canManagePhoto) // Show camera icon only if can manage photo
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      onPressed: _pickProfileImage,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_isGoogleUser && _isEditing) // Message for Google users when editing
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Gestionar foto en cuenta de Google', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  _showAppSnackBar('Por favor, gestiona tu foto de perfil directamente en tu cuenta de Google.', duration: const Duration(seconds: 3));
                },
              ),
            ),
          ),
        if (_canManagePhoto && _user?.profileImageUrl != null && _isEditing) // Delete button for manual users
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Eliminar foto de perfil', style: TextStyle(color: Colors.red)),
              onPressed: _deleteProfileImage,
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
        TextFormField(
          controller: _birthController,
          readOnly: true,
          onTap: _isEditing ? () async { // Only allow tapping if editing
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedBirthDate ?? DateTime(2000),
              firstDate: DateTime(1920),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.teal)), child: child!),
            );
            if (picked != null) {
              setState(() {
                _selectedBirthDate = picked;
                _birthController.text = DateFormat('dd/MM/yyyy').format(picked);
              });
            }
          } : null,
          decoration: InputDecoration(
            labelText: 'Fecha de Nacimiento',
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: _isEditing ? Theme.of(context).colorScheme.surface : Colors.grey.withAlpha(50),
          ),
          enabled: _isEditing, // Control enabled state
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _selectedGender,
          decoration: InputDecoration(
            labelText: 'Género',
            prefixIcon: const Icon(Icons.transgender),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: _isEditing ? Theme.of(context).colorScheme.surface : Colors.grey.withAlpha(50),
          ),
          items: const [
            DropdownMenuItem(value: 'Hombre', child: Text('Hombre')),
            DropdownMenuItem(value: 'Mujer', child: Text('Mujer')),
            DropdownMenuItem(value: 'Prefiero no decirlo', child: Text('Prefiero no decirlo')),
          ],
          onChanged: _isEditing ? (newValue) => setState(() => _selectedGender = newValue) : null,
          validator: (value) => value == null && _isEditing ? 'Seleccione su género' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(_websiteController, 'Sitio Web', Icons.language, enabled: _isEditing),
        const SizedBox(height: 24),
        
        // --- Social Media Section ---
        Align(
          alignment: Alignment.centerLeft,
          child: Text("Redes Sociales", style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        _isEditing ? _buildSocialMediaForm() : _buildSocialMediaLinks(),
        const SizedBox(height: 24),

        _buildTextField(_educationController, 'Educación (separado por comas)', Icons.school, enabled: _isEditing, maxLines: 3),
        const SizedBox(height: 16),
        _buildTextField(_certificationsController, 'Certificaciones (separado por comas)', Icons.verified_user, enabled: _isEditing, maxLines: 3), // New
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
          fillColor: enabled ? Theme.of(context).colorScheme.surface : Colors.grey.withAlpha(50), 
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
      );
    }
  
    Widget _buildSocialMediaForm() {
      return Column(
        children: [
          _buildTextField(_facebookController, 'Enlace de Facebook', Icons.facebook, enabled: true),
          const SizedBox(height: 16),
          _buildTextField(_instagramController, 'Enlace de Instagram', Icons.camera_alt, enabled: true),
          const SizedBox(height: 16),
          _buildTextField(_tiktokController, 'Enlace de TikTok', Icons.music_note, enabled: true),
          const SizedBox(height: 16),
          _buildTextField(_whatsappController, 'Número de WhatsApp', Icons.message, enabled: true, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField(_emailController, 'Correo de Contacto', Icons.email, enabled: true, keyboardType: TextInputType.emailAddress),
        ],
      );
    }
  
    Widget _buildSocialMediaLinks() {
      final links = _user?.socialMediaLinks ?? {};
      if (links.entries.where((e) => e.value.isNotEmpty).isEmpty) {
        return const Text('No hay redes sociales para mostrar.');
      }
  
      Future<void> launchLink(String url, String scheme) async {
          final Uri uri = Uri.parse(scheme.isNotEmpty ? '$scheme$url' : url);
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              _showAppSnackBar('No se pudo abrir el enlace: $url', isError: true);
          }
      }
  
      return Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          if (links['facebook']?.isNotEmpty ?? false)
            ActionChip(
              avatar: const Icon(Icons.facebook),
              label: const Text('Facebook'),
              onPressed: () => launchLink(links['facebook']!, 'https://www.facebook.com/'),
            ),
          if (links['instagram']?.isNotEmpty ?? false)
            ActionChip(
              avatar: const Icon(Icons.camera_alt),
              label: const Text('Instagram'),
              onPressed: () => launchLink(links['instagram']!, 'https://www.instagram.com/'),
            ),
          if (links['tiktok']?.isNotEmpty ?? false)
            ActionChip(
              avatar: const Icon(Icons.music_note),
              label: const Text('TikTok'),
              onPressed: () => launchLink(links['tiktok']!, 'https://www.tiktok.com/@'),
            ),
          if (links['whatsapp']?.isNotEmpty ?? false)
            ActionChip(
              avatar: const Icon(Icons.message),
              label: const Text('WhatsApp'),
              onPressed: () => launchLink(links['whatsapp']!, 'https://wa.me/'),
            ),
          if (links['email']?.isNotEmpty ?? false)
            ActionChip(
              avatar: const Icon(Icons.email),
              label: const Text('Email'),
              onPressed: () => launchLink(links['email']!, 'mailto:'),
            ),
        ],
      );
    }
  }