// lib/screens/professional/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_quill/flutter_quill.dart'; // New import
import 'dart:convert'; // New import for jsonEncode/decode
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';


class ProfessionalProfilePage extends StatefulWidget {
  final String? professionalUid; // New: Optional UID to view another professional's profile
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

  bool _isLoading = true;
  bool _isEditing = false;

  String? _name;
  String? _email;
  String? _phone;
  String? _rfc;
  String? _birthDate;
  String? _profileImageUrl;
  List<String>? _specialties; // New
  String _verificationStatus = "no verificado"; // New
  bool _showPhoneToUsers = false; // New
  bool _showEmailToUsers = false; // New
  Map<String, String> _workingHours = {}; // New
  List<Map<String, dynamic>> _locations = []; // New: For multiple locations
  List<Map<String, dynamic>> _services = []; // New
  String? _professionalType; // New: 'particular' or 'publico'
  String? _institutionName; // New: Name of the public institution

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rfcController = TextEditingController();
  final _birthController = TextEditingController();
  late QuillController _biographyQuillController; // Changed to QuillController
  final _institutionNameController = TextEditingController(); // New

  static const List<String> _predefinedSpecialties = [
    'Psicología Clínica',
    'Psicoterapia',
    'Psiquiatría',
    'Terapia Familiar',
    'Neuropsicología',
    'Terapia Cognitivo-Conductual',
    'Terapia Gestalt',
    'Psicoanálisis',
    'Terapia de Pareja',
    'Terapia Infantil',
    'Adicciones',
    'Trastornos de Ansiedad',
    'Trastornos Depresivos',
    'Trastornos de la Alimentación',
    'Estrés Postraumático',
    'Desarrollo Personal',
    'Orientación Vocacional',
  ];

  // New: Currency options
  static const List<String> _currencies = ['MXN', 'USD', 'EUR', 'Otro'];


