import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rfcController = TextEditingController();
  final _birthDateController = TextEditingController();

  String? _gender;
  DateTime? _selectedBirthDate;
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _accountType;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _rfcController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.teal, Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: duration),
    );
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final snapshot = await _dbRef.child('users/${user.uid}').get();
    if (snapshot.exists && mounted) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _rfcController.text = data['rfc'] ?? '';
        _gender = data['gender'];
        _profileImageUrl = data['profileImageUrl'];
        _accountType = data['accountType'];

        if (data['birthDate'] != null && data['birthDate'].isNotEmpty) {
          try {
            _selectedBirthDate = DateTime.parse(data['birthDate']);
            _birthDateController.text = DateFormat('dd/MM/yyyy').format(_selectedBirthDate!);
          } catch (e) {
            _birthDateController.text = '';
            _selectedBirthDate = null;
          }
        } else {
          _birthDateController.text = '';
          _selectedBirthDate = null;
        }

        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> updates = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _gender,
        'rfc': _rfcController.text.trim(),
        'birthDate': _selectedBirthDate != null ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!) : null,
      };

      await _dbRef.child('users/${user.uid}').update(updates);

      if (mounted) {
        setState(() => _isEditing = false);
        _showSnackBar('Perfil actualizado con éxito.', color: AppColors.success);
      }
    } catch (e) {
      _showSnackBar('Error al guardar datos: $e', color: AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isGoogleUser =>
      _auth.currentUser?.providerData.any((info) => info.providerId == 'google.com') ?? false;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Material(
      type: MaterialType.transparency,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24, vertical: 32),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _profileImageUrl != null ? CachedNetworkImageProvider(_profileImageUrl!) : null,
                                child: _profileImageUrl == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                              ),
                            ),
                            if (_isGoogleUser)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Center(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Foto de perfil gestionada por Google', style: TextStyle(color: Colors.blue)),
                                    onPressed: () => _showSnackBar('Tu foto de perfil es gestionada por tu cuenta de Google.'),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_rounded), border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? 'Ingrese su nombre' : null,
                              readOnly: !_isEditing,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_rounded), border: OutlineInputBorder()),
                              keyboardType: TextInputType.phone,
                              readOnly: !_isEditing,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: const InputDecoration(labelText: 'Género', prefixIcon: Icon(Icons.transgender), border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'Hombre', child: Text('Hombre')),
                                DropdownMenuItem(value: 'Mujer', child: Text('Mujer')),
                                DropdownMenuItem(value: 'Prefiero no decirlo', child: Text('Prefiero no decirlo')),
                              ],
                              onChanged: _isEditing ? (newValue) => setState(() => _gender = newValue) : null,
                              validator: (value) => value == null && _isEditing ? 'Seleccione su género' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _birthDateController,
                              readOnly: true,
                              onTap: !_isEditing ? null : () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedBirthDate ?? DateTime(2000),
                                  firstDate: DateTime(1920),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedBirthDate = picked;
                                    _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
                                  });
                                }
                              },
                              decoration: const InputDecoration(labelText: 'Fecha de nacimiento', prefixIcon: Icon(Icons.calendar_today_outlined), border: OutlineInputBorder()),
                            ),
                            if (_accountType == 'Profesional' || _accountType == 'Admin') ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _rfcController,
                                decoration: const InputDecoration(labelText: 'RFC', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder()),
                                readOnly: !_isEditing,
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isEditing)
                                  Flexible(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.save_rounded),
                                      label: const Text('Guardar'),
                                      onPressed: _isLoading ? null : _saveProfileData,
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                                    ),
                                  ),
                                if (_isEditing) const SizedBox(width: 16),
                                Flexible(
                                  child: ElevatedButton.icon(
                                    icon: Icon(_isEditing ? Icons.cancel : Icons.edit_outlined),
                                    label: Text(_isEditing ? 'Cancelar' : 'Editar'),
                                    onPressed: () {
                                      setState(() => _isEditing = !_isEditing);
                                      if (!_isEditing) _loadUserData();
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: _isEditing ? Colors.red : Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}