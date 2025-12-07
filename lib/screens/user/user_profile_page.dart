import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_colors.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String _name = '';
  String _phone = '';
  String _gender = ''; // New field
  String _preferredLanguage = ''; // New field
  String _timezone = ''; // New field
  String? _profileImageUrl; // To display existing photo
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();

  void _showSnackBar(String message, {Color color = Colors.teal}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Always call _loadUserData
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final snapshot = await _dbRef.child('users/${user.uid}').get();
    if (snapshot.exists && mounted) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _name = data['name'] ?? '';
        _phone = data['phone'] ?? '';
        _gender = data['gender'] ?? ''; // Load new field
        _preferredLanguage = data['preferredLanguage'] ?? ''; // Load new field
        _timezone = data['timezone'] ?? ''; // Load new field
        _profileImageUrl = data['profileImageUrl'];
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
      await _dbRef.child('users/${user.uid}').update({
        'name': _name,
        'phone': _phone,
        'gender': _gender, // Save new field
        'preferredLanguage': _preferredLanguage, // Save new field
        'timezone': _timezone, // Save new field
      });

      if (mounted) {
        setState(() => _isEditing = false);
        _showSnackBar('Perfil actualizado con éxito.', color: Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error al guardar datos: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Check if the current user is a Google user
  bool get _isGoogleUser =>
      _auth.currentUser?.providerData
          .any((info) => info.providerId == 'google.com') ??
      false;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Material(
      // Added Material widget
      type: MaterialType
          .transparency, // Use transparency to avoid visual changes
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 40 : 24, vertical: 32),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mi Perfil',
                              style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.055,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02),
                            // --- Profile Image Section (Display Only) ---
                            Center(
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _profileImageUrl != null
                                    ? CachedNetworkImageProvider(
                                        _profileImageUrl!)
                                    : null,
                                child: _profileImageUrl == null
                                    ? const Icon(Icons.person,
                                        size: 60, color: Colors.grey)
                                    : null,
                              ),
                            ),
                            if (_isGoogleUser)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Center(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text(
                                        'Foto de perfil gestionada por Google',
                                        style: TextStyle(color: Colors.blue)),
                                    onPressed: () {
                                      _showSnackBar(
                                          'Tu foto de perfil es gestionada por tu cuenta de Google.');
                                    },
                                  ),
                                ),
                              ),
                            // --- End Profile Image Section ---
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.03),
                            TextFormField(
                              initialValue: _name,
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: Icon(Icons.person_rounded),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) => _name = v,
                              validator: (v) =>
                                  v!.isEmpty ? 'Ingrese su nombre' : null,
                              readOnly: !_isEditing,
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02),
                            TextFormField(
                              initialValue: _phone,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                prefixIcon: Icon(Icons.phone_rounded),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              onChanged: (v) => _phone = v,
                              readOnly: !_isEditing,
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02),
                            // New Fields
                            TextFormField(
                              initialValue: _gender,
                              decoration: const InputDecoration(
                                labelText: 'Género',
                                prefixIcon: Icon(Icons.transgender),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) => _gender = v,
                              readOnly: !_isEditing,
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02),
                            TextFormField(
                              initialValue: _preferredLanguage,
                              decoration: const InputDecoration(
                                labelText: 'Idioma Preferido',
                                prefixIcon: Icon(Icons.language),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) => _preferredLanguage = v,
                              readOnly: !_isEditing,
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02),
                            TextFormField(
                              initialValue: _timezone,
                              decoration: const InputDecoration(
                                labelText: 'Zona Horaria',
                                prefixIcon: Icon(Icons.access_time),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) => _timezone = v,
                              readOnly: !_isEditing,
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.03),
                            // --- Action Buttons ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isEditing)
                                  Flexible(
                                    // Added Flexible
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.save_rounded),
                                      label: const Text('Guardar Cambios'),
                                      onPressed:
                                          _isLoading ? null : _saveProfileData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                      ),
                                    ),
                                  ),
                                if (_isEditing) const SizedBox(width: 16),
                                Flexible(
                                  // Added Flexible
                                  child: ElevatedButton.icon(
                                    icon: Icon(_isEditing
                                        ? Icons.cancel
                                        : Icons.edit_outlined),
                                    label: Text(
                                        _isEditing ? 'Cancelar' : 'Editar'),
                                    onPressed: () => setState(() {
                                      _isEditing = !_isEditing;
                                      if (!_isEditing) {
                                        // If canceling edit, reload original profile
                                        _loadUserData();
                                      }
                                    }),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isEditing
                                          ? Colors.red
                                          : Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                    ),
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