  @override
  void initState() {
    super.initState();
    _biographyQuillController = QuillController.basic(); // Initialize QuillController
    _loadProfile();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _rfcController.dispose();
    _birthController.dispose();
    _biographyQuillController.dispose(); // Dispose QuillController
    _institutionNameController.dispose(); // New
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final currentUserId = _auth.currentUser?.uid;
    final targetUid = widget.professionalUid ?? currentUserId; // Use passed UID or current user's UID

    if (targetUid == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Set _isEditing based on whether it's the current user's profile or not
    _isEditing = (widget.professionalUid == null || widget.professionalUid == currentUserId);

    try {
      final snapshot = await _db.child('users/$targetUid').get(); // Use targetUid
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _name = data['name'] ?? '';
          _email = data['email'] ?? '';
          _phone = data['phone'] ?? '';
          _rfc = data['rfc'] ?? '';
          _birthDate = data['birthDate'] ?? '';
          _profileImageUrl = data['profileImageUrl'];
          _specialties = (data['specialties'] as List?)?.map((e) => e.toString()).toList() ?? [];
          // _biography state variable removed, content directly loaded into QuillController
          _verificationStatus = data['verificationStatus'] ?? "no verificado";
          _showPhoneToUsers = data['showPhoneToUsers'] ?? false;
          _showEmailToUsers = data['showEmailToUsers'] ?? false;
          _workingHours = Map<String, String>.from(data['workingHours'] ?? {});
          _locations = (data['locations'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
          _services = (data['services'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
          _professionalType = data['professionalType'];
          _institutionName = data['institutionName'];


          _nameController.text = _name!;
          _phoneController.text = _phone!;
          _rfcController.text = _rfc!;
          _birthController.text = _birthDate!;
          _institutionNameController.text = _institutionName ?? '';
          // _specialtiesController is removed, so no update here
          // Initialize QuillController with loaded biography
          final biographyContent = data['biography'] as String?; // Get biography content from data
          if (biographyContent != null && biographyContent.isNotEmpty) {
            try {
              final doc = Document.fromJson(jsonDecode(biographyContent));
              _biographyQuillController.document = doc;
            } catch (e) {
              // Fallback to plain text if JSON parsing fails
              _biographyQuillController.document = Document()..insert(0, biographyContent);
            }
          } else {
            _biographyQuillController.document = Document();
          }
        });
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el perfil: ${e.toString()}'))
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      final ref = _storage.ref().child('profile_images/user_${uid}_profile.jpeg');
      
      TaskSnapshot uploadTask;
      if (kIsWeb) {
        uploadTask = await ref.putData(await picked.readAsBytes());
      } else {
        uploadTask = await ref.putFile(File(picked.path));
      }
      
      final url = await uploadTask.ref.getDownloadURL();

      await _db.child('users/$uid/profileImageUrl').set(url);
      setState(() {
        _profileImageUrl = url;
      });
    } catch (e) {
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir la imagen: ${e.toString()}'))
        );
      }
    } finally {
       if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProfileImage() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _profileImageUrl == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar imagen'),
        content: const Text('¿Seguro que quieres eliminar tu foto de perfil?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final ref = _storage.refFromURL(_profileImageUrl!);
      await ref.delete();
      await _db.child('users/$uid/profileImageUrl').remove();
      setState(() {
        _profileImageUrl = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la imagen: ${e.toString()}'))
        );
      }
    } finally {
       if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      await _db.child('users/$uid').update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'rfc': _rfcController.text.trim(),
        'birthDate': _birthController.text.trim(),
        'specialties': _specialties,
        'biography': jsonEncode(_biographyQuillController.document.toDelta().toJson()),
        'showPhoneToUsers': _showPhoneToUsers,
        'showEmailToUsers': _showEmailToUsers,
        'workingHours': _workingHours,
        'locations': _locations, // Save locations
        'services': _services,
        'professionalType': _professionalType, // Save professional type
        'institutionName': _professionalType == 'publico' ? _institutionNameController.text.trim() : null, // Save institution name
      });

      setState(() {
        _name = _nameController.text.trim();
        _phone = _phoneController.text.trim();
        _rfc = _rfcController.text.trim();
        _birthDate = _birthController.text.trim();
        _institutionName = _institutionNameController.text.trim();
        _isEditing = false;
      });
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito.'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el perfil: ${e.toString()}'))
        );
      }
    } finally {
       if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid; // Declare currentUserId here
    return Scaffold(
      appBar: AppBar(
        title: Text((widget.professionalUid != null && widget.professionalUid != currentUserId) // If viewing another professional's profile
            ? (_name ?? "Perfil Profesional") // Show their name as title
            : (_isEditing ? "Editar Perfil" : "Mi Perfil Profesional")), // Else, show user's own profile title
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          // Only show edit button if it's the current user's own profile and not in editing mode
          if (_isEditing && (widget.professionalUid == null || widget.professionalUid == currentUserId))
            IconButton(
              icon: const Icon(Icons.check), // Icon to save changes
              onPressed: _saveProfile,
              tooltip: 'Guardar Cambios',
            ),
          if (!_isEditing && (widget.professionalUid == null || widget.professionalUid == currentUserId))
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Editar Perfil',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildProfileHeader(),
        SizedBox(height: MediaQuery.of(context).size.height * 0.04),
        _isEditing ? _buildEditableForm() : _buildStaticInfoCard(),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildProfileHeader(),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.04),
        Expanded(
          flex: 3,
          child: _isEditing ? _buildEditableForm() : _buildStaticInfoCard(),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildProfileImage(),
        SizedBox(height: size.height * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _name ?? "Profesional",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ),
            if (_verificationStatus == 'verificado')
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.verified, color: Colors.blue, size: 24),
              ),
          ],
        ),
        SizedBox(height: size.height * 0.01),
        Text(
          _email ?? "",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: size.height * 0.02),
      ],
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector( // Wrap with GestureDetector
      onTap: _isEditing && _profileImageUrl != null ? () => _showImageOptions(context) : (_isEditing ? _pickProfileImage : null), // Only show options if image exists and in editing mode
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Hero(
            tag: 'profileImage', // Unique tag for Hero animation
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
              child: _profileImageUrl == null
                  ? Icon(Icons.person, size: 80, color: Theme.of(context).colorScheme.onPrimaryContainer)
                  : null,
            ),
          ),
          if (_isEditing) // Only show camera icon if in editing mode
            Positioned(
              bottom: 4,
              right: 4,
              child: Material(
                color: Theme.of(context).colorScheme.primary,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  onTap: _pickProfileImage, // This will still allow direct picking
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.camera_alt, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Ver imagen'),
                onTap: () {
                  Navigator.pop(bc); // Close bottom sheet
                  _viewProfileImage(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cambiar imagen'),
                onTap: () {
                  Navigator.pop(bc); // Close bottom sheet
                  _pickProfileImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Eliminar imagen', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(bc); // Close bottom sheet
                  _deleteProfileImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _viewProfileImage(BuildContext context) {
    if (_profileImageUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: Hero(
                tag: 'profileImage', // Unique tag for Hero animation
                child: Image.network(
                  _profileImageUrl!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaticInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _infoTile(Icons.badge_outlined, "RFC", _rfc),
            const Divider(),
            if (_showPhoneToUsers || _isEditing || widget.professionalUid != null) // Always show phone if viewing another professional's profile
              _infoTile(Icons.phone_outlined, "Teléfono", _phone),
            if (_showPhoneToUsers || _isEditing || widget.professionalUid != null)
              const Divider(),
            if (_showEmailToUsers || _isEditing || widget.professionalUid != null) // Always show email if viewing another professional's profile
              _infoTile(Icons.email_outlined, "Correo", _email), // Added email display
            if (_showEmailToUsers || _isEditing || widget.professionalUid != null)
              const Divider(),
            _infoTile(Icons.cake_outlined, "Fecha de nacimiento", _birthDate),
            const Divider(),
            _infoTile(Icons.psychology_outlined, "Especialidades", _specialties?.join(', ')),
            const Divider(),
            _infoTile(Icons.work_outline, "Tipo de Profesional", _professionalType),
            if (_professionalType == 'publico') ...[
              const Divider(),
              _infoTile(Icons.business, "Institución", _institutionName),
            ],
            const Divider(),
            // Display rich text biography
            if (!_biographyQuillController.document.isEmpty()) ...[
              const Divider(),
              _infoTile(Icons.description_outlined, "Biografía", null), // Title only, content below
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: QuillEditor.basic(
                  configurations: QuillEditorConfigurations(
                    controller: _biographyQuillController,
                    readOnly: true, // Read-only mode
                    sharedConfigurations: const QuillSharedConfigurations(
                      locale: Locale('es'),
                    ),
                  ),
                ),
              ),
            ],
            const Divider(),
            _buildLocationsDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_nameController, 'Nombre completo', Icons.person_outline),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            _buildTextField(_phoneController, 'Teléfono', Icons.phone_outlined, keyboardType: TextInputType.phone),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            _buildTextField(_rfcController, 'RFC', Icons.badge_outlined),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            _buildTextField(_birthController, 'Fecha de nacimiento (YYYY-MM-DD)', Icons.cake_outlined, keyboardType: TextInputType.datetime),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            _buildSpecialtiesInput(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            _buildSectionTitle(context, 'Tipo de Profesional'),
            _buildProfessionalTypeInput(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            _buildSectionTitle(context, 'Biografía'),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface.withAlpha(150),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  QuillToolbar.simple(
                    configurations: QuillSimpleToolbarConfigurations(
                      controller: _biographyQuillController,
                      sharedConfigurations: const QuillSharedConfigurations(
                        locale: Locale('es'),
                      ),
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.2,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QuillEditor.basic(
                      configurations: QuillEditorConfigurations(
                        controller: _biographyQuillController,
                        readOnly: false,
                        sharedConfigurations: const QuillSharedConfigurations(
                          locale: Locale('es'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            _buildSectionTitle(context, 'Consultorios'),
            _buildLocationsInput(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            _buildSectionTitle(context, 'Visibilidad de Contacto'),
            _buildSettingsCard([
              SwitchListTile(
                title: const Text('Mostrar teléfono a usuarios'),
                value: _showPhoneToUsers,
                onChanged: (value) => setState(() => _showPhoneToUsers = value),
                secondary: const Icon(Icons.phone_outlined),
              ),
              SwitchListTile(
                title: const Text('Mostrar correo a usuarios'),
                value: _showEmailToUsers,
                onChanged: (value) => setState(() => _showEmailToUsers = value),
                secondary: const Icon(Icons.email_outlined),
              ),
            ]),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            _buildSectionTitle(context, 'Horario de Trabajo General'),
            _buildSettingsCard([_buildWorkingHoursInput()]),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            _buildSectionTitle(context, 'Servicios y Precios'),
            _buildSettingsCard([_buildServicesInput()]),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
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
      maxLines: maxLines, // New
    );
  }

  Widget _buildSpecialtiesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Especialidades',
            prefixIcon: const Icon(Icons.psychology_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface.withAlpha(150),
          ),
          child: _specialties != null && _specialties!.isNotEmpty
              ? Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _specialties!
                      .map((specialty) => Chip(
                            label: Text(specialty),
                            onDeleted: _isEditing ? () => _removeSpecialty(specialty) : null,
                            deleteIcon: _isEditing ? const Icon(Icons.close) : null,
                          ))
                      .toList(),
                )
              : Text(_isEditing ? 'Selecciona una o más especialidades' : 'No disponible'),
        ),
        if (_isEditing)
          TextButton.icon(
            onPressed: () => _showSpecialtySelectionDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Añadir/Editar Especialidades'),
          ),
      ],
    );
  }

  void _removeSpecialty(String specialty) {
    setState(() {
      _specialties?.remove(specialty);
    });
  }

  Future<void> _showSpecialtySelectionDialog(BuildContext context) async {
    List<String> selected = List.from(_specialties ?? []); // Copy current selections

    await showDialog<void>(
      context: context,
      builder: (context) {
        final TextEditingController customSpecialtyController = TextEditingController();
        return AlertDialog(
          title: const Text('Seleccionar Especialidades'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateInDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _predefinedSpecialties.map((specialty) {
                        final isSelected = selected.contains(specialty);
                        return FilterChip(
                          label: Text(specialty),
                          selected: isSelected,
                          onSelected: (bool selectedValue) {
                            setStateInDialog(() {
                              if (selectedValue) {
                                selected.add(specialty);
                              } else {
                                selected.remove(specialty);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 30),
                    TextField(
                      controller: customSpecialtyController,
                      decoration: InputDecoration(
                        labelText: 'Añadir nueva especialidad',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: () {
                            final customSpecialty = customSpecialtyController.text.trim();
                            if (customSpecialty.isNotEmpty && !selected.contains(customSpecialty)) {
                              setStateInDialog(() {
                                selected.add(customSpecialty);
                                // _predefinedSpecialties.add(customSpecialty); // This is static, cannot add this way
                                customSpecialtyController.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _specialties = selected;
                });
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _infoTile(IconData icon, String title, String? value) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        (value?.isNotEmpty ?? false) ? value! : "No disponible",
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildWorkingHoursInput() {
    const List<String> daysOfWeek = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return Column(
      children: daysOfWeek.map((day) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(day, style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: _workingHours[day] ?? '',
                  decoration: const InputDecoration(
                    hintText: 'Ej: 9:00 - 17:00',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _workingHours[day] = value;
                    });
                  },
                  readOnly: !_isEditing, // Make read-only if not editing
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServicesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_services.isNotEmpty)
          ..._services.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> service = entry.value;
            return ListTile(
              title: Text(service['name'] ?? 'Servicio sin nombre'),
              subtitle: Text('${service['price'] ?? ''} ${service['currency'] ?? ''}'.trim()),
              trailing: _isEditing
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeService(index),
                    )
                  : null,
            );
          }).toList(),
        if (_isEditing)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add),
              label: const Text('Añadir Servicio'),
            ),
          ),
        if (!_isEditing && _services.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No hay servicios disponibles.'),
          ),
      ],
    );
  }

  void _addService() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController priceController = TextEditingController();
        String selectedCurrency = _currencies.first;
        return AlertDialog(
          title: const Text('Añadir Nuevo Servicio'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre del Servicio'),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Precio'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  DropdownButton<String>(
                    value: selectedCurrency,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCurrency = newValue!;
                      });
                    },
                    items: _currencies.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  setState(() {
                    _services.add({
                      'name': nameController.text.trim(),
                      'price': priceController.text.trim(),
                      'currency': selectedCurrency,
                    });
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, ingresa el nombre y el precio del servicio.')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _removeService(int index) {
    setState(() {
      _services.removeAt(index);
    });
  }

  Widget _buildProfessionalTypeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _professionalType,
          decoration: InputDecoration(
            labelText: 'Tipo de Profesional',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: ['particular', 'publico'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value == 'particular' ? 'Particular' : 'Público'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _professionalType = value;
            });
          },
        ),
        if (_professionalType == 'publico') ...[
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildTextField(_institutionNameController, 'Nombre de la Institución', Icons.business),
        ],
      ],
    );
  }

  Widget _buildLocationsInput() {
    return Column(
      children: [
        ..._locations.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> location = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(location['address'] ?? 'Dirección no especificada'),
              subtitle: Text(location['hours'] ?? 'Horario no especificado'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _locations.removeAt(index);
                  });
                },
              ),
              onTap: () => _addLocationDialog(locationToEdit: location, index: index),
            ),
          );
        }).toList(),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _addLocationDialog(),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Añadir Consultorio'),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationsDisplay() {
    if (_locations.isEmpty) {
      return _infoTile(Icons.location_on_outlined, "Ubicación", "No disponible");
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Consultorios", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ..._locations.map((location) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(location['address'] ?? 'Dirección no especificada', style: const TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Text(location['hours'] ?? 'Horario no especificado'),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  if (location['latitude'] != null && location['longitude'] != null)
                    SizedBox(
                      height: 150,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(location['latitude'], location['longitude']),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId(location['address']!),
                            position: LatLng(location['latitude'], location['longitude']),
                          ),
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _addLocationDialog({Map<String, dynamic>? locationToEdit, int? index}) async {
    final addressController = TextEditingController(text: locationToEdit?['address']);
    final hoursController = TextEditingController(text: locationToEdit?['hours']);
    LatLng? selectedPosition = locationToEdit != null
        ? LatLng(locationToEdit['latitude'], locationToEdit['longitude'])
        : null;
    GoogleMapController? mapController;

    // Request permission and get current location
    Future<void> _getCurrentLocation() async {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Los servicios de ubicación están deshabilitados.')));
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Los permisos de ubicación fueron denegados.')));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Los permisos de ubicación están permanentemente denegados, no podemos solicitar permisos.')));
        return;
      }

      try {
        final position = await Geolocator.getCurrentPosition();
        selectedPosition = LatLng(position.latitude, position.longitude);
        mapController?.animateCamera(CameraUpdate.newLatLng(selectedPosition!));
        final placemarks = await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          addressController.text = '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al obtener la ubicación: $e")));
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(locationToEdit == null ? 'Añadir Consultorio' : 'Editar Consultorio'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: selectedPosition ?? const LatLng(19.4326, -99.1332), // Mexico City
                          zoom: 14,
                        ),
                        onMapCreated: (controller) {
                          mapController = controller;
                        },
                        onTap: (position) {
                          setState(() {
                            selectedPosition = position;
                          });
                        },
                        markers: selectedPosition != null
                            ? {Marker(markerId: const MarkerId('selected'), position: selectedPosition!)}
                            : {},
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _getCurrentLocation();
                        setState(() {}); // Rebuild to show new location
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text("Usar mi ubicación actual"),
                    ),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      maxLines: 2,
                    ),
                    TextField(
                      controller: hoursController,
                      decoration: const InputDecoration(labelText: 'Horario de Atención'),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),            ElevatedButton(
              onPressed: () {
                if (addressController.text.isNotEmpty) {
                  final newLocation = {
                    'address': addressController.text.trim(),
                    'hours': hoursController.text.trim(),
                    'latitude': selectedPosition?.latitude,
                    'longitude': selectedPosition?.longitude,
                  };
                  setState(() {
                    if (index != null) {
                      _locations[index] = newLocation;
                    } else {
                      _locations.add(newLocation);
                    }
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, ingresa una dirección.')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}

